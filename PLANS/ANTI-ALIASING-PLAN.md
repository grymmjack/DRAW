## Plan: Antialias Mode — LOE + WBS

DRAW today is hard-edge by construction: every paint path lands on `PSET` (or `_PUTIMAGE` with `_DONTBLEND` for eraser), every selection/fill/picker assumes exact color equality, and every export round-trips through 32-bit BGRA without subpixel coverage. Adding a global "AA mode" is **not** a 1-line `_ANTIALIAS` flag — it touches drawing primitives, the stroke system, brushes, fills, selection/wand, transforms, custom-brush stamping, smart shapes, text, the picker, the eraser, history, DRW serialization, and BAS export. Recommended approach: a **per-document AA toggle** (so existing pixel-art workflows are untouched) implemented in **6 phases** behind one feature flag, shipped phase-by-phase rather than as a single mega-PR.

### LOE Summary

T-shirt sizing in **complexity points** (CP) — relative effort, not calendar time. 1 CP ≈ a focused half-day of senior work on this codebase. Risk: L=Low, M=Medium, H=High.

| Phase | Scope | CP | Risk |
| --- | --- | ---: | --- |
| 0. Foundation: AA flag, color/alpha helpers, mode plumbing | Toggle + cfg + theme + status indicator + helpers | **5** | L |
| 1. Primitive drawing: `PAINT_pset_with_symmetry`, brush stamp, line/rect/ellipse | Wu-line, coverage-based circle/square stamps, soft-edge brush | **18** | M |
| 2. Tools using primitives: Line, Rect, Ellipse, PolyLine/Fill, Bezier, Spray, Eraser, Symmetry, Crosshair, Smart Shapes (11 sub-tools) | Re-route every shape tool through AA primitives; preserve preview parity | **22** | M |
| 3. Coverage-aware ops: Fill (flood + tolerance), Magic Wand, Picker, Transparency-sample, opacity-lock | Replace exact-equality with tolerance/coverage thresholds | **14** | H |
| 4. Selection / Transform / Custom Brush / Stroke FX | Soft-edge marquee feather, AA transform resample, custom-brush sub-pixel stamp, outline FX | **16** | H |
| 5. Output & I/O: Text rasterization, BAS export, BMP/PNG/etc., DRW v-bump, History | Confirm alpha round-trips; emit AA-safe BAS code | **9** | M |
| 6. Polish: Settings UI, hotkey, theme, docs (CHEATSHEET/MANUAL/wiki), QA tests | Ship-ready | **6** | L |
| **Total** | | **90** | |

> Scale interpretation: **XL initiative**. Plan to ship Phase 0+1 first as an "experimental AA preview" (one or two tools), then expand.

### WBS (key items)

**Phase 0 — Foundation (5 CP):** `CFG.ANTIALIAS%` flag, menu/hotkey/status badge, new `PAINT_blend_pixel` + coverage helpers in _COMMON.BM, DRW persistence stub.

**Phase 1 — Primitives (18 CP):** Branch `PAINT_pset_with_symmetry` and `PAINT_on` in BRUSH.BM; add Wu-line, coverage circle/square, soft-edge stamp; `_MEM`-based hot loop; pixel-perfect single-pixel branch preserved.

**Phase 2 — Shape Tools (22 CP):** LINE.BM, RECT.BM, ELLIPSE.BM, POLY-LINE.BM+POLY-FILL.BM, BEZIER.BM, SPRAY.BM, ERASER.BM (coverage subtract — gotcha #21), SYMMETRY.BM, 11 Smart Shapes sub-tools.

**Phase 3 — Coverage Ops (14 CP, highest semantic risk):** Tolerance + soft fringe in FILL.BM; 8-bit alpha mask for `MAGIC_WAND_*` in MARQUEE.BM — *this ripples to transform/copy/paste*; picker no-snap path; opacity-lock becomes coverage-weighted.

**Phase 4 — Selection/Transform/Custom Brush (16 CP):** Promote selection mask to 8-bit alpha; bilinear/bicubic resample in TRANSFORM.BM and CROP.BM; sub-pixel stamping in CUSTOM-BRUSH.BM; AA stroke-sel outline.

**Phase 5 — Output & I/O (9 CP):** Verify FILE-BAS.BM round-trips AA art; export formats; DRW version bump (gotcha #15); history alpha round-trip; text rasterization sub-pixel.

**Phase 6 — Polish (6 CP):** Settings dialog AA section, tooltips/cursor, CHEATSHEET.md + manual + wiki, QA harness scripts.

### Verification

1. **Regression**: AA-off byte-equal compare of golden PNGs (QA harness) across every tool.
2. **AA-on**: visual diff vs. reference renders for line/rect/ellipse/poly/bezier/smart-shapes.
3. **Wand/Fill tolerance**: scripted seed colors with known fringe pixels verify mask widens by configured Δ.
4. **DRW round-trip**: save AA doc → load → re-save → byte-compare.
5. **BAS export**: emitted program runs and produces matching PNG.
6. **Performance**: brush stroke at 4096×4096 within current FPS budget via `PERF_*` counters.

### Decisions / Assumptions

- **Per-document toggle**, not global — protects the pixel-art identity of the app.
- **8-bit selection mask** is the schema-breaking change driving a DRW version bump.
- **Tolerance sliders** (wand/fill) ship even when AA is off — useful independently.
- **Out of scope**: vector layers, brush pressure dynamics, ClearType-style subpixel text. Only spatial AA on the raster grid.

### Further Considerations

1. **Ship strategy** — A: one big PR after Phase 6. **B (recommended)**: merge Phase 0+1 behind hidden flag, then incremental phase releases.
2. **Selection mask migration** — A: silent in-place upgrade. **B (recommended)**: bump DRW version + load warning. C: parallel 1-bit + 8-bit masks (high memory).
3. **Wand/Fill tolerance UI** — A: settings only. **B (recommended)**: live slider in property bar when tool active.

Plan saved to `/memories/session/plan.md`. Want me to dive deeper on any phase, or pivot to a smaller MVP scope (e.g., just Brush + Line + Ellipse AA)?