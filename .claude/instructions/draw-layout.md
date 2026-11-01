# Layout: `QB64_GJ_LIB/LAYOUT` and how DRAW wraps it

Plan and history: `PLANS/_/LAYOUT-LIBRARY-PLAN.md`. Built 2026-10-09 on the `layout-lib` branch.

## Why

Most of the layout bugs fixed on 2026-10-08/09 broke the same way: a size rule lived in one place, and a second place that should have used it didn't. Examples:
- the Preview's minimum height vs the dock's minimum slot
- a stretching window holding its column wide
- the hard-coded 60px layer minimum
- floating windows left over the docks

Now every docked panel *declares* its sizes once, and one solver turns the declarations into rectangles.

## The library (`includes/QB64_GJ_LIB/LAYOUT/`, prefix `LAY_`)

It's pure integer math: no DRAW globals, no drawing. `LAYOUT-TEST.BAS` is a headless unit test (33 checks); exit 0 means everything passed.

| Piece | What it does |
| --- | --- |
| **line** `LAY_line_new&(avail, gap)` | A row or column solved against one length |
| **item** `LAY_add&(l, min, basis, max, grow, shrink)` / `LAY_add_fixed&` | One box. `max` 0 = none |
| `LAY_lead i, px` | px before it; `-1` = shares the previous box's frame row. Ignored while the item is dropped (a collapsed box has no frame) |
| `LAY_drop i, rank, size` | When even the minimums don't fit, the highest rank collapses to `size` first |
| `LAY_set_dropped i, size, on` | Drop by hand, for a policy that depends on each outcome |
| `LAY_solve l` | Drops, then sizes, then positions → `LAY_ITEMS(i).at / .size / .dropped`, `LAY_overflow&(l)` |
| `LAY_min_total&` / `LAY_basis_total&` | What a line needs (its container's minimum) |
| `LAY_clamp x, y, w, h, area…` | Keeps a rect inside an area; too big pins its top-left |
| `LAY_obst_*` + `LAY_place …` | A floating rect: snap, nearest free spot among obstacles, inside-area fallback |

**Sizes** follow CSS flexbox's "resolve flexible lengths":
1. Leftover space goes to the items by `grow`; a deficit is taken back by `shrink × basis`.
2. Items are clamped to their min/max. Clamped items freeze and the rest share again.
3. The last grower or shrinker takes the rounding remainder.

The **basis is not raised to the minimum**. An item with min 24 and basis 0 grows from 0 and freezes at 24 only if its share falls short.

`LAY_MODE_LEGACY_MIN` (minimums only decide drops; no freezing) existed only for the pixel-parity port. DRAW no longer uses it.

**QB64-PE has no function pointers**, so a tree is solved one level at a time, outer level first. A box whose height depends on its width (the organizer) is measured between levels.

**Pools are global**: `LAY_reset` starts a pass. Read a line's results before the next `LAY_reset`. The dock calls it once per row solve and once per column.

## DRAW's side

| Where | What |
| --- | --- |
| `DOCK_panel_box(id, axisH, cross, min, basis, stretchy)` | **The one place a docked panel's size rules live.** Width: min/basis, and `stretchy` for windows that fill their slot (Preview, Browser: beside other panels only their minimum counts). Height: a fixed height, or a flex minimum (`max(DOCK_min_h%, DOCK_MIN_FLEX_H)`). Its helpers `DOCK_panel_w%` / `DOCK_fixed_h%` / `DOCK_min_h%` are still used by float hosts and drop targets |
| `DOCK_col_width%(c)` | A column's width from its panels' boxes, or its `WIDTH:` override |
| `DOCK_row_solve` | The screen row as one line: left columns, canvas (min `DOCK_MIN_CANVAS_W`, grow), right columns. Overflow hides columns by hand (`DOCK_hide_outermost%`: wider side, toolbox last). Sets column x and `DOCK_LX/RX`. If it still overflows, right columns stay pinned to the right edge |
| `DOCK_stack_column(c)` | One flex line per column. Fixed slots are fixed items, flex slots grow by `share` with their minimum, bordered neighbours get `lead -1`, auto-collapse is the drop order (rank = slot order, never the first; drop size = `DOCK_TITLE_H`) |
| `FPANEL_place` / `FPANEL_free%` | `LAY_place` / `LAY_free%` over `FPANEL_obstacles` (the other shown floating windows, in candidate order) |
| `*_clamp_to_work_area`, `TBED_clamp` | Each keeps its own work area and ends in `LAY_clamp` |

**Adding a docked panel's size rules:** add a case to `DOCK_panel_box`, and to its helpers if needed. Never compute a panel's size in the layout code itself.

## Testing a layout change

- **Pixel parity:** `DEV/tools/dock-baseline.sh shoot DIR` then `compare BASE DIR`. It shoots 12 stock layouts, and 0 differing means identical pixels.
- **A/B build** (how P1/P2 were proven identical): temporarily keep the old routine beside the new one under another name, run both on every layout, and log any mismatch to a file. Then run the stack-heavy dock tests (`dock-small`, `dock-fuzz-*`, `dock-tabs`, `dock-arrange`, …) and grep the log. Remove the scaffold before committing.
- **Targeted set:** `QA/tests/dock-*`, `popups-over-*`, `windows-input-guards` (and `tbed-*`, `preview-*` for floating windows). No full suite for a parity-proven refactor (memory: feedback-test-scope).
- **Bug fixtures:** each layout bug becomes a fixture in `LAYOUT-TEST.BAS` and, where it needs DRAW, a dock test (`dock-column-min-share`, `dock-layers-shrink-preview`, `dock-float-workarea`).
