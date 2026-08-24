# Anti-Aliasing — Phase 2c (smart shapes + soft eraser)

Plan: **PLANS/ANTI-ALIASING-PLAN.md**. Branch `aa-phase2c` (off main; 0/1/2a/2b merged).
This loop finishes the shape tools via the SS-COMMON chokepoints, and adds the one genuinely
new piece: the **coverage-subtract eraser** (soft erasing). Spray stays crisp by design
(stochastic 1px stipple — nothing to feather, like the 1px brush).

## The invariant + the caveat (unchanged)
- **AA default OFF; every AA-off path BYTE-IDENTICAL**, by construction:
  `IF NOT CFG.ANTIALIAS% THEN <verbatim original> ELSE <AA path>`. Never refactor the off-path.
- **AA-ON quality is VISUAL.** Loop proves builds clean + AA-off unchanged + AA-on no crash;
  a human reviews AA-on before merge.

## The big win
All 10 smart shapes commit through just two SS-COMMON helpers: **`SS_stroke_line`** (which
`SS_stroke_polyline` AND `SS_stroke_arc` both call — so it covers every stroke, polyline, and
arc) and **`SS_fill_polygon`**. AA those two and every smart shape gets AA at once. The
`commit%` flag keeps previews on the hard PSET/LINE path.

## 🔨 NOW — doing right now
_(all 5 boxes complete — Phase 2c done; Phase 2 COMPLETE)_

## Tasks

- [x] **1. AA smart-shape strokes.** DONE — `SS_stroke_line` routes thin → `PAINT_wu_line`; covers every smart-shape stroke, polyline, AND arc (both call it). Thick already AA. AA-off byte-equal. Commit c1255b6.

- [x] **2. AA filled smart shapes.** DONE — `SS_fill_polygon` overlays Wu edges on commit only (preview hard). AA-off byte-equal. Commit c1255b6. **(Human: eyeball a filled pie/pill/rounded-rect.)**

- [x] **3. Coverage-subtract eraser primitive.** DONE — `PAINT_erase_pixel` (dstAlpha − coverage*255, selection-gated) + `PAINT_erase_pixel_sym` in BRUSH.BM. Commit 78c01dd.

- [x] **4. AA eraser stamp + routing.** DONE — `PAINT_erase_circle_aa` (solid core + coverage-subtract feather); `ERASER_draw_at` uses it for round brushes >1px when AA on; 1px/square/AA-off keep the verbatim hard erase. AA-off byte-equal. Commit 78c01dd. **(Human: erase with a soft round edge over a filled area.)**

- [x] **5. Docs + QA.** DONE — QA smart-shape + eraser guards (9/9 pass); CHEATSHEET full AA coverage + crisp-by-design set; IDEAS Phase 2 COMPLETE; memory updated. Final `make` clean (binary current).

loop:on
