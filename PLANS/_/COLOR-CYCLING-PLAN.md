<!-- Status: PLANNED (not started) — written 2026-10-06. Working copy also at ~/.claude/plans/let-s-think-about-how-rosy-cosmos.md -->

# Palette color cycling for DRAW

## Context
Grymmjack wants DeluxePaint/GrafX2-style color cycling in DRAW. Ranges of palette indices animate at their own speeds, started and stopped from a key. Everything is done from the palette strip, without dialogs, building on Color Ops, where a chip *is* its pixels. The work is exported as a self-contained QB64 `.BAS` program that cycles. The first version also includes GrafX2-compatible GIF (CRNG), an animated GIF of the cycle, and DeluxePaint `.LBM` import and export.

**Decisions made with the user:**
- All four exports are in scope.
- The `.BAS` is a single file.
- **Shift+Tab** toggles cycling. Tab stays the toolbar toggle (action 401).
- Ping-pong is a DRAW extra. CRNG files can only store forward and reverse.

**Standards (verified):**
- **ILBM CRNG chunk** (DeluxePaint, Pro Motion, GrafX2): BE `pad, rate, flags, low, high`.
  - `rate` 16384 = 60 steps/s, linear.
  - `flags` bit0 = active, bit1 = reverse.
  - DeluxePaint writes 4 of these chunks.
- **GrafX2 GIF:** an application extension `21 FF 0B "CRNG\0\0\0\0" "1.0"` holding 6-byte records (`rate BE16, flags BE16, lo, hi`), up to 16 ranges.
  - Verified byte-for-byte on `~/git/qb64/qb64/IMAGE-TESTS/ASSETS/test.gif`: ranges 1–3 forward and 32–47 reverse.
- **GIF and PNG have no standard for cycling.** Sharing one means an animated GIF.
- **The Canvas Cycle technique** precomputes the positions of cycling pixels and updates only those. Color Ops' `PALETTE_OPS_edit_begin/apply` already does this.

**Prior art in the user's code:** `~/git/qb64/qb64/COLORS/PALETTE-CYCLE-IMAGE-32-8bpp.BAS`.
- A 32-bit screen, with an 8-bit image whose palette is rotated by `_PALETTECOLOR …, img&` and redrawn with `_PUTIMAGE`. This is the model for the `.BAS` export.
- Its rotation has an off-by-one: `range = end-start` should be `end-start+1`.

**Key constraint:** layers are RGBA, not indexed. A pixel belongs to the first palette index with the same RGB.
- Duplicate colors are ambiguous. They're flagged in the editor and made unique when importing GIF or LBM.
- Pixels changed by opacity or blend modes don't match a palette color exactly, so they don't cycle.

