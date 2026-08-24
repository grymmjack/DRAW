# Anti-Aliasing — Phase 2b (vector line/polygon completion)

Plan: **PLANS/ANTI-ALIASING-PLAN.md**. Branch `aa-phase2b` (off main; Phase 0+1+2a merged).
This loop finishes the **line/polygon family**: thin poly-line + bezier lines (they still use
QB64's built-in `LINE` in the common case), and poly-fill edge feathering. Curved smart shapes,
spray, and the eraser coverage-subtract are LATER loops (2c+).

## The invariant + the caveat (unchanged)
- **AA default OFF; every AA-off path BYTE-IDENTICAL to today**, guaranteed by construction:
  `IF NOT CFG.ANTIALIAS% THEN <verbatim original> ELSE <AA path>`. Never refactor the off-path.
- **AA-ON quality is VISUAL.** Loop proves: builds clean, AA-off unchanged, AA-on doesn't crash.
  A human reviews AA-on before merge.

## The pattern
Same as the ellipse `CIRCLE` fix: the thin/no-selection commit path uses a **built-in primitive**
(`LINE`) that bypasses the AA-routed `LINE_draw_clipped`/`_resolved`. Fix = add `OR CFG.ANTIALIAS%`
to the guard so AA routes to those SUBs (which already branch to the Wu line). AA off → verbatim
built-in `LINE`. Poly-fill instead overlays its edges as `PAINT_wu_line` in the fill color.

## 🔨 NOW — doing right now
➡️ **4. Docs + QA.**

## Tasks

- [x] **1. Thin poly-line AA.** DONE — `OR CFG.ANTIALIAS%` on both thin-segment guards (segment 2218 + close 3797); thin poly-lines route to LINE_draw_resolved (Wu). Preview left hard. AA-off byte-equal. Build clean. Commit 2db028d.

- [x] **2. Thin bezier AA.** DONE — `OR CFG.ANTIALIAS%` on the two `DRAWER_has_paint_mode%` guards (BEZIER.BM 205/252); thin curves route to LINE_draw_resolved (Wu). AA-off byte-equal. Build clean. Commit b0c387e. **(Human: eyeball a smooth bezier curve.)**

- [x] **3. Poly-fill edge AA.** DONE — Wu-edge overlay at the tool commit site (MOUSE.BM after POLY_FILL_scanline), NOT inside the shared SUB (it also rasterizes selection masks → must stay hard). Skips transparent/erase; targets current layer (=polyfill_target&). AA-off byte-equal. Build clean. Commit 2db028d. **(Human: eyeball a filled polygon's diagonal edges.)**

- [ ] **4. Docs + QA.** Extend `QA/tests/antialias-toggle.sh` with poly-line + poly-fill source-route guards. Update `CHEATSHEET.md` AA coverage (poly-line/bezier/poly-fill), `PLANS/IDEAS.md` Phase 2b status (and remaining 2c: smart shapes, spray, eraser), and `.claude/agent-memory/main/antialiasing.md`. Final `make` clean.

loop:on
