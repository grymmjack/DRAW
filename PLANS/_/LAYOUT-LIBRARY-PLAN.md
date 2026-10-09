# Layout library plan: one flexbox-style size solver that DRAW wraps

Status: **proposed** (2026-10-09). Nothing is built yet. The decisions Rick still has to make are at the end.

## Why

Rick, 2026-10-09: *"at this point given our geometry and modular configuration in DRAW should we have a underlying flexbox - like model that is in a library that DRAW just wraps?"*

Nearly every layout bug fixed on 2026-10-08/09 broke the same way. A size rule (minimum, preferred, stretch) lived in one place, and a second place that should have used it didn't:

| Bug | Rule that drifted | Where it lived |
| --- | --- | --- |
| Docked Preview drawn over the layers | Preview's minimum height vs the dock's 24px minimum slot | `PREVIEW_MIN_H` vs `DOCK_MIN_FLEX_H` / `DOCK_min_h%` |
| Layers can't be narrowed with the Preview docked above them | A stretching window reported its stretched width as the width it wants | `DOCK_panel_w%` (fixed twice: `DOCK_stretch_min_w%`) |
| Layer panel buttons overlap | Minimum width hard-coded at 60px, unrelated to the 6 buttons | `LAYERS_clamp_width%` vs the button bar render |
| Customize Toolbars covers docked panels | Window size not fitted to the work area | `TBED_fit_dims` |
| Floating window left over the docks | Work area changed, windows not re-placed | `FPANEL_settle` |
| Too-tall picker placed at y −94 | Candidate positions not clamped | `FPANEL_place` |
| Lone toolbox forced to 3 columns | Organizer/drawer minimums counted outside their column | `TOOLBAR_reflow` |

In a flex model, every box *declares* its minimum, preferred and maximum size and how it grows or shrinks, and **one** solver turns those declarations into rectangles. A missing minimum is then one declaration, not a bug that waits for a particular arrangement to show up.

## What exists (survey 2026-10-09)

**Docking** (`GUI/DOCK.BM`, 2,419 lines; `GUI/DOCK-TREE.BM`, 623, pure and unit-tested by `QA/unit/dock-unit.bas`; `GUI/DOCK-RESIZE.BM`, 239):

- **Screen row** — `DOCK_layout`:
  - Column width is the widest shown panel (`DOCK_panel_w%`), or the column's `WIDTH:` override (`wpx`).
  - A stretching window counts only its minimum when it isn't alone in the column (`DOCK_stretch_min_w%`).
  - `DOCK_hide_for_width` hides the outermost column of the wider side until the canvas has `DOCK_MIN_CANVAS_W`, toolbox column last.
  - "Full height spreads outward."
  - `DOCK_place_columns` assigns x from the outside in.
- **Column** — `DOCK_stack_column` + `DOCK_column_need%`:
  - Fixed panels take `DOCK_fixed_h%(id, w)`; for the organizer that height depends on the column width.
  - Flex panels share the rest by `share`, and the last flex slot takes the rounding.
  - Each flex panel is then bumped to its `DOCK_min_h%` *after* the share is handed out, which is where overflow comes from.
  - Two bordered panels share a frame row (−1px).
  - Titled slots add `DOCK_TITLE_H`.
  - When the column is too short, slots auto-collapse from the bottom (never the first).
  - The two routines each repeat the same per-slot rules.
- **Browser band** — `DOCK_place_band`: a top or bottom band across the canvas area, with its own min/max.

**Floating windows** (`GUI/FLOAT-PANEL.BM`):
- `FPANEL_place` does snapping plus a nearest-free-spot candidate search.
- `FPANEL_settle` re-places windows on the first frame and whenever the work area changes.
- Each window also has its own clamp: `PREVIEW_`, `COLORMIXER_`, `ADVCP_`, `CS3D_`, `PENP_` and `BROWSER_clamp_to_work_area`, plus `TBED_clamp`. That's six near-copies.

**Panel insides** (each its own arithmetic):
- the layer panel's button bar (`(w − 18) \ 6`, and `LAYERS_min_width%` repeating it)
- `TOOLBAR_reflow` / `TOOLBAR_fit_width`
- `ORGANIZER_layout%` / `ORGANIZER_height_for%`
- `DRAWER_layout` / `DRAWER_min_w%`
- `TBED_layout` / `TBED_fit_dims`
- `PENP_layout`
- `MENUBAR_layout_in_bounds%`
- `SCREEN_fit_min_w/h`
- `*_compute_display_size` for each window

**QB64-PE constraint:** there are no function pointers, so a solver can't call a panel back to measure it. The design below avoids needing that.

## Design

### The library: `QB64_GJ_LIB/LAYOUT` (prefix `LAY_`)