## Phase 0 — quick standalone checks (scratchpad)
1. The Shift+Tab keycode under GLFW (`--developer`, then `inputs.log`).
2. Whether `_LOADIMAGE(gif, 256)` keeps the file's palette indices. This decides whether a GIF LZW decoder is needed.
3. `_DEFLATE$`, `_BASE64ENCODE$`, `_BASE64DECODE$` and `_INFLATE$` round-trip, and `_MEMPUT` of a string into image memory.
4. An 8-bit overlay with `_CLEARCOLOR` and `_PALETTECOLOR`, drawn onto a 32-bit screen.
5. That the new field names compile (gotcha #20: reserved words).

## Phase 1 — cycling in the editor (first shippable)

**New module `GUI/PALETTE-CYCLE.BI/BM` (prefix `PCYC_`)**
- Include it after PALETTE-OPS in `_ALL.BI` and `_ALL.BM`.
- `TYPE PCYC_RANGE`: `lo`, `hi`, `rate` (CRNG units, so round-trips are lossless), `cmode` (FWD/REV/PING), `active`.
  - Up to 16 ranges, kept sorted, never overlapping.
- Global `PCYC.ENABLED` holds view state only; it isn't saved in documents.
- **Timing** works the same in the editor, the `.BAS` and the animated GIF:
  - steps/s `= rate*60/16384`
  - step `k = INT((now - origin) * sps)`, from absolute time so it never drifts
  - a speed change rebases the origin
- **Shift per step**, with `n = hi-lo+1`:
  - FWD: `k MOD n`
  - REV: `(n - k MOD n) MOD n`
  - PING: `m = k MOD 2n`, `a = m if m <= n else 2n-m`, shift `a MOD n`
  - Chip `lo+j` shows `PAL(lo + ((j-s) MOD n + n) MOD n)`.

**Rendering (`OUTPUT/SCREEN.BM`, `RENDER_layers`)**
- While cycling, always build the full composite and skip the single-layer shortcut.
- `PCYC_build_from compositeImg&` copies the composite into a persistent `PCYC.BUF`.
  - It records the positions of cycling pixels using a 64K lookup on the low RGB bits, confirmed against the full color.
  - It applies the current shifts, keeping each pixel's alpha.
- Then blit `PCYC.BUF` and set `CANVAS_CONTENT_SRC& = PCYC.BUF`, so the Preview window cycles too.
- On step-only frames, rewrite just the recorded pixels and skip the layer loop.
- In pattern-tile mode, do this once per frame.
- Never write into `COMPOSITE_BUFFER&`, `COMPOSITE_*_CACHE&` or the layer images.

**Idle loop (`DRAW.BAS`)**
- While cycling: `FRAME_IDLE = FALSE`.
- Set `SCENE_CHANGED` only when a range's shift changes, following the blinking text cursor's pattern. The scene cache and partial redraw keep working between steps.
- Compare a palette signature each frame so any palette change rebuilds the pixel map.

**Actions 2060–2069** (`CMD_init` / `CMD_execute_action`)

| ID | Action |
|---|---|
| 2060 | Toggle cycling (Shift+Tab, registered in `INPUTS_register_all`) |
| 2061 | Range from marked chips |
| 2062 | Delete range |
| 2063 | Clear ranges |
| 2064 | Cycle direction |
| 2065 | Pause range |
| 2066 / 2067 | Faster / slower |
| 2068 | Restart phase |
| 2069 | Report duplicate colors |

- **Menus and categories:** Palette menu, "CYCLE COLORS ✓" plus a "COLOR CYCLING" submenu; command palette entries; `INPUT_category_for%`.
- **Color Ops:** add 2060–2069 to its auto-off exceptions (`GUI/COMMAND.BM:866`).
- **Status bar:** add a `STATUS_flash` helper to `GUI/STATUS.BM`, show a `CYC` badge while cycling, and a hover readout such as `CYC 2: 32-47 REV 8.0/s`.

**Undo and palette changes**
- `PALETTE_snapshot$` gets a `"CYC1"` tail. `PALETTE_restore` reads it only when present, so old history still restores.
- Ranges follow palette edits:
  - delete: shift or shrink, and drop a range left with fewer than 2 colors
  - insert: shift or grow
  - reorder: the range follows its colors if they stay contiguous; otherwise the index span stays (DeluxePaint behavior)
- Range edits are recorded with `HISTORY_record_palette`.

**Saving (.draw v30)**
- `DRW_VERSION% = 30`. The new section goes after the v29 AI block and before history.
- On load, ranges go into local variables and are adopted after `PALETTE_OPS_reset` (line ~1663 runs after the file has been read).
- Call `PCYC_reset` from `PALETTE_OPS_reset`, which covers all three new-document paths plus the ASE and PSD importers.
- Add the missing reset in `DRW_load_from_png`.
- Update `.claude/instructions/draw-fileformat.md`.

## Phase 1b — palette-strip gestures and range bands

**New gestures in Color Ops mode.** They use Ctrl only, so none of the existing gestures change.

| Gesture | Effect |
|---|---|
| Ctrl+L-drag | Create a range (with a preview while dragging) |
| Ctrl+L-click a range chip | FWD → REV → PING |
| Ctrl+R-click | Pause the range |
| Ctrl+M-click | Delete the range |
| Ctrl+Wheel | Speed through a table (0.5–60 steps/s; one undo step per wheel burst) |
| Ctrl+Shift+Wheel | Fine speed adjustment |

**Bands drawn inside the chips** (bottom 2px), so the strip layout doesn't change:
- color per range;
- solid band for FWD, a chevron for REV, dashed for PING;
- dimmed when paused;
- a checker pattern when a duplicate color blocks the chip.

Files: `GUI/PALETTE-STRIP.BM` (render, wheel) and `GUI/PALETTE-OPS.BM` (`handle_strip_click`, `handle_held%`).

## Phase 2 — single-file `.BAS` export (`OUTPUT/PAL-INDEX.BI/BM` and `OUTPUT/FILE-CYCLE-BAS.BI/BM`, action 2330)

**Shared index helper**
- `IDX_index_image$(LAYERS_flatten&)`: exact color match first, otherwise the nearest palette color, with a cache.
- It also picks a transparent index and counts quantized pixels for a warning.

**What gets written into the program**
- One data blob: palette, ranges, a raw 32-bit base image, and an 8-bit overlay holding only the cycling pixels.
- DRAW runs `_DEFLATE$` and then `_BASE64ENCODE$`, and writes the result as `DATA` lines.

**Generated program**
- A 32-bit screen at the largest whole-number zoom that fits.
- The base image is drawn once.
- The overlay is an 8-bit image with `_CLEARCOLOR`. Each range rotates `_PALETTECOLOR` on its own timer.
- Space pauses and Esc quits.
- It uses only single-condition `IF`s and avoids reserved names.

The existing `FILE-BAS` and `FILE-QB64` exporters are not changed.

## Phase 3 — GIF writer, GrafX2 CRNG and GIF import (`OUTPUT/FILE-GIF.BI/BM`, action 2331)

**Writer**
- GIF89a with a global color table from `PAL()`.
- LZW: 5003-slot hash, clear code at 4096, a pre-allocated bit buffer, 255-byte sub-blocks.
- The CRNG block goes right after the color table, as GrafX2 does.
- Ping-pong is written as forward, with an optional private `DRAWCYCL` block that preserves it.
- Transparency uses a Graphic Control Extension.

**Import**
- `DRW_load` checks for `GIF8`. Only when a CRNG block is present: adopt the file's full palette and ranges, re-color using the true indices, and make duplicate colors unique.
- GIFs without CRNG load exactly as today.

## Phase 4 — animated GIF of the cycle (action 2332)
- **Frames:** frame 1 is the full image. Later frames cover only the bounding box of the cycling pixels, each with a local color table holding that step's palette. The LZW data is encoded once and reused.
- **Loop:** `NETSCAPE2.0` loop forever. Total length is the least common multiple of the range periods in 2-cs ticks, capped at 1000 frames or 60 s; DRAW warns if the cap cuts the loop short.

## Phase 5 — DeluxePaint `.LBM` (`INPUT/FILE-LBM.BI/BM`, `OUTPUT/FILE-LBM.BM`, actions 2333–2335)

**Reader**
- Recognize `FORM…ILBM` or `FORM…PBM ` in `DRW_load` (one hook covers every open path).
- Chunks: `BMHD`, `CMAP` (4-bit correction), `CRNG` (skip empty ones), `CAMG` (refuse HAM, expand EHB), `BODY` (ByteRun1).
- Convert planar to chunky. Mask or transparent color becomes alpha 0.
- Build the document through `DRW_create_canvas_at_size`.

**Writer**
- ILBM planar by default, with `ceil(log2(colors))` planes. PBM chunky is a second option.
- Chunks: `BMHD` (ByteRun1, 10:11 aspect for 320×200), `CMAP`, max(4, n) `CRNG`, and an optional `DRCY` chunk that preserves ping-pong.
- Add `*.lbm;*.iff` to the open filters in `TOOLS/LOAD.BM` and to drag-and-drop.

**File menu:** a "COLOR CYCLING" submenu next to EXPORT AS.

## Phase 6 — docs and tests
- `SHORTCUTS.md` (regenerate the binding index).
- `docs/MANUAL/03-color-palette.md`: a Color Cycling section.
- `docs/MANUAL/10-file-io.md`.
- Fix the outdated Shift+Tab references in `PLANS/TUTORIAL`.
- `PLANS/TESTS` checklist.
- `QA/tests/palette-cycle-*.sh`.

## Verification
- **Every phase:** `make`; the duplicate action-ID audit (gotcha #17); the `AND`-guard audit (gotcha #18) on new files.
- **Phase 1, Xvfb + xdotool:**
  - Load a fixture with one range, press Shift+Tab, snap the canvas, wait 0.5 s, snap again → the regions differ.
  - Shift+Tab off → matches the base snapshot.
  - Undo of a range edit restores the strip.
  - Save and reopen → `xxd` shows the v30 section and the ranges return.
  - `draw-watch.sh` for CPU use.
- **Phase 2:** compile the generated `.bas` with `~/git/qb64pe/qb64pe -w -x`, run it under Xvfb, take two screenshots 0.3 s apart → they differ; Esc → exit code 0.
- **Phase 3:**
  - Open `test.gif` → ranges (1–3 fwd, rate 0x0750) and (32–47 rev, rate 0x0A5C).
  - Re-export → the CRNG bytes are identical (`xxd`), `compare -metric AE` = 0, and ImageMagick/ffmpeg decode the file.
- **Phase 4:** `identify` shows the planned frame count and delays; ffmpeg decodes it.
- **Phase 5:** `ffmpeg -i out.lbm out.png` matches a PNG export (AE = 0); an LBM → DRAW → LBM round trip keeps the CRNG chunks.

## Sources

- [ILBM (Wikipedia)](https://en.wikipedia.org/wiki/ILBM): CRNG chunk, rate units, flags

- [LBM Format (ModdingWiki)](https://moddingwiki.shikadi.net/wiki/LBM_Format): CRNG byte layout, CCRT, DeluxePaint writes 4 CRNG chunks

- [Cosmigo community: saving color-cycling images](https://community.cosmigo.com/t/how-to-save-a-color-cycling-image/713): GIF has no cycling standard; export frames

- [Canvas Cycle (Joseph Huckaby, art by Mark Ferrari)](https://experiments.withgoogle.com/canvas-cycle): precompute cycling-pixel offsets, update only those

- GrafX2 GIF CRNG extension: verified from bytes in `~/git/qb64/qb64/IMAGE-TESTS/ASSETS/test.gif` (parser prototype: `~/git/qb64/qb64/IMAGE-TESTS/GRAFX2-GIF.BAS`)

- Prior QB64 cycling: `~/git/qb64/qb64/COLORS/PALETTE-CYCLE*.BAS`
