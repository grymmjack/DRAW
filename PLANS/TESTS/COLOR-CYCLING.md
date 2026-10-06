# [ ] COLOR CYCLING TESTING

Automated coverage (run these first):
- `QA/unit/pcyc-unit.bas`: shift math, range bookkeeping, serialization, the cycled buffer and the indexer (`qb64pe -w -x -o pcyc-unit.run pcyc-unit.bas && ./pcyc-unit.run`)
- `DEV/tools/test-cycle-exports.sh`: every format round trip, the generated `.bas` compiling and animating, and GrafX2 / ffmpeg / netpbm interop
- `QA/draw-qa.sh tests/palette-cycle-basic.sh tests/palette-cycle-gestures.sh tests/palette-cycle-strip.sh`

The manual checks below cover what automation can't see: feel, speed and real third-party programs.

## [ ] TOGGLE

### [ ] Shift+Tab
1. [ ] Open `SAMPLES/COLOR CYCLING/waterfall.draw`
2. [ ] Press `Shift+Tab`: the water falls, the foam ripples outward, and the status bar shows `[CYC]`
3. [ ] The palette strip swatches in the ranges animate too
4. [ ] Press `Shift+Tab` again: true colors come back, and `[CYC]` goes away
5. [ ] Plain `Tab` still toggles the toolbar and does not affect cycling
6. [ ] While typing in a text layer, `Shift+Tab` does nothing

### [ ] Menu
1. [ ] Palette → Cycle Colors toggles it, and its checkmark follows `Shift+Tab`
2. [ ] Palette → Color Cycling flyout lists all 9 commands
3. [ ] Command palette (`?`), type `cycl`: every color cycling command is listed

## [ ] MAKING RANGES

### [ ] From marked swatches
1. [ ] Turn on Palette Ops and right-drag across 6 swatches to mark them
2. [ ] Palette → Color Cycling → Range From Marked Chips: a solid band appears under the 6 swatches
3. [ ] With fewer than 2 marked swatches, the status bar explains what to do instead

### [ ] Ctrl+drag
1. [ ] In Palette Ops, `Ctrl`+left-drag across swatches: a white preview band follows the drag
2. [ ] Release: the range is created, and the status bar shows `Added CYC n: lo-hi FWD 10.0/s`
3. [ ] `Ctrl`+drag over part of an existing range replaces it (no overlaps)

### [ ] Gestures on a range swatch
1. [ ] `Ctrl`+left-click cycles the direction FWD → REV → PING, and the band changes from solid to dash-dot to dashed
2. [ ] `Ctrl`+right-click pauses the range (band dims, colors hold) and resumes it
3. [ ] `Ctrl`+wheel up/down makes it faster/slower; the status bar readout updates
4. [ ] `Ctrl`+`Shift`+wheel makes small speed changes
5. [ ] `Ctrl`+middle-click deletes the range
6. [ ] Hovering a range swatch shows `CYC n: lo-hi MODE x.x/s` in the status bar

## [ ] UNDO

1. [ ] Undo (`Ctrl+Z`) and redo (`Ctrl+Y`) each step: add, delete, direction, pause, clear all
2. [ ] Five quick `Ctrl`+wheel notches undo as ONE step
3. [ ] Undo after a Palette Ops color delete restores the color AND the range

## [ ] PALETTE OPS BOOKKEEPING

1. [ ] Middle-click (delete) a swatch inside a range: the range shrinks by one
2. [ ] Delete swatches until the range has 1 color left: the range disappears
3. [ ] `Shift`+middle-click (insert) inside a range: the range grows by one
4. [ ] Drag a whole range's swatches somewhere else: the range moves with them
5. [ ] Drag one swatch out of the middle of a range: the range keeps its index span

## [ ] DUPLICATES / RULES

1. [ ] Give a swatch inside a range the same color as an earlier swatch: its band shows a red checker
2. [ ] Palette → Color Cycling → Check Duplicate Colors lists that index
3. [ ] Pixels painted at 50% opacity in a cycling color do NOT cycle (expected)
4. [ ] Exports and PNG saves contain the true colors, not the colors on screen mid-cycle

## [ ] SAVE / LOAD

1. [ ] Save a document with 3 ranges (one REV, one PING, one paused), close it, and reopen it: all 3 come back exactly
2. [ ] File → New / Open another file: the ranges are cleared
3. [ ] An old (pre-v30) `.draw` opens fine with no ranges

## [ ] EXPORTS (File → Color Cycling)

1. [ ] Export Cycling QB64 Program: compile with `qb64pe -x`, then check it runs and cycles at the same speeds. SPACE pauses, `+`/`-` change the speed, R restarts, ESC quits
2. [ ] Export GIF + Cycle Ranges: open it in **GrafX2** and check the ranges cycle there (Palette → Cycling)
3. [ ] Export Animated GIF: open it in a browser; it loops smoothly with no jump at the seam
4. [ ] Export DeluxePaint ILBM: open it in GrafX2 / PyDPainter / DeluxePaint (Amiga emulator) and check the ranges cycle
5. [ ] Export DeluxePaint PBM: open it in DeluxePaint II Enhanced (DOSBox) or GrafX2
6. [ ] An art layer with transparency exports with the transparent color in GIF and LBM

## [ ] IMPORTS

1. [ ] Open a GrafX2 GIF with ranges: the palette and ranges load; `Shift+Tab` cycles
2. [ ] Open a DeluxePaint `.lbm` (ILBM and PBM): the palette and ranges load
3. [ ] `Ctrl+S` after opening a `.lbm`/`.gif` writes `NAME.draw` next to it; the original is untouched
4. [ ] Drag and drop a `.lbm` onto the window: it opens as a document
5. [ ] A plain GIF without ranges still opens as before

## [ ] PERFORMANCE

1. [ ] 320x200 with 2 ranges cycling: CPU stays low (compare with cycling off)
2. [ ] 1920x1080 canvas with a full-screen range: still responsive; drawing while cycling works
3. [ ] Pattern Tile Mode while cycling: all 9 tiles cycle together
