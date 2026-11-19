# MyPaint brushes (TOOLS/MYPAINT, GUI/MYPAINT-PANEL, native/mypaint_draw.h)

Rick, 2026-11-17: "add my paint brush engine and brush load/save etc. with a palette to
choose those brushes" / "for now i don't have a toolbox tool so just add to tools menu".
Plan and checklist: `PLANS/MYPAINT.md`. User docs: manual chapter 9 "MyPaint Brushes".

## Pieces

| Piece | What |
|---|---|
| `native/mypaint/` | libmypaint **v1.6.1 (ISC)**, vendored by `DEV/mypaint/vendor.sh` (from `~/git/_ext/libmypaint`, tag v1.6.1) and patched by `DEV/mypaint/patch.py` to build as C++ inside a `DECLARE LIBRARY` header: json-c gone (`mypaint_brush_from_string` is a stub), glib off, casts. Re-vendor = rerun vendor.sh; never hand-edit the copied files. [macOS] [Windows] those builds use **clang** (Apple clang / llvm-mingw), which errors where Linux g++ only warns (`register`, double→float narrowing in braces) and macOS `#define`s `YES` / `NO` (renamed `PAINTED_*` in `mypaint-brush.c`): check a patch.py change with `clang++ -std=c++17 -fsyntax-only -Inative` on a file that `#define`s YES / NO and includes `mypaint_draw.h` (shipped 2026-11-18 broken on both - farm found it) |
| `native/mypaint_draw.h` | Unity build of the engine + DRAW's surface: lazy 64 px tiles over the layer buffer (fix15 premultiplied), written back per `stroke_to`; an unchanged fix15 pixel keeps its exact 8-bit original; selection coverage lerp + opacity lock on write-back; own tiny JSON reader / writer for `.myb` v3. Entry points `mp_*` (TOOLS/MYPAINT.BI) |
| `DEV/mypaint/unit.cpp` | Standalone check: `g++ -O2 -std=gnu++17 -Inative -o /tmp/mp-unit DEV/mypaint/unit.cpp` - paints strokes, mask, save / reload, loads every shipped brush |
| `ASSETS/BRUSHES/MYPAINT/` | All 7 mypaint-brushes sets (**CC0**, 196 brushes + `_prev.png`), `order.conf` (MyPaint's groups), README (authors, upstream commit), COPYING-CC0 |
| `TOOLS/MYPAINT.BI/BM` | `TOOL_MYPAINT` (45), the brush (`MYPAINT_load%`, `MYPAINT_save%` + `MYPAINT_make_preview`, size: `MYPAINT_apply_size` / `MYPAINT_radius_log!` - by default (`CFG.MYPAINT_SIZE_FROM_BRUSH`) DRAW's brush size is the diameter, radius_log = LN(px / 2), re-applied at every stroke start; off = file radius + `CFG.MYPAINT_SIZE` / 10 in log units), the stroke (`MYPAINT_stroke_begin%` / `_step` / `MOUSE_release_mypaint` / `_finish` / `_abort`), dump `MYP` |
| `GUI/MYPAINT-PANEL.BI/BM` | The palette: dock panel `DP_MYPAINT` (11). Groups from order.conf, leftovers per folder, then MY BRUSHES (`<data>/MYPAINT-BRUSHES/`). Thumbnails of the shown group only (`MYPP_load_thumbs`). Dump `MYPP` / `MYPPB` |

## Rules

- **One stroke = one undo step**: `beforeImg` copied on press, `HISTORY_record_brush` on release
  only when the box changed and the image differs. A document load / new canvas calls
  `MYPAINT_stroke_abort` (all three creation paths - CLAUDE.md gotcha 15).
- **The layer's `_MEM` is held for the whole stroke** (`MYPAINT_MEM`); every step checks
  `_MEMEXISTS` first and aborts if the layer went away (gotcha 21). `mp_stroke_end` writes nothing
  (each `stroke_to` already wrote its tiles back), so aborting after the buffer is gone is safe.
- **Apron** (gotcha 14): the stroke works in buffer px (`MOUSE.UNSNAPPED_X + apronW`); the mask is
  canvas-sized and offset by (apronW, apronH) natively.
- **Picking the tool keeps the selection**: `MYPAINT_select_tool` sets the tool, then
  `TOOLS_reset_all FALSE` like every tool key. A bare `MARQUEE_reset` (as it did first) drops a
  box selection, and the stroke then paints unclipped (caught by mypaint.sh's exact compare).
- **Selection**: the marquee mask (soft coverage) or, for a plain box selection, a temporary
  white-box mask. Coverage = mask alpha (RGB white), like `SELECTION_cover%`.
- **Input**: pressure = `PEN_stroke_pressure!` with a pen (Pen Control's processing), 0.5 for the
  mouse; tilt from `PD_tilt_x/y`; dtime from `TIMER(.001)`, clamped 1 ms..0.5 s; view zoom =
  `SCRN.zoom!`. The release sends a pressure-0 event at the last spot.
- **Colour**: FG (left) / BG (right) into the brush's HSV base values (`mp_set_color`).
- **`[` / `]`** (actions 601 / 602) with the tool: `MYPAINT_size_step` - one brush size (`BRUSH_SIZE_increase` / `_decrease`) while it follows the brush size (`MYPAINT_SIZE_FROM_BRUSH=TRUE`, the default; Rick 2026-11-18 "the brush size should set the mypaint brush size too"), else `MYPAINT_SIZE` by 2. Reset Size (2686, `MYPAINT_size_reset`) sets the brush size nearest the file's diameter (`MYPAINT_file_size_index%`); the Settings SIZE slider is the brush-size index then. Action 2690 toggles following. Dump `MYPZ fromBrush brushPx radius*100 fileSizeIndex`.

## Actions (2680-2686, `TOOLS/MYPAINT.BI`)

TOOL (Tools > MyPaint Brush, also opens the palette), PANEL (View > MyPaint Brushes), LOAD, SAVE,
BIGGER, SMALLER, RESET. Command palette names start "MyPaint" / "View: MyPaint Brushes".

## Config `[MYPAINT]`

`MYPAINT_BRUSH`, `MYPAINT_SIZE_FROM_BRUSH` (TRUE), `MYPAINT_SIZE` (-40..40, only when that is FALSE), `MYPAINT_PANEL`, `MYPAINT_SET` (group name),
`MYPAINT_CELL` (24..128), `MYPAINT_PANEL_SCALE`. The panel / scale / set / cell keys are in
`WS_panel_keys$` (workspaces remember them).

## QA

`QA/tests/mypaint.sh`. Dump lines (DOCK dump):
- `MYPP vis x y w h group nGroups n cell cols rowsFit rowsAll scroll gridX gridY hover cur groupName`
- `MYPPB id x y w` - header controls (1 `<`, 2 `>`, 3 LOAD, 4 SAVE, 5 the group name; row 2 for LOAD / SAVE)
- `MYP tool active ready strokes steps x1 y1 x2 y2 size name|set|path` - the last stroke's changed box in buffer px (x1 > x2 = none)

## The MyPaint Brush Settings panel (2026-11-18)

`GUI/MYPAINT-SET` (`MPS_`, dock panel `DP_MYPSET` = 12, `REGION_MYPSET`, DP_H_FIXED: `MPS_h_for%(w)`),
View > MyPaint Brush Settings = action 2687 (`MPS_ACT_PANEL`), 2688 = Reset All. Eight sliders:
SIZE (`CFG.MYPAINT_SIZE`), OPAQUE / SHARP / GAIN / PIGMENT (`opaque` / `hardness` /
`pressure_gain_log` / `paint_mode` x 100), SMOOTH (`slow_tracking` x 10) through `mp_set_base`,
PRESSURE (`CFG.MYPAINT_MOUSE_PRESSURE`, replaces the mouse's fixed 0.5 in `MYPAINT_stroke_step`),
TWIST (`CFG.MYPAINT_TWIST` degrees -> native `mp_set_twist` turns = `barrel_rotation`, the last
`stroke_to_2` arg). The file's values are captured by `MPS_capture` in `MYPAINT_load%` /
`MYPAINT_save%` / `MYPAINT_init` and are each slider's reset. Sliders are `GUI/PANEL-SLIDER`
(`PSL_`, shared with the brush palette `GUI/BRUSH-PANEL`): one row (label | track | value) or
stacked when narrow; columns side by side in a wide dock. Dumps `MPS` / `MPSS` / `MPSB`.
Test `mypaint-settings.sh`. Placed under DP_MYPAINT's column when an arrangement has none
(`DOCK_mypset_place`).
