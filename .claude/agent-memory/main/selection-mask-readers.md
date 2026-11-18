---
name: selection-mask-readers
description: How every MARQUEE.SELECTION_MASK reader tests a pixel - the scoping map for antialiased (soft) selections
metadata:
  type: project
---

Audited 2026-11-17 when Rick asked for antialiased selection tools ("selection tools are not
anti-aliased - they should be if it's enabled"). The mask is a canvas-sized 32-bit image,
selected = opaque white `_RGB32(255,255,255)`, else `_RGBA32(0,0,0,0)`; box selections may
have no mask (MARQUEE.BOX + MARQUEE.ACTIVE%).

A soft mask (partial alpha at ellipse / lasso / polygon edges) splits the readers:
- **Exact `= _RGB32(255,255,255)`** (partial = UNselected): `SELECTION_is_point_inside%`
  (MARQUEE.BM ~2588) - the choke point for ALL painting / fill / custom-brush / shape clipping
  (`PAINT_pset_with_symmetry`, `PAINT_blend_pixel`, `PAINT_erase_pixel`, FILL_*, FILL_ADJ_*,
  CUSTOM_BRUSH_*), plus copy / cut / delete (SELECTION.BM 140 / 215 / 538), fill FG/BG
  (COMMAND.BM CASE 313/314), SAVE_selection, ANS export, STROKE_SEL_apply, wand floods.
- **`_ALPHA32 > 0`** (partial = selected, full strength): MOVE lift + clear (MOVE.BM 382 / 849 /
  996 / 1036), TRANSFORM activate / commit / warp (binary nearest warp), merge / invert /
  expand / contract (all rebuild binary), edge cache for marching ants, bounds recomputes.
- **Proportional**: only `IMGADJ_sel_coverage&` (then thresholded at 50%).
- Every mask edit (merge, invert, grow / shrink, warp, wand flood) flattens it back to binary.

**How to apply:** soft selections need (1) builders writing coverage alpha, (2) a coverage
function replacing the boolean choke point so PAINT_* / fill scale by it, (3) cut / copy /
delete / move-lift / transform to blend by coverage, (4) mask ops to keep alpha. Not started -
pending Rick's go on the plan. Related: [[antialiasing]].
