---
name: antialiasing
description: DRAW's experimental anti-aliasing mode — flag, coverage primitive, and how AA-off stays byte-identical
metadata:
  type: project
---

DRAW is adding an optional **anti-aliasing mode** (branch `antialiasing`), shipped in
phases behind one flag. Full plan + audited anchors: `PLANS/ANTI-ALIASING-PLAN.md`.
Default **OFF** to protect the hard-edged pixel-art identity.

**The invariant that governs every AA edit:** with AA off, every drawing path must be
**byte-identical to before**. This is guaranteed *by construction*, not by testing — each
chokepoint reads `IF CFG.ANTIALIAS% THEN <AA path> ELSE <verbatim original>`, and the AA
primitive itself collapses to the original `PSET` at full coverage. Never refactor the
off-path. See [[qb64pe-not-is-bitwise]] — the toggle uses `NOT CFG.ANTIALIAS%` which is
safe only because the flag is a canonical 0/-1 boolean (matches the CRT toggle).

**The one AA write primitive** (`TOOLS/BRUSH.BM`): `PAINT_blend_pixel (x,y,col,coverage!)`
+ `PAINT_blend_pixel_sym`. It does NOT hand-roll source-over — it scales the source
alpha by `coverage` and lets QB64 `_BLEND` composite (`out = src*a + dst*(1-a)`). At
`coverage >= 1.0` it takes the verbatim `PSET (x,y), resolvedCol~&` branch → byte-identical.
It honors the same gates as `PAINT_pset_with_symmetry`: `SELECTION_is_point_inside%` +
`OPACITY_LOCK_allows_draw%`, and composes the resolved color via `DRAWER_resolve_paint_color~&`.

**Phase 0+1 shipped (experimental):**
- `CFG.ANTIALIAS%` flag — 5 config sites modeled on `CRT_ENABLED` (CONFIG.BI/BM save+load,
  `DRAW.cfg.default` `[ANTIALIAS]`). `--options-list` self-documents it; `--option ANTIALIAS=TRUE` works.
