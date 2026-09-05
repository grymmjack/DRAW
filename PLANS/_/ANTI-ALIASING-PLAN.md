# Plan: Antialias Mode — revised against current code (2026-08-24)

> Revised on branch `antialiasing` after a full audit of the current pipeline (the
> original May-2025 estimate is in git history). Anchors below are verified against
> today's code. **Net: smaller and less risky than the original 90-CP estimate** —
> AA pixels already round-trip through every persistence path, so there is **no DRW
> format change and no history/export work**. The real work is the *drawing* side.

DRAW is hard-edge by construction: the innermost pixel write is `PSET (x,y), resolvedCol`
in `PAINT_pset_with_symmetry`, every shape tool is in-BASIC Bresenham/midpoint feeding
that primitive, fill/wand/picker test **exact** color equality, and transform/crop/custom-
brush resample **nearest-neighbor**. A global "AA mode" is a per-document/`CFG` toggle that
branches these paths to coverage-weighted blending, shipped in phases behind one flag.

## Ground truth (audited anchors)

**Primitive chokepoints** (both in `TOOLS/BRUSH.BM`, names accurate):
- `PAINT_pset_with_symmetry (x,y,col,apply_symmetry)` — `BRUSH.BM:45`. Innermost write is
  `PSET (x%,y%), resolvedCol~&` where `resolvedCol~& = DRAWER_resolve_paint_color~&(x,y,col)`
  (pattern/gradient/paint-mode resolution — **AA must compose with this, not bypass it**).
  Gated by `SELECTION_is_point_inside%` + `OPACITY_LOCK_allows_draw%`. Eraser/transparent
  toggles `_DONTBLEND` when `_ALPHA32(col)=0` (`BRUSH.BM:60-63`).
- `PAINT_on ()` — `BRUSH.BM:97`. Stroke interpolator (Bresenham) with size branches.
- Pixel-perfect single-pixel branch **already exists** (`BRUSH.BM:150-208`, `PP_STROKE`/
  `PP_BACKUP`/`PAINT_draw_pixel_perfect`) — preserve it (AA off for pixel-perfect).
- Brush stamps: `PAINT_draw_filled_circle` (`BRUSH.BM:295`, hard `dist_sq<=r_sq`),
  `PAINT_draw_filled_square` (`:319`), dispatcher `PAINT_stamp_brush` (`:341`).
- Symmetry fan-out: `SYMMETRY_get_mirrored_points` (`SYMMETRY.BM:119`), integer reflection.

**Shape tools** (all per-pixel `PSET`/`PAINT_stamp_brush`, files correct):
LINE.BM (`LINE_draw_clipped:21`, `_resolved:67`, `_brushed:111`), RECT.BM
(`RECT_draw_clipped_outline:20`, `_filled:51`), ELLIPSE.BM (`ELLIPSE_draw_clipped_outline:148`
midpoint, `_brushed:76`, `_fill_scanline:221`), POLY-LINE.BM (delegates to LINE),
POLY-FILL.BM (`POLY_FILL_scanline:20`), BEZIER.BM (`BEZIER_draw_cubic:162` → 5 backends),
SPRAY.BM (`SPRAY_on:22` → primitive), ERASER.BM (`ERASER_draw_at:93` = `PAINT_stamp_brush`
with alpha-0; **no subtract path exists — coverage-subtract is greenfield**).
Smart shapes: **10** sub-tools (SS-3D-CUBE/3D-TEXT/ARROW/BEVEL-RECT/PACMAN/PIE-DONUT/PILL/
POLYGON/ROUNDED-RECT/TAB), all commit through `SS-COMMON.BM` helpers gated by a `commit%`
flag (commit=primitive, preview=built-ins) — the commit/preview split point already exists.

**Coverage-sensitive ops** (all exact/nearest today):
- Fill `FILL_flood` (`FILL.BM:191`) — exact `POINT(x,y) = target_color~&`, no tolerance.
- Magic wand `MAGIC_WAND_select_with_mode` (`MARQUEE.BM:1080`) — exact-equality flood into
  the mask. Picker `PICKER_pick_color` (`PICKER.BM:169`) — exact 1×1 composite, no averaging.
- **Selection mask = a canvas-sized 32-bit image** `MARQUEE.SELECTION_MASK AS LONG`
  (`MARQUEE.BI:93`); membership tested binary `= _RGB32(255,255,255)` / `_ALPHA32>0`
  (`SELECTION_is_point_inside% MARQUEE.BM:2392`). **De-binarizing this (honor intermediate
  alpha) is the Phase 3/4 change — no 1-bit→8-bit widening, the buffer is already 8-bit.**
- Transform resample: inline nearest-neighbor `_MEM` inverse-map in `TRANSFORM_compute_preview`
  (`TRANSFORM.BM:172`, round at `:315`). Crop/resize: inline `_PUTIMAGE`-stretch
  (`CANVAS_resize_with_content:209`, `CROP_apply:508`). No named resample SUB.
- Custom brush: integer `_PUTIMAGE` stamp `CUSTOM_BRUSH_render` (`CUSTOM-BRUSH.BM:263`),
  nearest-neighbor scale/rotate. Opacity-lock: binary `OPACITY_LOCK_allows_draw%`
  (`BRUSH.BM:18`, `_ALPHA32(POINT)>0`).

**Foundation / IO (mostly free):**
- CFG boolean pattern (copy `CRT_ENABLED`): TYPE `CONFIG.BI` (~:437), default `CONFIG.BM`
  (~:142), save (~:1381), load CASE (~:2245), `DRAW.cfg.default`. Toggle+`CONFIG_save`
  modeled on CRT `COMMAND.BM:1458`; `CMD_register` `COMMAND.BM:429`.
