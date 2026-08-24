# Anti-Aliasing — Phase 2a (Ellipse) + inheritance verification

Plan: **PLANS/ANTI-ALIASING-PLAN.md**. Branch `antialiasing`. Phase 0+1 (flag, blend
primitive, AA brush circle, Wu line, Line tool, toggle UI, shared Edge-Mode button) is
DONE and reviewed. This loop extends AA to the **ellipse** (the canonical curved shape)
and verifies the tools that already inherit AA. Poly-fill / smart shapes / spray / eraser
are LATER loops (2b+).

## The invariant + the caveat (unchanged from Phase 0+1)
- **AA default OFF; every AA-off path BYTE-IDENTICAL to today**, guaranteed by construction:
  `IF NOT CFG.ANTIALIAS% THEN <verbatim original> ELSE <AA path>`. Never refactor the off-path.
- **AA-ON quality is VISUAL — the loop cannot judge it.** Loop proves: builds clean, AA-off
  unchanged, AA-on doesn't crash. A human reviews the AA-on ellipse before the next loop.

## Technique
Coverage via a signed-distance field (SDF) to the ellipse boundary, fed to the existing
`PAINT_blend_pixel`. For pixel offset (dx,dy) from center with radii (rx,ry):
`f = (dx/rx)^2 + (dy/ry)^2`; `sdf ≈ (sqrt(f)-1)*sqrt(f) / sqrt((dx/rx^2)^2 + (dy/ry^2)^2)`
(pixels, negative inside; center = deep inside → coverage 1). **Fill:** coverage =
`clamp(0.5 - sdf, 0, 1)`. **Outline (1px):** coverage = `clamp(1 - |sdf|, 0, 1)`. This same
SDF-coverage approach extends to the curved smart shapes in a later loop.

## 🔨 NOW — doing right now
_(all 6 boxes complete — Phase 2a done)_

## Tasks

- [x] **1. Ellipse SDF coverage helper.** DONE — `ELLIPSE_coverage!(dx,dy,rx,ry,isOutline)` in ELLIPSE.BM; SDF via implicit/gradient, reduces to |offset|-r for circles; fill=clamp(0.5-sdf), outline=clamp(1-|sdf|); center-guarded. Commit c1811e7.

- [x] **2. AA filled ellipse.** DONE — `ELLIPSE_fill_scanline_aa` walks the bbox (+1px), draws SDF fill coverage via `PAINT_blend_pixel`. `ELLIPSE_fill_scanline` branches to it when `CFG.ANTIALIAS%`; else verbatim scanline. Build clean. Commit c1811e7.

- [x] **3. AA ellipse outline.** DONE — `ELLIPSE_draw_outline_aa` (SDF outline coverage). `ELLIPSE_draw_clipped_outline` branches when `CFG.ANTIALIAS%`; else verbatim midpoint. Build clean. Commit c1811e7. **(Human: eyeball a smooth circle/ellipse outline + fill with AA on.)**

- [x] **4. Confirm the ellipse tool commit routes through the AA paths.** DONE — found a gap: the common outline case used QB64 `CIRCLE` (hard), bypassing AA. Fixed by adding `OR CFG.ANTIALIAS%` to the 3 outline-decision guards (MOUSE.BM 3372/3384/3392) so AA routes through `ELLIPSE_draw_clipped_outline`; AA-off keeps `CIRCLE`. Fill always routed. Preview left hard (snaps on commit, like Line). Build clean. Commit cfdfd6e.

- [x] **5. Verify poly-line + bezier already inherit AA.** DONE (source trace). Partial: **thick** brush lines inherit AA (LINE_draw_brushed → AA stamp), and the selection/paint-mode/opacity case routes to LINE_draw_clipped/_resolved (AA-branched). BUT the **common thin-line case uses built-in `LINE`** (MOUSE.BM:2227 poly-line; likely poly-line-close ~3795 and BEZIER.BM too) → bypasses AA, same as the ellipse `CIRCLE` gap. **Phase 2b:** add `OR CFG.ANTIALIAS%` to those guards (poly-line 2218/2220, poly-close, bezier) so thin lines route to `LINE_draw_clipped`. **RECT confirmed intentional AA no-op** (axis-aligned edges nothing to feather; thick-brush rect corners already AA via the stamp). Not fixed here (loop is ellipse-scoped).

- [x] **6. Docs + QA.** DONE — QA ellipse guard added (7/7 pass); CHEATSHEET AA coverage (Ellipse added, RECT crisp noted); IDEAS Phase 2a status + 2b TODO; memory updated (SDF technique + built-in-primitive bypass gotcha). Final `make` clean (binary current).

loop:on