Pure integer math. It touches no DRAW globals, does no drawing and does no I/O, so it compiles and tests headless (like `DOCK-TREE.BM` and `dock-unit`). The files are `LAYOUT.BI`, `LAYOUT.BM`, `LAYOUT-TEST.BAS` and `README.md`, matching `VECT2D/`, `COLOR/` and the other modules.

**One primitive: a line.** A line is a row or column of items along one axis, solved against an available length. A tree is solved one level at a time by the caller, outer level first, so the cross size is known before the inner level is measured. That's how the organizer gets its height from the column's width without a callback: the wrapper solves the screen row, reads each column's width, measures the organizer at that width, then solves the column.

```basic
TYPE LAY_ITEM
    minSize    AS LONG    ' never smaller (px)
    basis      AS LONG    ' preferred size before grow / shrink
    maxSize    AS LONG    ' never larger (0 = no limit)
    grow       AS SINGLE  ' share of leftover space (0 = keeps basis)
    shrink     AS SINGLE  ' share of the deficit (0 = never below basis)
    lead       AS LONG    ' px before this item: + gap, -1 = shares a frame row with the previous
    dropRank   AS INTEGER ' overflow: highest rank collapses first (0 = never)
    dropSize   AS LONG    ' its size once dropped (a title strip, or 0 = hidden)
    ' --- out ---
    pos        AS LONG    ' offset from the line start
    size       AS LONG
    dropped    AS INTEGER
END TYPE

' build
l& = LAY_line_new&(available&, gap&)
i& = LAY_add&(l&, minSize&, basis&, maxSize&, grow!, shrink!)
LAY_lead i&, -1                    ' optional per-item extras
LAY_drop i&, rank%, dropSize&
' solve + read
LAY_solve l&
LAY_ITEMS(i&).pos / .size / .dropped
LAY_overflow&(l&)                  ' px still over after every drop (0 = fits)
LAY_min_total&(l&)                 ' the line's own minimum: what its container must give it
LAY_free l&                        ' or LAY_reset each frame (pool arrays, no handles to leak)
```

**The solver** is CSS flexbox's "resolve flexible lengths", in integers:

1. Total the bases plus leads.
2. If that's under the available length, share the leftover by `grow`. If it's over, share the deficit by `shrink × basis`.
3. Clamp each item to its min/max. If any were clamped, freeze them and redistribute among the rest. Repeat until nothing changes.

   This freeze loop is what today's code lacks. `DOCK_stack_column` hands out the share first and bumps each flex panel to its minimum afterwards, so the column overflows. That's how the Preview ended up drawn over the layers.
4. Still over at every minimum: drop the item with the highest `dropRank` to its `dropSize`, then repeat from step 1.

   This one rule covers both today's "auto-collapse slots from the bottom" (`dropSize` = the title strip) and "hide the outermost column" (`dropSize` = 0, toolbox column ranked last).
5. Round to whole pixels. The last growing item takes the remainder, which is today's rule, kept for pixel parity.

**One 2D helper** for floating windows: `LAY_place(rect, obstacles(), area, snap)` runs today's `FPANEL_place` algorithm:
- snap to the edges of the area and of other windows
- take the nearest spot clear of every other window inside the area
- if there's none, take the nearest spot inside the area
- a window too big for an axis keeps its top-left edge inside the area

It returns the spot, and each window's own clamp becomes a call to it.

### DRAW's side: one panel contract, one wrapper

**`DOCK_panel_box(id, crossSize, box)`** fills in a panel's min/basis/max for the axis being solved. It replaces `DOCK_panel_w%`, `DOCK_min_h%`, `DOCK_fixed_h%`, `DOCK_stretch_min_w%` and `LAYERS_min_width%` as the *one* place a panel says how big it may be:

| Panel | Width (screen row) | Height (column) |
| --- | --- | --- |
| Layers | min = button bar's `LAY_min_total&` (108), basis = `LAYER_PANEL.width%`, max 400 | flex, grow = share, min = header + one row |
| Toolbox | basis = columns × pitch | fixed = rows × pitch (`TOOLBAR_reflow`) |
| Organizer | its widget stack | fixed, measured at the column's width |
| Preview / Browser (stretch) | min only, plus basis = floating width when alone in the column | flex, min = `PREVIEW_MIN_H` × scale |
| Mixer / Adv picker / 3D / Pen | fixed = own size | fixed = own size |
| Edit / advanced bar | basis = columns × pitch | flex |

**The wrapper**, `DOCK_layout`, keeps its name and its callers:

1. **Screen row:** one line holding the left columns, the canvas (grow 1, min `DOCK_MIN_CANVAS_W`), and the right columns. A column's box is the combination of its panels' boxes: min = the largest min, basis = the largest non-stretch basis (or the stretch basis when the column holds only stretch panels), max = the smallest max. `wpx` pins all three. Drop ranks reproduce `DOCK_hide_for_width`.
2. **Each column:** one line of its slots. Fixed slots are min = basis = max. Flex slots are grow = share, min = panel min + title. Bordered neighbours get `lead −1`. Drop ranks run bottom-up from slot 2.
3. Hand each rect to `DOCK_apply_panel` exactly as today. Panels never see the library.

The tree (`DOCK-TREE.BM`), the `[DOCK]` grammar, workspaces, handles, dividers, the dump format and every panel's render code are unchanged.

## Phases

Each phase ships on its own and has its own exit check. **P1 and P2 are refactors: the dock baseline must show 0 differing shots.**

| Phase | Work | Exit check |
| --- | --- | --- |
| **P0 Library** | `QB64_GJ_LIB/LAYOUT` + `LAYOUT-TEST.BAS` (headless). Test cases are the real situations: tonight's bugs as fixtures, rounding remainder, freeze loop with min and max, drop order, frame-row overlap, `LAY_place` corners (too big, no free spot, snap). | Unit test passes; DRAW unchanged |
| **P1 Columns** | `DOCK_stack_column` + `DOCK_column_need%` → one `LAY_` line per column. The overflow-by-minimum path becomes the freeze loop. | Baseline 0 differing; `dock-unit`; `QA/tests/dock-*` (40 files) |
| **P2 Screen row** | Column widths + `DOCK_hide_for_width` + the stretch rule → one `LAY_` line. `DOCK_panel_box` replaces the five size functions. | Same, plus `dock-layers-shrink-preview`, `dock-resize`, `dock-toolbox-*` |
| **P3 Floating windows** | `FPANEL_place` → `LAY_place`. The six `*_clamp_to_work_area` + `TBED_clamp` become one call each. | `dock-float-workarea`, `dock-native-*`, `popups-over-*`, `windows-input-guards` |
| **P4 Panel insides, as touched** | Layer button bar first (its minimum then comes from the same line that lays it out, which retires `LAYERS_min_width%`). Then `TBED_layout`/`TBED_fit_dims`, the organizer, the bar columns, and Settings rows, each when it's next changed for another reason. | That panel's tests |

P0–P2 are the core: one library, the dock on top of it. P3 is a short follow-on. P4 is opt-in and never a sweep.

**After P2** the five per-panel size functions and the duplicated per-slot rules are gone. Adding a panel means filling in one `DOCK_panel_box` case.

## Testing

- **Library:** `LAYOUT-TEST.BAS`, exit code 0 = pass, like `QA/unit/dock-unit.bas`. Every bug in the table above becomes a fixture, for example "flex item with min 152 in a 140px line: overflow reported, neighbours keep their minimums".
- **DRAW:** the existing `DEV/tools/dock-baseline.sh` (pixel parity), `QA/unit/dock-unit.bas` (tree), and the `QA/tests/dock-*` suite. `dk_check` already asserts the invariants a solver must keep: no overlap, on screen, windows inside their slot, title bars reachable, saved arrangement = live.
- **Full suite once:** at the end of P2, since every test's geometry goes through the new code.

## Risks

- **Pixel parity.** Rounding, the shared frame row, titles and auto-collapse must reproduce today exactly for P1/P2, which is why the baseline gates them. Intentional behaviour changes (the freeze loop fixing overflow) land as separate, visible commits after parity is reached.
- **No callbacks in QB64-PE.** That's handled by level-by-level solving: the wrapper measures between levels. If a box ever needs its size to depend on its *own* solved size, it needs a second pass, which is a known flexbox limit and doesn't occur in DRAW today.
- **Scope creep.** P4 is explicitly "as touched". The win is in P0–P2.
- **Performance.** It's a handful of items per frame (≈6 columns × ≤6 slots). The freeze loop is bounded by the item count. Negligible next to rendering.

## Decisions for Rick

| Question | Recommendation |
| --- | --- |
| Where the solver lives | **`QB64_GJ_LIB/LAYOUT`.** Reusable like `COLOR_PICKER` and `FILE_DIALOG`, and the purity is enforced by it compiling without DRAW. |
| P1/P2 behaviour | **Pixel parity first**, then any intended changes as their own commits. |
| Overflow policy | **Keep today's**: slots collapse to their strips from the bottom (never the first); columns hide outermost-first on the wider side, toolbox last. |
| Branch | **New branch `layout-lib` from main after PR #158 merges**, so the toolbar-editor PR stays reviewable. |
| P4 scope | **As touched, layer button bar first.** No sweep. |
