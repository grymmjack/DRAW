# Palette color cycling (DeluxePaint / GrafX2 style)

Plan + decisions: `PLANS/_/COLOR-CYCLING-PLAN.md`. User docs: manual ch. 3 *Color Cycling*,
ch. 10 *Color Cycling Formats*. Examples: `SAMPLES/COLOR CYCLING/`.

## Model — read this first

- Layers stay **RGBA**. There is no indexed pixel storage. A pixel *belongs* to the **first**
  palette index with exactly its RGB (the Color Ops rule "a chip IS its pixels"). Cycling is a
  **display-time remap of the finished composite**; layer pixels are never written.
- A **range** = palette indices `lo..hi` (≥ 2 colors), `rate` in **ILBM CRNG units**
  (16384 = 60 steps/s, linear; stored verbatim so LBM/GIF round-trips are lossless), `cmode`
  FWD/REV/PING, `active` (FALSE = paused, holds `heldStep`). Max 16, sorted by `lo`,
  **never overlapping** (`PCYC_add_range%` drops ranges it overlaps).
- `PCYC.ENABLED` is **view state** (Shift+Tab), not saved. Ranges are document state.

## Shift math (identical in editor, .bas, animated GIF)

`n = hi-lo+1`, step `k = INT((now-origin)*sps)` from absolute time (`PCYC_now#`, midnight-safe).

| mode | shift | period (steps) |
|------|-------|----------------|
| FWD  | `k MOD n` | n |
| REV  | `(n - k MOD n) MOD n` | n |
| PING | `m = k MOD 2(n-1)`; `m > n-1 → 2(n-1)-m` | 2(n-1) |

Chip / pixel of index `lo+j` shows `PAL(lo + ((j - shift) MOD n + n) MOD n)`
(`PCYC_display_index%`). FWD moves colors toward higher indices.
Speed changes and unpausing **rebase** the origin so the current step is kept (`PCYC_rebase`).

## Files

| File | Role |
|------|------|
| `GUI/PALETTE-CYCLE.BI/BM` | `PCYC_` module: ranges, timing, shift math, LUT + pixel map, `PCYC_present&`, serialize, bookkeeping, actions 2060-2069, strip bands, Ctrl gestures, wheel-burst undo |
| `OUTPUT/PAL-INDEX.BI/BM` | `IDX_index_image$`: image → palette indices (exact first-index, cached nearest that **skips cycle-range indices**, alpha<128 → transparent slot = `PAL_COLOR_COUNT`) |
| `OUTPUT/FILE-CYCLE-BAS.BI/BM` | `CYCX_` hub: File > Color Cycling actions 2330-2335, shared save dialog, open dialog, single-file `.bas` generator |
| `OUTPUT/FILE-GIF.BI/BM` | GIF89a LZW writer, CRNG + `DRAWCYCL1.0` extensions, animated GIF, GIF reader (`GIF_load_cycling%`), shared `CYCX_adopt_begin/finish`, CRNG/DRAWCYCL parsers, duplicate-color nudge |
| `INPUT/FILE-LBM.BI/BM` | ILBM/PBM reader (`LBM_load%`) |
| `OUTPUT/FILE-LBM.BM` | ILBM/PBM writer (`LBM_export%`) |
| `OUTPUT/BATCH.BI/BM` | CLI `--cycle` / `--export` / `--export-anim` (exit 0/1) |

## Render hook (OUTPUT/SCREEN.BM `RENDER_layers`)

- `useComposite% = ... OR PCYC_running%`, and the trivial single-layer path is skipped while
  running (it would bypass the composite).
- After compositing: `shownImg& = PCYC_present&(compositeImg&)`; blit `shownImg&` and set
  `CANVAS_CONTENT_SRC& = shownImg&` (Preview cycles too). `COMPOSITE_BUFFER&` and the
  `COMPOSITE_*_CACHE&` stay **uncycled** — never write cycled pixels into them.
- `PCYC_present&` keeps a persistent `PCYC.BUF`. It `_MEMGET`s the composite into a string and
  compares with the last base; only when the composite **or** the palette/range signature
  changed does it copy + rebuild the pixel map (64K low-16-bit-RGB hash, first index wins).
  Each step rewrites only the recorded cycling pixels whose display color changed (alpha kept).
- Pattern tile mode calls `RENDER_layers` 9×; `PCYC.BUILT_SEQ = SCREEN_RENDER_SEQ&` makes the
  later calls reuse the buffer.

## Idle loop (DRAW.BAS)

