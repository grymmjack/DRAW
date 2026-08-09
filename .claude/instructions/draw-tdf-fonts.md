# TheDraw (.TDF) font support

Deep-dive for `GUI/TDF-FONT.BI/BM` (parser + rasteriser) and
`GUI/TDF-BROWSER.BI/BM` (picker). Read this before touching either.

## The one idea that explains the design

**A TDF glyph is a grid of CP437 character cells, not a bitmap.** A single "A"
might be 12x6 cells; DRAW rasterises those through QB64-PE's built-in 8x16 VGA
font (`_FONT 16` + `_CONTROLCHR OFF`, the same primitive `GUI/TEXT-LAYER.BM`
already uses for built-in fonts) into a 96x96 image.

Everything else follows from that:

- TDF needed **no new pixel machinery**. `TDF_render_glyph` returns one glyph as
  an image, exactly like `CBF_render_glyph`, and the existing
  `TEXT_LAYER_draw_bitmap_char` blit consumes it unchanged.
- Colour faces carry a VGA attribute byte per cell, which is precisely what
  `isColorBitmapFont` already means in DRAW — the blit's
  `isColorBitmap% AND NOT TEXT_LAYER_FORCE_TINT%` branch passes source colours
  through. Block and outline faces are single-colour and take the tint path.
- Glyphs are **large**. 55x41 cells = 440x656 px for one character. Do not
  assume a glyph fits anywhere.

## Binary format

```
0x13 "TheDraw FONTS file" 0x1A          bundle header
  per font, repeated until a 0x00 byte:
    FF00AA55        u32 LE font indicator
    u8 nameLen + name[12] + 4 magic bytes
    u8  type        0=outline 1=block 2=color
    u8  spacing     the font's own inter-glyph gap
    u16 blockSize
    u16 lookup[94]  offsets for '!'..'~'; 0xFFFF = undefined
    glyphBlock[blockSize]
```

Record start + 25 = lookup table; + 213 = glyph block
(`TDF_LOOKUP_OFFSET` / `TDF_BLOCK_OFFSET`).

Each glyph in the block: `u8 width, u8 height`, then a byte stream terminated by
`0x00`. Control bytes: `13` newline, `'&'` end marker (no cell),
`0xFF` hard blank (a cell with no ink), `' '` skip (a cell with no ink).

- **Colour faces**: every *non-control* byte is followed by an attribute byte —
  `fg = attr AND 15`, `bg = (attr \ 16) AND 7`. `'&'` is still a control byte,
  so a colour face can never contain a literal `&`.
- **Outline faces**: bytes `'A'..'Q'` are placeholders into `TDF_OUTLINE_CHAR`
  (19 styles x 17 slots, index `byte - 65`). `'@'` fill marker and `'O'` hole
  are cells with no ink. `'R'` has no slot and renders blank.

## Gotchas specific to this module

1. **The declared width/height bytes lie.** The corpus contains values up to
   244x223 cells — 1952x3568 px for one character. `TDF_decode_glyph%` ignores
   them and measures the real extent by walking the byte stream; the true
   maximum across the shipped corpus is 55x41. `TDF_MAX_CELLS_W/H` clamp.
   `DEV/tdf-repack.py` does the same measurement and stores the honest value in
   the `.TDX` index.

2. **Face names are not unique** — 4419 collisions across the wild corpus, and
   even after content-deduplication a bundle still holds several *genuinely
   different* faces under one name (three distinct `BigOutline` faces ship in
   `OUTLINE.TDF`). Identity is therefore the pseudo-path
   `TDF://<BUNDLE>/<face name>#<ordinal>` (`FONT_LIST_tdf_path$`) — the trailing
   ordinal is load-bearing, not decoration: without it a saved document resolves
   to whichever same-named face happens to come first. `FONT_LIST_find_by_name%`
   is not safe for TDF.

   `TDF_FACE().dupIndex` / `.dupTotal` carry that ordinal, assigned in two linear
   passes at registration (the repacker sorts each bundle by name, so duplicates
   are adjacent — counting matches per face would be O(n²) over 3560 faces).
   `TDF_face_display$` appends ` #n` in the picker so a human can tell them
   apart; parse the ordinal back off with `_INSTRREV` on `#`, since a face name
   may itself contain one.

