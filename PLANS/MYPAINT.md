# MyPaint brushes

Rick, 2026-11-17: "add my paint brush engine and brush load/save etc. with a palette to choose
those brushes" - "for now i don't have a toolbox tool so just add to tools menu".

## Sources and licences (checked 2026-11-18)

- **Engine: libmypaint v1.6.1, ISC** (github.com/mypaint/libmypaint). Vendored, not linked:
  `DEV/mypaint/vendor.sh` copies the brush engine + tiled surface into `native/mypaint/`,
  generates the settings headers from `brushsettings.json`, and `DEV/mypaint/patch.py` makes it
  build as C++ inside a QB64-PE `DECLARE LIBRARY` header: json-c removed (`mypaint_brush_from_string`
  is a stub), glib off, a handful of casts. `native/mypaint/COPYING` keeps the ISC notice.
  Builds on every OS the same way as the other `native/*.h` (no new link dependency, no CI change).
- **Brushes: mypaint-brushes, CC0-1.0** for every set (classic, deevad, Dieterle, experimental,
  kaerhon_v1, ramon, tanda - 196 brushes, ~3.7 MB with `_prev.png` previews). Shipped in
  `ASSETS/BRUSHES/MYPAINT/<set>/`, with `order.conf` and a README naming the authors.

## The model

- A brush = 64 settings (`MyPaintBrushSetting`), each a base value plus curves over 18 inputs
  (pressure, speed, random, stroke, direction, tilt, ...). A `.myb` file (v3) is JSON:
  `{"version":3, "settings": {"radius_logarithmic": {"base_value": 2.0, "inputs": {"pressure":
  [[0,0],[1,0.5]]}}, ...}}`. DRAW parses it in C (`native/mypaint_draw.h`, a small JSON reader)
  and calls `mypaint_brush_set_base_value` / `set_mapping_n` / `set_mapping_point`.
  Save writes the same JSON back (settings that differ from the default, plus every curve).
- Painting: `mypaint_brush_stroke_to(brush, surface, x, y, pressure, xtilt, ytilt, dtime, ...)`
  per pointer event; the brush emits dabs onto a `MyPaintTiledSurface` (64x64 tiles, RGBA
  premultiplied 15-bit fixed point). DRAW's surface hands out tiles **lazily**: the first
  request for a tile converts that part of the layer (8-bit straight BGRA) into fix15; the end of
  the stroke step converts the touched tiles back. A pixel whose fix15 value did not change keeps
  its original 8-bit value, so the round trip never alters pixels the brush did not touch.
- Write-back honours DRAW's rules: the selection's coverage (`SELECTION_cover%`-style: the mask
  passed as a pointer; new = old + (painted - old) * cover / 255), the layer's opacity lock
  (alpha kept), the layer apron offset (gotcha #14). Smudge brushes read colour through
  `get_color` from the same tiles, so they pick up the layer's pixels.
- Inputs: pressure / tilt from `TABLET` (Pen Control: after its pressure processing), the mouse
  = pressure 0.5 like MyPaint; dtime from the frame clock; view zoom = DRAW's zoom so
  "radius by zoom" settings behave.
- One undo step per stroke: the layer snapshot taken on press, the stroke's bounding box on
  release (the brush tool's history path).

## DRAW pieces

- `native/mypaint_draw.h` - unity build of the vendored C, the lazy-tile surface, `.myb`
  read / write, `mp_*` entry points (`mp_load`, `mp_save`, `mp_stroke_begin`, `mp_stroke_to`,
  `mp_stroke_end`, `mp_set_color`, `mp_get/set_base`, `mp_preview`).
- `TOOLS/MYPAINT.BI/BM` - `TOOL_MYPAINT`, state (current brush, folder, size / opacity overrides),
  press / drag / release, color from FG (HSV into the brush's color settings), history.
- `GUI/MYPAINT-PANEL.BI/BM` - the brush palette: a dock panel (`DP_MYPAINT`, like the Selection
  Bar's wiring - it floats / tabs / rows like any dock panel) with `<` GROUP `>`, LOAD / SAVE, the
  brush's name and size, and a grid of the `_prev.png` thumbnails; click = pick (and switch to the
  tool). Its own Scale (MYPAINT_PANEL_SCALE).
- Tools menu: MYPAINT BRUSH (picks the tool, opens the palette), View menu: MYPAINT BRUSHES
  (the palette). Action ids from a free range (grep first, gotcha #17).
- cfg `[MYPAINT]`: MYPAINT_BRUSH (last brush path), MYPAINT_PANEL + its geometry, MYPAINT_SIZE
  (radius offset, log), MYPAINT_OPACITY.
- QA dump lines `MYP` (tool, brush, last stroke bbox, dabs) and `MYPP` (panel, cells).

## Checklist

- [x] M1 research + this plan
- [x] M2 engine builds (`native/mypaint_draw.h`), a C unit check paints a stroke into a buffer
- [x] M3 .myb load / save + the shipped CC0 sets
- [ ] M4 brush palette panel + Tools / View menu entries + actions + cfg
- [ ] M5 painting through the engine: pen inputs, selection coverage, opacity lock, apron, undo
- [ ] M6 QA + docs (manual, SHORTCUTS, .claude/instructions, memory)
