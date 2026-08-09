---
name: create-color-bitmap-font-from-image
description: "Create a DRAW Color Bitmap Font (CBF) .bmp from a source image of a character set — a retro screenshot, a spritesheet, a chargen test screen. Locates the character grid at sub-pixel accuracy, lifts each glyph, writes the marker-row spritesheet DRAW expects, and verifies it loads. Use when the user wants a new colour font in ASSETS/FONTS/COLOR_BITMAP/."
---

# Create a Color Bitmap Font from an Image

DRAW's **CBF** fonts keep their original pixel colours instead of being tinted to
the foreground colour. They live in `ASSETS/FONTS/COLOR_BITMAP/` and are picked
up automatically at startup by `FONT_LIST_scan_bitmap_dir`.

This skill turns a picture of a character set into one.

**Scripts live in `scripts/`. They need `Pillow` and `numpy`.** If the system
Python is externally managed (PEP 668, typical on Debian/Ubuntu), make a venv in
the session scratchpad rather than fighting it:

```bash
python3 -m venv "$SCRATCH/venv" && "$SCRATCH/venv/bin/pip" install -q pillow numpy
```

---

## The format (read this before anything else)

Mirrored in `scripts/cbf.py`; the authority is `CBF_detect%` / `CBF_load_cache` /
`CBF_render_glyph` in `GUI/FONT-LIST.BM`.

A CBF font is **one .bmp strip**:

```
height = glyphHeight + 1        row 0 is a MARKER row, not pixels
row 0  = background everywhere, except ONE pixel of another colour
         at the starting x of each glyph
rows 1+= the glyphs, left to right, in their real colours
```

Four rules decide whether a sheet works:

1. **Background is elected, not declared.** The loader takes the *most frequent
   colour in row 0*. Whatever wins becomes transparent everywhere in the glyphs.
2. **Glyph starts are marker pixels; widths are implied.** `width[i] =
   markerX[i+1] - markerX[i]`, and the last glyph runs to the right edge. So
   glyphs can be proportional for free — just space the markers unevenly.
3. **Characters map positionally.** Glyph 0 is ASCII 33 `!`, glyph 1 is 34 `"`,
   … up to 126 `~`. A full printable set is **94 glyphs in strict ASCII order**.
   There is no encoding table — a missing glyph shifts every later character.
   Glyphs past 94 continue onto codes **127+** (up to `CBF_GLYPH_MAX` = 128
   glyphs total), which is how a font carries an extra block such as Apple II
   MouseText. `CHARMAP` walks 0..255 calling `CBF_render_glyph`, so those show
   up in the character grid with no further work. Insert a blank spacer glyph
   if you want the extra block to start on a round code.
4. **Space is never a glyph.** DRAW advances by the average glyph width.

Gotchas that will bite:

- Stop short of 94 glyphs and the tail is simply unmapped. Stop between 33 and
  64 and you have no letters at all. Cover 33–90 but not 97+ and DRAW aliases
  lowercase onto the uppercase glyphs.
- `CBF_GLYPH_MAX` is 128; extra glyphs are ignored.
- `CBF_detect%` rejects anything under 10px wide, under 3px tall, with fewer
  than 2 row-0 colours, or with fewer than 2 glyphs.
- If glyphs average under ~3px wide, the 1px markers can outnumber the
  background in row 0 and the loader elects the *marker* colour as background.
  `cbf.write` refuses to write that.

**Display name** comes from `FONT_LIST_extract_name$`: filename, minus
extension, with `-` and `_` turned into spaces. So `APPLE-][-40-COLOR.bmp` shows
up as `APPLE ][ 40 COLOR`. Prefer hyphens over literal spaces — the name comes
out identical and the filename stays shell-safe.

**Keep names short, and put the distinguishing token early.** The font dropdown
cuts long names with a `~`, so a family whose members differ only in a trailing
suffix collapses into rows that all look the same. `APPLE ][ 40 COLUMNS AMBER`,
`... AMBER CRT` and `... AMBER SCAN` all rendered as `APPLE ][ 40 COLUMNS AMB~`
— three entries indistinguishable from each other. Renaming is not free either:
`.draw` files store the font by display name and resolve by exact match
(`DRW.BM`), so a rename silently drops the font on already-saved art. Budget the
name before you ship the first font in a family.

---

## Step 1 — Get the source image on disk

An image pasted into the conversation is **not a file**. Pillow cannot open it.
Ask the user to save it and give you the path. Do not try to reconstruct it.

## Step 2 — Read the image and write down the character inventory

Look at the image and record, per line of text, **exactly** what it says. You
need this: the grid fit is driven by character counts, and the glyph order is
driven by which character is which.

Then check coverage against the 94 printable ASCII. A chargen test screen
usually has all of them across its rows; a game's font sheet often has only
uppercase and digits — say so up front, because the resulting font will alias
lowercase to uppercase.

## Step 3 — Determine the cell size

The glyph cell in **source dots**, not screen pixels. Apple II 40-column text is
`7x8`; CGA/VGA text is `8x8`; EGA/VGA 80x25 is `8x16`; C64 is `8x8`. Getting
this wrong makes everything downstream wrong, so confirm it against the machine,
not by eyeballing the image.