- Menu checkbox: `MENUBAR_register_item ...,hasCheckbox,...` (`MENUBAR.BM:50`); mirror state
  in the `SELECT CASE actionId` block (`MENUBAR.BM:757-817`, e.g. CRT `CASE 950` at `:801`).
- Status badge: `STATUS_render` **now in `GUI/STATUS.BM:32`** (append to `tool_name$` like the
  SMART-SHAPES `" SNAP"`/`" LOCK"` badges at `:90-101`).
- **DRW: no change needed.** `DRW_VERSION% = 29` (`DRW.BI:31`); layer pixels already 32-bit
  BGRA (`DRW.BM:238`). Selection mask is NOT persisted (load `MARQUEE_reset`s it) — and AA
  does not require persisting it. (Persisting feathered selections would be a *separate*
  optional feature needing a v30 bump; out of scope here.)
- **History: no change.** All snapshots `_COPYIMAGE(...,32)` — AA alpha round-trips free.
- **Export: no change.** PNG via `_SAVEIMAGE` on 32-bit flatten preserves alpha
  (`FILE-EXPORT.BM:85`); BAS already emits `_RGBA32`+`_BLEND` (`FILE-BAS.BM:347,532`) → Phase 5
  = verification only.
- **Text: already AA-capable.** Per-layer `antialias` flag (`TEXT.BM`), persisted since DRW
  v20 (`DRW.BM:1336`) → Phase 5 text = default/override `aaActive%` from `CFG.ANTIALIAS%`.

## Core technical approach

Add `SUB PAINT_blend_pixel (x, y, col, coverage!)` (source-over: `out = src*cov + dst*(1-cov)`,
alpha combined) in BRUSH.BM. When `CFG.ANTIALIAS%` is **off**, `coverage=1` and the path stays
byte-identical to today's `PSET` (this is the regression invariant). When **on**, geometry
supplies fractional coverage: Wu's algorithm for lines (fractional endpoints → 2 pixels per
step weighted by distance), distance-to-edge ramp for circle/square stamps (1px AA fringe),
scanline partial-coverage for fills/polys. The blend reads dest via `POINT` for the MVP
(optimize to `_MEM` later); it still composes the **resolved** color and honors selection +
opacity-lock. Pixel-perfect and single-pixel-size stay hard-edged.

## Revised phases (dependency order)

| Phase | Scope | Risk | Notes vs original |
| --- | --- | --- | --- |
| 0. Foundation | `CFG.ANTIALIAS%` (5 sites) + menu toggle + status "AA" badge + `PAINT_blend_pixel`/coverage helpers | L | as planned |
| 1. Primitives | Branch `PAINT_pset_with_symmetry`/`PAINT_on`; Wu-line; coverage circle/square stamps; preserve pixel-perfect + AA-off byte-equality | M | as planned |
| 2. Shape tools | Route LINE/RECT/ELLIPSE/POLY-LINE/POLY-FILL/BEZIER/SPRAY + **10** smart-shapes through AA primitives; eraser coverage-**subtract** (new) | M | 10 not 11 |
| 3. Coverage ops | Fill tolerance + soft fringe; wand tolerance; picker average option; opacity-lock coverage-weighted; de-binarize `SELECTION_is_point_inside%` | M | **down from H** (no schema break) |
| 4. Selection/Transform/Custom brush | Feathered selection reads; bilinear resample in `TRANSFORM_compute_preview` + crop/resize; sub-pixel custom-brush stamp; AA marquee outline | M–H | mask already 32-bit |
| 5. Output/IO | **Verify** BAS/PNG/DRW/history round-trip AA (no new code); wire `CFG.ANTIALIAS%` → text `aaActive%` | L | **down from M** |
| 6. Polish | Settings AA section, tooltips, CHEATSHEET/docs, QA golden-diff harness | L | as planned |

## Verification (and the visual caveat)

**AA is inherently visual — the task-loop can build and run AA-**off** regression (golden-PNG
byte-equal, which the QA harness can check headlessly), but it CANNOT judge AA-**on** quality.**
So each phase ships as: (a) builds clean, (b) AA-off is byte-identical to pre-phase (golden
compare), (c) a human visually reviews AA-on before the next phase. Verification checklist:
1. AA-off golden-PNG byte-equal across every touched tool (headless, harness).
2. AA-on visual review (human) — line/rect/ellipse/poly/bezier/smart-shapes/brush.
3. Fill/wand tolerance: scripted seed with known fringe verifies mask widens by Δ.
4. DRW/history/BAS round-trip already covered by existing golden tests (no format change).
5. Perf: brush stroke on a large canvas within FPS budget via `PERF_*`.

## Decisions

- **Per-document/`CFG` toggle, default OFF** — protects the pixel-art identity.
- **No DRW version bump** — AA round-trips through the existing 32-bit paths.
- **Tolerance sliders** (wand/fill) are useful independently and ship even with AA off.
- **Out of scope:** vector layers, brush-pressure dynamics, subpixel/ClearType text,
  persisting feathered selections to DRW. Only spatial AA on the raster grid.

## Recommended loop scope

Ship **Phase 0 + Phase 1** first as an experimental AA preview on the Brush/Dot + Line
(the visible core), gated by the flag, with AA-off byte-equality proven. **Human-review the
AA-on brush/line output**, then arm the next loop for Phase 2 (all tools), then 3–6. The
`.claude/TASKS.md` for the first loop covers Phase 0 + Phase 1 only for this reason.