3. **Faces are registered on demand.** 3757 faces against `FONT_LIST_MAX` of
   512 — they cannot all live in the font list, which is the whole reason the
   browser exists. `FONT_LIST_add_tdf_font%` adds one face and dedupes by
   pseudo-path.

4. **Index stability is load-bearing.** `.draw` stores a text layer's font as a
   raw `fontIdx` INTEGER, so registration order matters. Used faces are recorded
   in `DRAW_TDF_FONTS.txt` and re-registered by `FONT_LIST_load_tdf_used`
   **before `FONT_LIST_sort`** — keep that ordering or saved documents will
   resolve to the wrong font.

5. **Cache granularity is the glyph *block*, not the glyph.** `blockSize` is a
   u16 so a whole face is at most 64 KB; once resident, decoding is pure memory
   work. `TDF_CACHE_GW` additionally memoises per-glyph widths, because
   `TEXT_LAYER_measure_char%` asks for widths every frame and measuring means a
   full decode.

6. **Never read a FUNCTION's own name inside its body** — in QB64 that is a
   recursive CALL, not a variable read, and it SIGSEGVs or fails to compile.
   This bit `TDF_glyph_advance%` and `TDF_face_height%` during development; both
   now compute into a local and assign once at the end.

7. **Scaling happens after rasterisation.** `TDF_downscale&` box-filters the
   finished glyph. Shrinking the *cell grid* instead would discard the CP437
   shade blocks (0xB0-0xB2) that encode a colour face's gradients — the whole
   point of the antialiased downscale is to average those dither cells back into
   real intermediate colours. Colour is averaged **weighted by alpha** and alpha
   averaged separately, so the transparent surround does not fringe glyph edges.
   `TDF_glyph_advance%` / `TDF_face_height%` / `TDF_glyph_width%` all apply the
   same `TDF_scaled%` ratio, or layout desynchronises from the pixels.

8. **`TDF_init` runs at include time** (called from the `.BI`), so it must not
   touch `THEME.*` or the filesystem — see gotcha 11 in CLAUDE.md. Bundle
   scanning is deferred to `TDF_ensure_scanned`, which is lazy and idempotent.

## Assets

`DEV/tdf-repack.py <corpus-dir> -o ASSETS/FONTS/THEDRAW` deduplicates a raw
corpus by face content and writes `{OUTLINE,BLOCK,COLOR}.TDF` plus `.TDX`
indices. Face records are copied **verbatim** — the tool never re-encodes a
glyph, so output cannot drift from the source. Pass `--manifest` for a
`faces.csv` listing every kept face and the file it came from.

The `.TDX` sidecar is DRAW-specific: 8-byte magic `DRAWTDX1`, `u32 faceCount`,
then fixed 32-byte records matching the `TDX_REC` TYPE in `GUI/TDF-FONT.BI`.
**If you change that TYPE, change `TDX_REC` in the Python tool to match** — it
is read straight off disk with `GET`, so a field-width mismatch silently yields
garbage rather than an error.

## Verifying changes

`DEV/EXPERIMENTS/TDF-TEST.BAS` is a standalone harness (it includes only
`GUI/TDF-FONT.BI/BM`, plus its own `SAFE_FREEIMAGE` stub). Build it **into the
repo root** — QB64 chdir's to the executable's directory at startup, so a binary
built elsewhere will not find `./ASSETS/FONTS/THEDRAW/`:

```bash
cd ~/git/DRAW
qb64pe -w -x -o TDF-TEST.run DEV/EXPERIMENTS/TDF-TEST.BAS && ./TDF-TEST.run
```

It counts faces, renders samples of each type and each scale to `/tmp`, sweeps
every face for decode failures, and prints `GRIDDUMP` cell grids for a
deterministic set of (face, char) pairs.

Those dumps are the real regression test: they were diffed against Mike
Krueger's `retrofont` crate (the reference implementation kaleidotron uses) over
60 glyphs spanning all three face types, with **0 mismatches**. When changing
the decoder, re-run that diff. Note the harness pads rows to the glyph's full
width while retrofont's rows are ragged — strip trailing `....` from both sides
before comparing, and remember that one sampled character is a comma and another
a colon, so do not use those as field separators in the comparison script.