`IF PCYC_tick% THEN FRAME_IDLE=FALSE: SCENE_CHANGED=TRUE: GUI_NEEDS_REDRAW=TRUE` and
`IF PCYC_running% THEN FRAME_IDLE=FALSE`. `PCYC_tick%` returns TRUE only when a shift (or the
palette/range signature) changed — same discipline as the text cursor blink. The strip chips
cycle too (`PALETTE_STRIP_render` draws `PAL(PCYC_display_index%(i))`).

## Undo + Color Ops bookkeeping

- `PALETTE_snapshot$` appends `"CYC1" + PCYC_serialize$`; `PALETTE_restore` parses it **only
  if present** (old history records leave ranges alone). So every palette undo record carries
  the ranges; range edits record `HISTORY_record_palette` via `PCYC_commit`.
- Ctrl+Wheel speed bursts: snapshot at the first notch, `PCYC_wheel_flush` records one step
  after 0.7 s quiet (from `PCYC_tick%`) or before any other range edit / Color Ops exit.
- Color Ops edits call `PCYC_on_delete` (shift/shrink, drop < 2), `PCYC_on_insert` (shift /
  grow when strictly inside), `PCYC_on_reorder` (follow if still contiguous, else keep span)
  **before** the after-snapshot is taken.
- `PALETTE_OPS_reset` → `PCYC_reset` (all document-creation paths + `DRW_load_from_png` plain
  PNG path). `PCYC_validate` clips ranges when the palette shrinks.

## .draw v30

After the v29 AI block, before history: `LONG blobLen` + `PCYC_serialize$` (count INT, per
range lo, hi INT, rate LONG, cmode, active INT, heldStep LONG = 16 bytes). `DRW_load_binary`
reads it into a **local** and adopts it **after** `PALETTE_OPS_reset` (which clears ranges).

## File formats

- **ILBM CRNG chunk** (8 B BE): `pad(2) rate(2) flags(2) lo hi`; flags bit0 active, bit1
  reverse. Writer emits max(4, n) chunks (DeluxePaint style) + private `DRCY` chunk.
- **GrafX2 GIF**: app extension `21 FF 0B "CRNG\0\0\0\0" "1.0"` right after the global color
  table, sub-block of 6-byte records `rate(BE16) flags(BE16) lo hi`. Writer adds
  `21 FF 0B "DRAWCYCL1.0"` (version 1, count, per range lo hi rate(BE16) cmode active
  heldStep(BE16)). The same payload is the LBM `DRCY` chunk. Readers prefer DRAWCYCL/DRCY.
- PING → written as FWD in CRNG; paused → inactive.
- `_LOADIMAGE(gif, 256)` remaps to QB64's VGA palette ([Linux] verified 2026-10-06), hence the
  native GIF decoder. `DRW_load` sniffs `GIF8` (only GIFs containing CRNG/DRAWCYCL take the
  native path) and `FORM ILBM|PBM `.
- Imports nudge duplicate colors that **matter** (used by pixels or in a range) to the nearest
  free RGB (L1 ≤ ±3) — unused *earlier* duplicates first, so visible pixels rarely change.
  Inactive / rate-0 CRNG ranges import paused at the default speed.
- Animated GIF: 2-cs ticks, loop = LCM over ranges of `P*5000/gcd(P*5000, sps*100)` ticks
  (speed snapped to 0.01/s), cap 3000 ticks / 1000 frames; frame 1 full, later frames =
  bbox of cycling pixels, one LZW stream reused, per-step local color table, disposal 1.

## Gotchas hit while building it

- Reserved words: `out`, `base` (and `pos`, `off`...) fail as identifiers — `ixOut$`, `artBytes$`.
- QA in **zsh**: `$args` does not word-split — use `${=args}` or arrays, or DRAW gets one
  giant argument and starts as a normal GUI session (looks like a hang).
- `DRAW_EXTRA_ARGS` in the QA harness is word-split: no spaces in the path.
- Open dialog used to make **any** opened file the Ctrl+S target (`CURRENT_DRW_FILENAME$`),
  so saving after opening a GIF/LBM/BMP overwrote it with project data. Now only
  `.draw`/`.png`; others set `CURRENT_FILENAME$` → companion `.draw`.

## Tests

- `QA/unit/pcyc-unit.bas` — headless unit test (shift math, bookkeeping, serialize, present,
  indexer). `qb64pe -w -x -o pcyc-unit.run pcyc-unit.bas && ./pcyc-unit.run` (exit 0).
- `DEV/tools/test-cycle-exports.sh` — batch round trips for every format (compiles + runs the
  `.bas`, ImageMagick/ffmpeg/netpbm decode checks, GrafX2 fixture `QA/fixtures/grafx2-crng.gif`).
- `QA/tests/palette-cycle-basic.sh`, `palette-cycle-gestures.sh` — GUI (Shift+Tab, undo, Ctrl
  gestures).