## Step 4 — Fit the grid

```bash
python3 scripts/fit_grid.py SHOT.png --cell 7x8 \
    --row - \
    --row "abcdefghijklmnopqrstuvwxyz" \
    --row "ABCDEFGHIJKLMNOPQRSTUVWXYZ" \
    --out spec.json
```

`--row` is matched to each detected text band in order; `-` skips one.

Retro screenshots are scaled by non-integer factors with blur, so you cannot
crop on integer boundaries — you have to find where each **dot centre** landed.
The fitter measures one shared scale for the whole image (autocorrelating the
character pitch, floored by ink-span / character-count) and then searches only
the per-row offsets.

**It gets close, not exact.** Expect to nudge x/y by a pixel or two in step 6.

## Step 5 — Build the sheet

```bash
python3 scripts/build_cbf.py spec.json --out "MY-FONT.bmp" --preview p.png
```

Two spec fields decide whether this succeeds:

- **`threshold`** — dots dimmer than this snap to the background. This is the
  one that matters. DRAW makes only the *exact* background colour transparent,
  and blur means almost no dot lands on it exactly, so an unthresholded crop of
  a scaled screenshot comes out as **solid blocks with nothing transparent**.
  The script prints the lit-dot percentage and warns at both extremes.
- **`trim`** — `false` keeps a fixed cell (monospace); `true` crops each glyph
  to its ink plus `gap` columns, giving a proportional font.

## Step 6 — Verify, and iterate on the glyphs

```bash
python3 scripts/inspect_cbf.py MY-FONT.bmp --art A I H g 0
python3 scripts/inspect_cbf.py MY-FONT.bmp --render "Sphinx of black quartz" -o p.png --scale 8
```

`inspect_cbf.py` re-implements DRAW's loader, so if it is happy DRAW will be.
Read the ASCII art against what the glyphs should look like:

