---
name: qa-splash-startup-state-dependency
description: RESOLVED — filled shapes on an apron-promoted layer landed off-canvas (raw-coord fill, gotcha #14); the splash was only a timing trigger
metadata:
  type: project
---

[Linux] 2026-09-06. RESOLVED. During the QA harness run, disabling the boot splash
(`SPLASH_ENABLED=0`) made filled-rect / paste / fire-on-selection render NOTHING —
deterministically. Root-caused with `_LOGINFO` A/B (QB64PE_LOG_HANDLERS=file):

**Root cause (NOT the splash):** filled-shape commit paths wrote at RAW canvas coords.
When a layer is apron-promoted (`apronW>0`, imgHandle larger than the canvas), canvas
(x,y) maps to buffer (x+apronW, y+apronH) — gotcha #14. Outline paths were apron-aware
(brush path `PAINT_stamp_brush` / `LINE_draw_brushed`), but the SOLID FILLS were not, so
the fill landed in the off-canvas apron border → invisible. The splash was only a TIMING
TRIGGER: with it off, an early `canvas_focus` click hit while the Move tool was active
(`MOUSE.BM` ~2212 captures+promotes the layer on click). RECT/ELLIPSE/POLYGON are all
"allowed in apron" (`MOUSE_tool_allowed_in_apron%`, MOUSE.BM ~29) so they draw on the
still-promoted layer without demoting → the fill must add the apron offset. Real
user-reachable path: move any layer (promotes it), then draw a filled shape → it vanishes.

**Fix (offset the fill by LAYERS(CURRENT_LAYER%).apronW%/apronH%, clip/color stay canvas):**
- RECT solid fill + symmetry siblings — `INPUT/MOUSE.BM` (~3341).
- ELLIPSE non-AA fill — `TOOLS/ELLIPSE.BM` `ELLIPSE_fill_scanline` (AA path via
  `PAINT_blend_pixel` was already apron-aware).
- POLYGON fill — `TOOLS/POLY-FILL.BM` `POLY_FILL_scanline`.
Verified: `tool-rect` splash-off 12/12; new deterministic regression test
`QA/tests/apron-fill-after-move.sh` (promote via Move, draw all 3 filled shapes) —
ellipse failed pre-fix, all pass post-fix; `tool-ellipse`/`tool-polygon-select`/
`apron-paint-after-move` no regressions.

Aside: `SPLASH_ENABLED=0` in the qa-harness DRAW adapter override list is NOT a good
QA default — it swaps splash-race flakes for this (now-fixed) determinism and left it
non-obvious; keep the splash ON in QA. Related: [[qa-harness-toolkit]].
