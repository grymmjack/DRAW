# Antialiased selections + Selection Bar

Rick, 2026-11-17: "we need to have antialias be a global thing for selections too ... it will
pay off by making draw truly flexible for me"; "for selection tools let's make a new panel too
for selection properties (layout similar to text properties) where we can have feathering /
threshold sliders for magic wand, etc." Controls chosen: feather, wand tolerance + options,
mode + grow/shrink, shape options.

## The model

`MARQUEE.SELECTION_MASK` stays a canvas-sized 32-bit image, but its **alpha is coverage**
(0..255, RGB white). Binary masks (0 / 255) behave exactly as before - every change below must
reduce to the old code path at coverage 0 or 255 (AA-off byte-identical by construction).

- `SELECTION_cover%(x, y)` -> 0..255: 255 with no selection / inside a box; the mask's alpha
  (RGB must be white, as the old exact-white test); 0 outside.
- `SELECTION_is_point_inside%` = cover >= 128 (the hard approximation for callers that
  can't scale; identical for binary masks).
- Writes scale by coverage: paint = source-over at cov * sel; erase = alpha * (1 - sel);
  copy = alpha * sel; cut / delete / move-lift clear = alpha * (1 - sel); fill = blend by sel.

Reader map: `.claude/agent-memory/main/selection-mask-readers.md`.

## Checklist

### A. Soft mask core
- [x] A1 `SELECTION_cover%` + `is_point_inside%` threshold (MARQUEE.BM)
- [x] A2 PAINT_pset_with_symmetry / PAINT_blend_pixel / PAINT_erase_pixel scale by cover
- [x] A3 builders write coverage with AA on: ellipse select, polygon select, freehand (lasso)
- [x] A4 mask ops keep alpha: merge (add = max, subtract = a*(1-b), intersect = min), invert
      (255 - a), expand / contract (max / min filter), bounds (> 0), edge cache (>= 128)
- [x] A5 consumers: copy / cut / delete (SELECTION.BM), fill FG/BG (CASE 313/314), move lift +
      clear (MOVE.BM), transform activate / commit / warp (smooth warp with AA), Export
      Selection, stroke selection, ANS export, swatches-from-selection, image adjust
- [x] A6 FILL.BM, FILL-ADJ, CUSTOM-BRUSH, RECT / ELLIPSE / LINE / POLY-FILL clipped draws,
      EXTRACT-GRID, ANIM-BRUSH, MOUSE.BM callers - scale or threshold, case by case
      (done 2026-11-18: fill (flood / global) + rect / ellipse / line write through
      `SEL_put_px` - soft; the rest read `SELECTION_is_point_inside%` = at least half selected)
- [x] A7 QA test (QA/tests/sel-soft-clear.sh: hard vs feathered Delete; sel-bar.sh): soft ellipse selection -> fill / delete / copy-paste / move / paint inside

### B. Mask kernels (native/selmask.h, -O3)
- [x] B1 feather (separable box blur x3 ~ gaussian, radius px)
- [x] B2 grow / shrink by radius (max / min, alpha kept), smooth
- [x] B3 combine (replace / add / subtract / intersect)
- [x] B4 wand flood: tolerance (RGBA distance), contiguous on/off, bounds; AA edge option

### C. Selection Bar (GUI/SEL-BAR, dock panel DP_SELBAR, shown with a selection tool)
- [x] C1 panel shell: dock registration like DP_TEXTBAR, wraps lines, UPPERCASE labels
- [x] C2 mode chips: REPLACE / ADD / SUBTRACT / INTERSECT (sticky; Shift / Alt still override)
- [x] C3 feather slider (new selections) + FEATHER button (current)
- [x] C4 wand: TOLERANCE slider, CONTIGUOUS, SAMPLE MERGED, ANTIALIAS EDGE
- [x] C5 GROW / SHRINK / SMOOTH amount + buttons, INVERT, DESELECT
- [x] C6 shape: rect / ellipse FIXED RATIO / FIXED SIZE (w x h) / FROM CENTER; lasso /
      polygon SMOOTHING
- [x] C7 cfg keys (SELECTION_*), palette commands, QA dump line (SELBAR / SELM / SELBARC); tooltips still to do
- [x] C8 QA test for the bar (QA/tests/sel-bar.sh); docs (manual, SHORTCUTS, instructions)

---

# Queue on this branch (fx-blurs-soft-selections), in order

## 1. X-sheet blur lanes: every DRAW blur + its properties (Rick 2026-11-17)
"we need the blur in the xsheet effects to allow motion blur - and controls for blur amount and
blur direction ... in addition to regular old blur"; "if we could have all the blurs we have in
draw, and their properties that'd be ideal".
- [x] native kernel (imgfx.h): motion / zoom / spin, premultiplied, bilinear; amount in px
      (zoom / spin: px of smear at the farthest corner); IMAGE_ADJ_blur_typed_at& (centre)
- [x] Blur dialog uses it (fast; ZOOM / SPIN amount now means px)
- [x] lanes: BLUR TYPE (17, stepped like BLEND: BOX / GAUSSIAN / MOTION / ZOOM / SPIN /
      MOTION FOLLOW = along the layer's own X/Y movement), BLUR ANGLE (18, degrees);
      BLUR range 0..64; zoom / spin centre = the layer's pivot (+ its move)
- [x] X-sheet: type menu, names on the lane, typed value; tip id range (ANIM_XS_tip 6000 + ..)
- [x] QA test + docs (docs/XSHEET-HOLDS-AND-LANES.md, draw-animation.md)

## 2. Soft selections + Selection Bar (sections A-C above)

## 3. MyPaint brushes (Rick 2026-11-17: "add my paint brush engine and brush load/save etc.
   with a palette to choose those brushes"; "for now i don't have a toolbox tool so just add
   to tools menu")
- [ ] engine (native, libmypaint-compatible dab model: settings + inputs + curves -> dabs)
- [ ] .myb load / save (JSON v3), ship a set of brushes (licence-checked)
- [ ] brush palette panel to pick them (thumbnails), Tools menu entry (no toolbox button)
- [ ] pressure / tilt / speed inputs from Pen Control; undo; QA + docs