| Symptom | Cause |
|---|---|
| Every dot lit, solid blocks | `threshold` too low (or 0 on a blurred source) |
| Glyphs sheared / drifting along the row | `sx` slightly wrong — error accumulates left to right |
| Glyphs consistently clipped on one side | that row's `x` off by a dot |
| Rows of the glyph missing top or bottom | that row's `y` off, or `cell` height wrong |
| Wrong letters entirely | a `--row` text is mistyped, or a character is missing and everything after it shifted |
| "fully-background glyph renders as nothing" | thin glyphs (`-` `:` `` ` ``) lost to `threshold` |

Loop back to step 4/5 until the art is clean. **Do not ship a font you have not
looked at glyph-by-glyph** — a shifted character map is silent and ruins every
later glyph.

## Step 7 — Install and record

Write to `ASSETS/FONTS/COLOR_BITMAP/<NAME>.bmp` and bump the bundled-font count
in `CHEATSHEET.md` (search for "bundled CBF fonts"). No code change is needed —
the directory scan finds it.

---

## When a direct crop is not good enough

If the source is a heavily scaled, blurred, or composite-filtered capture, step
5 will produce recognisable-but-wrong glyphs: serifs lost, thin punctuation
vanished, diagonals broken. At that point stop trying to tune `threshold` and
switch strategy:

**Take the shapes from a font that already has them, and take only the colour
from the image.** A pixel-exact TTF of the same character generator usually
exists (`ASSETS/FONTS/COMPUTERS/` has Apple II, Atari, BBC, C64, PET). Verify it
really is the same ROM by rendering it at its native pixel size and checking the
glyph box, then reproduce the colour effect analytically.

`scripts/build_apple2_color.py` is the worked example of exactly this, and
`scripts/ntsc.py` is the reusable colour half.

---

## Worked example — APPLE ][ 40 COLUMNS COLOR

Built from an Apple II character-generator test screen (761x582, a ~2.92x
non-integer upscale with NTSC composite blur).

**Why the shapes did not come from the screenshot.** At that scale a lit dot
bleeds about one dot to its right, so thresholding back to a 7x8 mask corrupted
91 of 94 glyphs — worst on diagonals (`Q` `M` `W` `V` `X` `N`).

**Pick the ROM font that actually has the right cell.** The first attempt used
`Apple2.ttf`, which looks like the same character generator but is an 8x8-em
font: `p` and `q` need *nine* rows there, so both descenders were silently
clipped. `PrintChar21.ttf` is a true 7x8 cell — no glyph overflows it, and it
carries MouseText too. The two disagree on exactly six glyphs (`%` `(` `,` `p`
`q` `t`); rendering each through the fitted NTSC model and comparing against the
screenshot picked PrintChar21 **6/6**. Always check whether *any* glyph's ink
falls outside the cell before trusting a font as your shape source.

**Where the colour came from.** Apple II text is 1-bit; the colour is an NTSC
artifact. Dots clock out at 7.16 MHz against a 3.58 MHz subcarrier — exactly one
colour cycle per **2 dots** — so a dot's *column parity is its phase*:

| dot context | even column | odd column |
|---|---|---|
| isolated | violet **(197, 68, 252)** | green **(58, 187, 3)** |
| inside a run | white | white |
| at the end of a run | violet fringe | green fringe |

Measured off the screenshot (1068 dots, 37 context classes), then used to fit a
4-tap quadrature decoder — phase 0.576 rad, chroma 0.48 — to RMS 22.7/255. The
re-render agrees with the screenshot on **26/26** letter hues.

This is also why the cell being **7 dots — an odd number** — makes consecutive
characters alternate green/violet in the original: each cell start flips parity.

**The one judgement call.** A font sheet stores one rendering per glyph, but the
real machine colours a glyph by where it sits. Fixing every glyph at phase 0
(as if at column 0) is the font-like choice — `H` is the same colour wherever
you type it — and puts most stems on odd dots, so the font reads green with
violet and white fringes. `--phase 1` gives the violet-dominant twin; shipping
both as a colour pair is reasonable (`lemblue`/`lemgreen`/… already do this).

**MouseText.** The sheet also carries the 32 MouseText glyphs at codes 128–159
(a blank spacer occupies 127 so the block starts round). `Apple2.ttf` has no
MouseText at all, and recovering it from the screenshot was not good enough —
a deblur classifier trained on the four text rows, where `Apple2.ttf` supplies
ground truth, cross-validated at only 98.8% per dot, and did worse still on
MouseText's dense block graphics. So the glyphs come from **`PrintChar21.ttf`**,
Kreative Korp's Apple II font, which carries them at **U+0080–U+009F**.

That mapping was not assumed — it was *identified*: matching the noisy
extraction against all 3211 candidate codepoints put 23 of 32 glyphs exactly on
`U+0080 + index`, with the rest landing on near neighbours. The general trick is
worth remembering: **a noisy extraction is good enough to locate the right
glyphs in a clean font, even when it is not good enough to be the font.**

MouseText `$46`/`$47` differ between ROM revisions — the //e Enhanced has the
running-man pair, the IIGS has menu icons. Those were the two worst matches
against the screenshot until the reactivemicro wiki explained why; PrintChar21
keeps the //e glyphs at `U+E011`/`U+E012`, where `$47` matches the screenshot
*exactly* (0 differing dots, against 24 for `U+0087`). `--iigs` selects the other
set.

**CRT variants, and why there are three size tiers.** A real scanline *gap* needs
an output row of its own, so a true-scanline sheet is necessarily twice as tall
as the native cell. That is a big deal in practice: dropped next to the 7x8
original, a 14x16 font is 4x the area and the size jump is jarring enough that
it reads as a different font rather than a variant.

So the family ships three tiers: native 7x8, a `SCAN` tier that dims **alternate
glyph rows** at 7x8 (not physically a scanline, but it reads as one and costs
nothing in size), and the true-scanline `CRT` tier at 14x16 / 7x16. Offer the
cheap tier — people reach for a font that matches the size of their other art far
more often than for the accurate one.

Keep the names short. DRAW truncates font names in the dropdown, so a family
whose members differ only in a trailing suffix collapses into rows that all read
the same — `APPLE ][ 40 COLUMNS AMBER`, `... AMBER CRT` and `... AMBER SCAN` all
rendered as `APPLE ][ 40 COLUMNS AMB~`, which looks like duplicate entries.
Budget the distinguishing token to fit inside the cut.

The two column modes share identical 7x8 bitmaps; what differs is the dot clock,
so a 40-column dot is about square (14x16 once rows are doubled) and an
80-column dot is half as wide (7x16). Dimming applies **only to lit pixels** — an
opaque CRT ground would make every glyph carry a black box and stop it
compositing.

One implementation trap: express the dimming rule against the **output** row, as
`(r * vscale + sy) % 2 == 1`. Writing it against the sub-row (`sy >= vscale/2`)
looks equivalent and works at vscale=2, but silently becomes a no-op at
vscale=1 — the 1x variant then builds fine and looks identical to the plain one.

Monochrome variants deliberately carry no artifact colour: that is what a mono
monitor showed, and it is exactly why 80-column text was unreadable on a colour
set.

```bash
python3 scripts/build_apple2_color.py                     # the 40-col colour font
python3 scripts/build_apple2_color.py --all               # the whole nine-font family
python3 scripts/build_apple2_color.py --columns 80 --phosphor amber --scanlines --out X.bmp
python3 scripts/build_apple2_color.py --phase 1 --out V.bmp   # violet-dominant twin
python3 scripts/build_apple2_color.py --verify /tmp/v     # re-render the reference rows
```

**Line spacing.** A CBF font's leading *is* its glyph height — there is no
separate setting — so spacing can only be changed by baking blank rows into the
sheet. Before doing that, check what the hardware actually did: the Apple II text
screen is 192 scanlines over 24 rows, capitals occupy 7 of the 8 cell rows, and
the reference screenshot's own row pitch measures 16 scanlines for two rows. 8px
was already correct; the airier look people remember is the CRT's scanline
structure, not extra leading.

`--verify` re-renders the screenshot's own text at the *original* per-character
phases and at the fitted capture brightness, so it can be compared against the
source directly. That is the check that caught the model being right.
