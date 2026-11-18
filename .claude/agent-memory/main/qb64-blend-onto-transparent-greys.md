---
name: qb64-blend-onto-transparent-greys
description: QB64-PE _BLEND (PSET / LINE / _PUTIMAGE) onto a pixel with alpha < 255 darkens soft pixels - copy raw with _DONTBLEND, composite with gj_sel_over
metadata:
  type: project
---

[Linux, QB64-PE main 2026-11-18, probed with a standalone program] QB64's 32-bit blend is wrong
whenever the DESTINATION pixel is not opaque:

- 50% white blended onto an empty pixel stores `807F7F7F` (alpha right, colour halved = grey).
- 25% red over 50% white gave `A0FFBFBF`; over opaque white it is right (`FFFEFEFE`).
- Same for `PSET` / `LINE` with `_BLEND` onto alpha 0.

`_PUTIMAGE` blends only when BOTH source and destination have `_BLEND` on (images default to
on): `_DONTBLEND` on either one makes it a raw copy. A probe that leaves the source on
`_DONTBLEND` "proves" blending is fine - set both flags deliberately when probing.

**Why:** soft pixels (AA strokes, MyPaint strokes, feathered selections) live on transparent
layers, so every blended copy of them into a fresh image or onto a transparent layer greys
their rims. Rick 2026-11-18: a feathered paste got grey rims; the Move preview of a soft hole
was darker than the commit.

**How to apply:**
- Copying pixels into a new / cleared image: `_DONTBLEND dst` around the `_PUTIMAGE`, or `_COPYIMAGE`.
- Compositing a soft image ONTO a layer (src over dst): `gj_sel_over` in `native/selmask.h`
  (straight-alpha over; wrapper `MOVE_put_float` in TOOLS/MOVE.BM), or per pixel
  `PAINT_cover_over` (TOOLS/BRUSH.BM).
- [Linux, 2026-11-18] The layer composite (SCREEN_render's composite buffer + group flushes), the
  merges and `LAYERS_flatten&` now use `MOVE_image_over` / `MOVE_image_over_rect` (native
  `gj_over_rect`). Proven by a control build with them reverted: two overlapping airbrush clouds
  (soft over soft, on an empty Background) merged down came out with a dark grey halo (2885 px
  off); the Preview-open composite path showed no difference either way. Test
  `QA/tests/soft-composite.sh` - it needs REAL soft pixels: an "ANTIALIAS=TRUE" line drew only
  hard pixels (3 colours), so the first version of the test passed on the broken build too.
  Check a soft-pixel test's colour count before trusting it.
- Audit scanner: `_NEWIMAGE` followed by a `_PUTIMAGE` into it with no `_DONTBLEND` between
  (38 sites on 2026-11-18). Related: [[antialiasing]], [[selection-mask-readers]].