- Toggle UI: **action 958** (was free — always grep first, gotcha #17), `CMD_register`
  "Toggle Anti-Aliasing", View → **ANTI-ALIASING** checkable menu item (checked mirror in
  `MENUBAR.BM`), and a **" AA"** badge appended to `tool_name$` in `STATUS_render`.
- AA brush: `PAINT_draw_filled_circle_aa` — solid core (`dist <= radius-0.5`) + 1px feather
  to `radius+0.5` via `PAINT_blend_pixel_sym`. Square stays hard (axis-aligned = nothing to AA).
  **Brush sizes are odd-only** (`BRUSH_PIXEL_SIZES(i)=(i-1)*2+1` → 1,3,5,…). The two smallest
  are special-cased: size 1 = single `PSET`, size 3 = a crisp plus-sign. When AA is on, size 3
  falls through to the AA circle (added `AND NOT CFG.ANTIALIAS%` to both plus-sign branches in
  `PAINT_on` + `PAINT_stamp_brush`). **Size 1 deliberately stays crisp** (Rick's call) — a single
  pixel has no edge to feather; soft-dabbing it would just make a weak translucent dot.
- AA line: `PAINT_wu_line` (Xiaolin Wu) via `PAINT_blend_pixel_sym`; `LINE_draw_clipped`/
  `_resolved` short-circuit to it when `CFG.ANTIALIAS% AND BRUSH_SIZE_pixels% <= 1`.

**Edge Mode — PP/AA are mutually exclusive.** Pixel-Perfect and Anti-Aliasing are
opposite edge treatments, so DRAW enforces **never both on**: enabling one turns the
other off, in every path — `BRUSH_SIZE_toggle_pixel_perfect` (covers action 609 + F6)
forces AA off; COMMAND.BM `CASE 958` forces PP off. A shared **Edit Bar button** (slot 28,
action **959**) controls whichever is the current *target*: **left-click** toggles that
target on/off, **right-click** (action **960**, wired via `EDITBAR_handle_right_click` +
a new B2 branch in MOUSE.BM ~1104) switches the target PP↔AA (live-swapping if active).
`EDGE_MODE_TARGET` (EDITBAR.BI, `EDGE_TARGET_PP`/`_AA`) only remembers which face shows;
truth stays in `BRUSH_SIZE.PIXEL_PERFECT` / `CFG.ANTIALIAS%`. The button paints an "AA"
tag (`EDITBAR_draw_aa_badge`, 8×8 font) when target=AA. Menu lives in **Edit**, not View
(AA is a draw-time behavior, not a view overlay like CRT). NOTE: `EDITBAR_action_enabled%`
uses the `funcname% = expr` return-assignment idiom in a one-line SELECT CASE — the MCP
linter flags these as "self-reference SIGSEGV" **false positives**; they compile fine.

**Phase 2a (Ellipse/Circle) shipped.** `ELLIPSE_coverage!(dx,dy,rx,ry,isOutline)` (ELLIPSE.BM)
= signed-distance-field AA: implicit `f=(dx/rx)²+(dy/ry)²`, divide `(√f−1)` by the gradient
magnitude to get pixel distance to the boundary (reduces to `|offset|−r` for a circle).
Fill=`clamp(0.5−sdf)`, outline=`clamp(1−|sdf|)`. `ELLIPSE_fill_scanline` / `ELLIPSE_draw_clipped_outline`
branch to `_aa` variants (walk bbox+1px, draw via `PAINT_blend_pixel`) when `CFG.ANTIALIAS%`.
**Gotcha found:** the ellipse *commit* (INPUT/MOUSE.BM) used QB64's built-in **`CIRCLE`** for the
common outline case, bypassing AA — fixed by adding `OR CFG.ANTIALIAS%` to the 3 outline guards.
Same **built-in-primitive bypass exists for poly-line** (`LINE` at MOUSE.BM:2227) and likely
bezier/poly-close → Phase 2b must add the same `OR CFG.ANTIALIAS%` guard there. **RECT is an
intentional AA no-op** (axis-aligned; thick-brush rect corners already AA via the stamp). The SDF
approach is the template for curved smart shapes. Drag previews stay hard (snap on commit, like Line).

**Phase 2b (poly-line, bezier, poly-fill) shipped.** Thin poly-line/bezier had the same
built-in-primitive bypass as the ellipse `CIRCLE` — fixed with `OR CFG.ANTIALIAS%` on their
thin-line guards (poly-line MOUSE.BM 2218/3797; bezier `DRAWER_has_paint_mode%` guards
BEZIER.BM 205/252) so thin lines route to `LINE_draw_resolved` (Wu). **Poly-fill** feathers
its diagonal edges by overlaying `PAINT_wu_line` per edge in the fill color — done at the
tool COMMIT site (INPUT/MOUSE.BM after `POLY_FILL_scanline`), NOT inside `POLY_FILL_scanline`
itself, because that SUB is **also used to rasterize selection masks** (MARQUEE.BM) which must
stay hard. Skips the transparent/erase case; targets the current layer (=polyfill_target&).
Phase 2c remaining: curved smart shapes (reuse the SDF approach), spray, eraser coverage-subtract.

**Phase 2c (smart shapes + soft eraser) shipped — Phase 2 COMPLETE.** All 10 smart shapes
commit through two SS-COMMON chokepoints: **`SS_stroke_line`** (which `SS_stroke_polyline` AND
`SS_stroke_arc` both call — so one Wu branch AA's every stroke/polyline/arc) and **`SS_fill_polygon`**
(Wu edge overlay on commit only; preview stays hard). **Soft eraser** is the one genuinely new
primitive: `PAINT_erase_pixel(x,y,coverage)` = coverage-SUBTRACT (`dstAlpha − coverage*255`, reads
POINT on the current layer, selection-gated, opacity-lock does NOT gate erasing) + `_sym` +
`PAINT_erase_circle_aa` (solid core + feather). `ERASER_draw_at` uses it for round brushes >1px when
AA on; 1px/square/AA-off keep the verbatim hard `PAINT_stamp_brush` erase. **Intentional AA no-ops:**
RECT + square brush/eraser (axis-aligned), 1px brush, **spray** (stochastic 1px stipple — nothing to
feather). Remaining AA work is Phases 3-6 (fill/wand tolerance, feathered selection, bilinear
transform/crop resample, text `aaActive%` wiring) — NOT the raster drawing tools, which are done.

**What the loop CANNOT verify:** AA-*on* visual quality. The QA test
(`QA/tests/antialias-toggle.sh`) only checks the flag default, the source-route guard
structure, and an AA-on non-crash smoke. A human must eyeball soft brush/line output.

**Audit findings that de-scoped later phases:** no DRW bump (layer pixels already 32-bit,
history `_COPYIMAGE(...,32)`, BAS already emits `_RGBA32`+`_BLEND`); selection mask is
already a 32-bit image (`MARQUEE.SELECTION_MASK AS LONG`) so Phase 3/4 is de-binarizing
reads, not a schema break; text already has a persisted per-layer `antialias` flag.
**[2026-08-25 correction — BUG-7] The Phase 2c eraser wiring was INCOMPLETE.** The note above
("`ERASER_draw_at` uses it for round brushes >1px") described the *intended* design, but
`ERASER_draw_at` had **zero callers** — the live eraser stroke goes `MOUSE_tool_brush → PAINT_on`,
which (AA on) stamped `PAINT_draw_filled_circle_aa` with the transparent color; `PAINT_blend_pixel`
detects alpha=0, `_DONTBLEND`s, and writes alpha-0 at every coverage level → a HARD full-circle
erase, not the soft coverage-subtract feather. So the soft AA eraser shipped dormant. Fixed on
`v2.0.0-input-hardening`: `PAINT_on` (interpolation) AND the single-stamp path now route to
`PAINT_erase_circle_aa` when `CFG.ANTIALIAS% AND _ALPHA32(col)=0 AND round AND radius>=1`. Entirely
inside the `IF CFG.ANTIALIAS%` branch → AA-off byte-identical. Lesson: a dormant feature hides when
the primitive exists and looks correct but nothing calls it — grep for callers, don't trust the SUB.

Related: [[drag-drop-targets]] (same branch-then-fleet-test-then-merge workflow).
