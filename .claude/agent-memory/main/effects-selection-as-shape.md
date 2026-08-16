---
name: effects-selection-as-shape
description: How edge/growth effects (drop shadow, outline, grow, glows, bevel…) support marquee selections in GUI/IMAGE-ADJ.BM
metadata:
  type: project
---

[Linux] Added 2026-08-15 (branch more-image-effects). Alpha-edge effects read the
SOURCE image's **alpha channel** to find the silhouette, then radiate an effect
from that edge — so on a **solid** layer they do nothing ("effects only work on
transparency"), and clip-to-selection wipes them because they draw *outside* the
shape.

**Fix = selection-as-shape.** When a marquee selection is active, feed the effect
the *selection silhouette* as its shape and composite only the NEW pixels back
over the untouched layer. Shared choke point in `GUI/IMAGE-ADJ.BM`:

- `IMGADJ_edge_shape_source&(layerImg, apW, apH)` — returns a layer copy whose
  alpha is forced opaque inside the selection / transparent outside (RGB kept);
  returns `0` when no selection → caller runs on the raw layer (normal behavior).
- `IMGADJ_composite_effect_only(layerImg, fxResult, shapeSrc, origSnap)` — for
  each pixel: if `fxResult == shapeSrc` (unchanged silhouette) keep the original
  layer, else source-over the effect pixel onto the original. This is what keeps
  the interior intact and adds only the radiated shadow/outline/glow/bevel. The
  `fp==sp` compare is robust (blur/soft pixels differ from the flat silhouette).
- `IMAGE_ADJ_apply_spatial_edge(adjResult, shapeSrc, label)` — if `shapeSrc<>0`
  composites effect-only + records undo; else delegates to `apply_spatial`.

**Per-effect wiring** (in each dialog's apply loop): build `xxEdge&` via
`IMGADJ_edge_shape_source&`; if non-zero run `ENGINE(xxEdge&, …)` + `apply_spatial_edge`,
else run the ORIGINAL `ENGINE(layer,…)` + its original `apply_spatial`/`apply_to_layer`
(don't lose alpha-preserving apply for inner effects). Free `xxEdge&` after.
**11 effects wired:** Drop Shadow, Long Shadow, Outline, Grow/Shrink, Bevel, Outer
Glow, Inner Glow, Corona, Backlight, Emboss, Chrome. Any NEW edge effect must add
the same 3-line branch. Color adjustments (brightness etc.) do NOT use this — they
still clip via `IMGADJ_clip_to_selection`.

Test: `QA/tests/effect-selshape.sh` (solid block + partial marquee + drop shadow →
asserts shadow lands INSIDE the block OUTSIDE the selection). Partial marquee drag
IS drivable via the harness `drag` (atomic press+move) despite older notes.

**Preview parity (done 2026-08-15):** the loupe (`IMAGE_ADJ_update_loupe`) captures
a **padded** window (`CONST IMGADJ_LOUPE_PAD`) so edge effects see real neighbours
instead of the crop's rectangular border (fixes glow/shadow rendering at the loupe
edge); `DIALOG_draw_preview` derives the pad from the size mismatch and shows only
the central window. Growth (`apply_spatial`) dialogs drop the layer-alpha mask (it
wiped outward pixels). With a selection active, the loupe **frames the selection**
(`IMGADJ_sel_bbox%`) and builds `IMGADJ_SHAPE_THUMB` (silhouette); edge dialogs
preview via `IMGADJ_fx_src&(ctx)` (silhouette or origThumb) + `IMAGE_ADJ_fx_preview_finish
ctx, growth%` (composite effect-only for sel, else alpha-mask for non-growth). Any
new edge dialog must use those two helpers in its preview block.
See also [[qb64pe-reserved-words]] (`off` bit me here → renamed `ceOff`).
