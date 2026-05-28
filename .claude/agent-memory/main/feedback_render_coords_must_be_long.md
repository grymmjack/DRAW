---
name: feedback-render-coords-must-be-long
description: DRAW's render-pipeline coordinate variables (dx, dy, tdx, tdy, baseDX/Y, spdx/spdy, cv_left/right/top/bottom, new_cx/cy, ovlDX/Y) must be LONG, not INTEGER. canvasW * zoom overflows 16-bit INTEGER at high zoom on large canvases — the math silently wraps and the rendered canvas lands far off-screen.
metadata:
  type: feedback
---

QB64-PE `INTEGER` is 16-bit signed (-32768..32767). DRAW's render math
multiplies `SCRN.canvasW& * SCRN.zoom!` to compute the zoomed blit size,
then offsets it to center in the viewport:

```
zw& = SCRN.canvasW& * SCRN.zoom!            ' LONG (correct)
dx& = (SCRN.w& - zw&) \ 2 + SCRN.offsetX%   ' MUST be LONG
```

For a 4480-wide canvas (e.g. Screens.png collage) at zoom 16:
- `zw& = 4480 * 16 = 71680`
- `dx = (864 - 71680) \ 2 = -35408` — overflows INTEGER, wraps to ~+30128

The dispatcher fires the zoom action correctly, `ZOOM_to_level_canvas_center`
correctly sets `SCRN.zoom!`, but the render places the canvas off-screen.
Bug never showed up on small (320×200) canvases because at 32x the math
gives `-4688`, which fits INTEGER. The instant a canvas wider than ~2000px
is loaded and zoomed past ~7x, this triggers.

**Why:** Pre-existing assumption from when canvases were always small.
The pipeline grew large canvas support without widening the coord types.
First triggered visibly when user pressed Z+9 (1600%) and Z+0 (3200%) on
Screens.png and reported "canvas vanishes into limbo space" (their phrase
turned out to be literally accurate).

**How to apply:** any new render-path coord variable (a position computed
from `canvasW * zoom` math) must be declared `AS LONG`, never `AS INTEGER`.
Any new render SUB taking dx/dy params must use `AS LONG`. The widened
chain is currently:
- `SCREEN_render` locals: `dx, dy, tdx, tdy, baseDX, baseDY, spdx, spdy`
- SUBs: `RENDER_layers`, `RENDER_grids`, `RENDER_tool_previews`,
  `TRANSPARENCY_render` (x/y/w/h all LONG), `REFIMG_render`,
  `SYMMETRY_render_guides`, `TEXT_render_preview`
- Zoom centering: `new_cx, new_cy, old_cx, old_cy, scrCx, scrCy,
  cv_left/right/top/bottom, vp_left/right/top/bottom, vp_cx, vp_cy`
  in `ZOOM_to_level_canvas_center`, `ZOOM_adjust_offset`, `ZOOM_to_region`
- `PIXEL-ANALYZER` overlay coords: `ovlDX, ovlDY`

Still INTEGER (intentional, smaller user-controlled values, separate
refactor if it becomes a problem): `SCRN.offsetX%`, `SCRN.offsetY%`,
`SCRN.panelShiftX%` (TYPE fields). At extreme zoom + extreme pan,
panning could in principle push these past INTEGER too; if a future bug
report shows pan-not-working at 32x on huge canvas, widen these next.

Fixed in the crt-overlay branch (May 2026). See PR or git blame on the
SUB signatures above for the full type-widening diff.
