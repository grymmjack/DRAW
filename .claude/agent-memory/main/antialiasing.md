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
- AA line: `PAINT_wu_line` (Xiaolin Wu) via `PAINT_blend_pixel_sym`; `LINE_draw_clipped`/
  `_resolved` short-circuit to it when `CFG.ANTIALIAS% AND BRUSH_SIZE_pixels% <= 1`.

**What the loop CANNOT verify:** AA-*on* visual quality. The QA test
(`QA/tests/antialias-toggle.sh`) only checks the flag default, the source-route guard
structure, and an AA-on non-crash smoke. A human must eyeball soft brush/line output.

**Audit findings that de-scoped later phases:** no DRW bump (layer pixels already 32-bit,
history `_COPYIMAGE(...,32)`, BAS already emits `_RGBA32`+`_BLEND`); selection mask is
already a 32-bit image (`MARQUEE.SELECTION_MASK AS LONG`) so Phase 3/4 is de-binarizing
reads, not a schema break; text already has a persisted per-layer `antialias` flag.
Related: [[drag-drop-targets]] (same branch-then-fleet-test-then-merge workflow).
