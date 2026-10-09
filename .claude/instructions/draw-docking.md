# Docking: the panel tree (GUI/DOCK)

Photoshop/GIMP-style panel arrangement: dock, stack, tab, collapse, float, dock
back. Plan and decisions: `PLANS/_/DOCKING-PLAN.md`. Built on branch `docking`
(2026-10), on top of the flexible widths in `GUI/DOCK-RESIZE` (#156).

**Fixed rules:** only the LEFT and RIGHT edges dock - except the Browser, which can also dock in a band along the top or bottom of the canvas area (below). The menu bar (and text bar)
is always on top; the status bar and color strip are always at the bottom.

## Files

| File | Role |
| --- | --- |
| `GUI/DOCK.BI` | Types + state: `DPANEL()` registry, `DOCK_COL()`, `DOCK_SLOT()`, `DOCK_TAB(slot, tab)`, `DOCK_UI` (hover/menu/divider/move/target), constants |
| `GUI/DOCK-TREE.BM` | **Pure** tree code, unit-tested by `QA/unit/dock-unit.bas`: registry, editing, `[DOCK]` grammar, snapshots, moves. No SCRN/CFG/THEME here, so the unit test compiles it alone |
| `GUI/DOCK.BM` | Everything that touches the app: layout, per-panel adapters, handles, menu, dividers, move/drop, float host, native windows, legacy-key bridge |
| `GUI/DOCK-RESIZE.BM` | Inner-edge width drag; `DOCK_handle_mouse%` calls chrome → divider → move → edges, in that order |

## Model

- **Panel** (`DP_*`, 13): TOOLBOX, ORGANIZER, DRAWER, LAYERS, EDITBAR, ADVBAR, CHARMAP (docked panels) and PREVIEW, MIXER, ADVCP, CS3D, PEN, BROWSER (native floating windows). `DPANEL(id)`: name, title, `hmode` (`DP_H_FIXED` own height / `DP_H_FLEX` shares), `tall` (makes its column full height), `bordered`, `floats` (has its own window), `slot` (0 = not docked), float rect, dock-back memory (`hside/hcol/hslot/halone`), and this frame's rect (`rVis, rx..rh`).
- **Column** `DOCK_COL`: `side`, `ord` (1 = outermost), `wpx` (0 = the panels' own width).
- **Slot** `DOCK_SLOT`: `col`, `ord` (1 = top), `share`, `collapsed`, `ntabs`, `act`. `autoc` = collapsed by the layout this frame (not saved).
- **Default tree:** while `DOCK_CUSTOM = FALSE`, `DOCK_build_default` rebuilds the tree **every layout** from the old side keys (`TOOLBOX_DOCK_EDGE`, `LAYERS_PANEL_DOCK_EDGE`, edit/adv bar and charmap `dockSide`). Any user arrangement sets `DOCK_CUSTOM` (`DOCK_change_begin`) — otherwise a live drag is undone the next frame.

## Layout (`DOCK_layout`, called from `SCREEN_compute_layout`)

1. Columns holding a `tall` panel are FULL height and are placed first; full height **spreads outward** (any column outside a full one is full too). The menu bar spans what is left (`DOCK_MENU_LX/RX`).
2. Each column stacks its slots: fixed panels take their own height, bordered neighbours share a frame row, flex panels split the rest by `share` (drawer has a minimum). Titled slots (tabs, collapsed, docked native window) get an 11px strip (`DOCK_TITLE_H`).
3. **Small windows:** a column too short collapses slots from the bottom (`autoc`); `DOCK_hide_for_width` hides outermost columns (toolbox's last) so the canvas keeps ≥ 160px.
4. `DOCK_apply_rect` hands each visible panel its rect (the fields its own code reads). `DOCK_live%(id)` gates every panel's render and hit tests.
5. Canvas edges `DOCK_LX/RX` → `SCRN.uiLeftEdge/uiRightEdge`, `panelShiftX`.

## The panel contract

A dockable panel renders inside the rect it is given and hit-tests inside it.
To add one: a `DP_` id + `DOCK_panel_def` in `DOCK_init_panels`; cases in
`DOCK_panel_shown%`, `DOCK_panel_w%`, `DOCK_fixed_h%` (fixed ones),
`DOCK_apply_rect`; gate its render with `DOCK_live%`. Native windows also need
the adapter below.

## Native floating windows (Preview, Mixer, ACP, 3D, Pen, Browser)

They keep their own look and code; a `docked` field switches them over:
- `docked` = **in the tree** (`DOCK_native_reset_docked` sets it from `DPANEL().slot` each layout), not "has a rect". `DOCK_native_off%(id)` is TRUE for a docked window whose slot shows nothing this frame (collapsed, inactive tab, hidden column); its render calls (`SCREEN.BM`, 3 places) and `*_hit_window%` check it. Without this a window in a hidden tab fell back to floating at its old spot.
- While docked: the work-area clamp exits early, resize/maximize are off, the slot sets position (fixed ones are centered, Preview/Browser are sized to the slot).
- `DOCK_native_grab%` = the title bar minus its buttons; docked, that is the slot's handle (`DOCK_native_for_region%` lets the region filter accept it).
- Floating, the window's own title drag calls `DOCK_native_drag` (targets + preview) and `DOCK_native_drag_end%` on release (docks if over a target).
- `DOCK_native_undock` restores the floating size and saves the position to its CFG keys. The Browser keeps its floating size in `CFG.BROWSER_WIDTH/HEIGHT` — every write of those is guarded with `docked = 0` so the slot size never overwrites it.

## Float host (docked panels floating)

`DOCK_place_floats` hands the panel `(fx+1, fy+th, fw-2, fh-th-1)`, `th = DOCK_float_title_h%`: a 6px grip strip (`DOCK_FLOAT_GRIP_H`) for the edit / advanced bars and anything under 64px wide (a title wouldn't fit), else the 11px title bar. A floated bar opens at its own column width and `contentH` tall (`DOCK_float_content_h%`); `DOCK_float_clamp` keeps it in the work area. The bars draw only **whole** icons (a partial one spilled past the rect).

## Interaction

| Gesture | Code |
| --- | --- |
| Hover a slot's handle (title strip, layers header, or a 3px grip drawn after `SkipToPointer:`) | `DOCK_handle_at%`, `DOCK_overlay_render` |
| Right-click a handle: Move to Left/Right Edge, Collapse/Expand, Float/Dock Back, Reset Arrangement | `DOCK_menu_build`, `DOCK_menu_do` |
| Drag the divider between two flex slots | `DOCK_handle_divider%` |
| Drag a handle (5px threshold) → drop on an edge / between columns (new column), a slot's top/bottom third (split), middle (tab), elsewhere (float) | `DOCK_handle_move%`, `DOCK_drop_target`, `DOCK_drop_apply`, `DOCK_move_render` |
| Click a tab / chevron, double-click a title | `DOCK_title_click`, `DOCK_toggle_collapse` |
| Double-click a floating title / Dock Back | `DOCK_dock_back` (`halone` → its own column again) |
| Drag a floating panel's right / bottom edge or corner | `DOCK_handle_float_resize%` (`DOCK_RZ`, `DOCK_float_edge_at%` — region-guarded like the handles; cursor via `DOCK_float_cursor_edge%` in `POINTER_build`) |

Every tree change: `DOCK_change_begin` … `DOCK_change_commit msg` (saves to the
active workspace via `WSC_save_dock`, else `CONFIG_save`).

## The old side keys (legacy bridge)

View → Layout Dock Left/Right (443–452, 2051/2052), Ctrl+Shift+click a panel,
Hide Left/Right Side UI (436/437) and the Layout checkmarks predate the tree.
- **Read** sides with `DOCK_side_now%(id)` (tree side if docked, else the key) — never the keys directly.
- **Stock Default** (`CFG.STOCK_DEFAULT_LAYOUT`, on by default; `QA/DRAW.qa.cfg` turns it off for the older dock tests): Default never stores an arrangement. `DOCK_*` keys from the cfg file are dropped after load (`--option DOCK_*` still applies), `CONFIG_save_dock` writes none. In Default, `DOCK_change_commit`, `DOCK_save_value` (edge resizes) and side swaps (`DOCK_side_request` undoes the caller's key flip via `DOCK_key_set` and moves in the tree) go to `WS_layout_change_in_default`: a name prompt → `WSC_from_default_begin%` (captures what is on screen) → `WS_default_layout_reset` (live layout back to stock, so the new workspace's restore point is stock) → `WSC_save_and_use`. Tab switches / collapse use `DOCK_change_commit_soft` (session-only in stock Default). Test: `workspace-stock-default`.
- **Toolbox columns** (`TOOLBAR_reflow`): the wanted columns, plus more while the buttons don't fit the height. The organizer's height / a usable drawer and their minimum widths count **only while they are stacked in the toolbox's column** (`DOCK_with_toolbox%`); docked elsewhere or floating they take none of it (they used to force a lone 1-column toolbox to 3). An organizer / drawer docked apart is at least one widget stack / one bin wide (`DOCK_panel_w%`). Tests: `dock-toolbox-narrow`, `dock-toolbox-stacked-fit`.
- **After setting** a key, call `DOCK_side_request id, side`: a custom tree moves the panel (its whole column when the column holds nothing else; the toolbox counts its organizer + drawer), the default tree follows the keys by itself.
- Do **not** mirror the tree into the keys: the workspace overlay only snapshots keys a workspace touches, so a mirror would leak into the user's DRAW.cfg.

## The Browser's band (top / bottom)

`DOCK_BAND_SIDE` (0 / `DOCK_BAND_TOP` / `DOCK_BAND_BOTTOM`) + `DOCK_BAND_H`; saved as `BAND=TOP|BOTTOM,<h>` in the snapshot (`DOCK_BAND` in DRAW.cfg, `BAND` in `[DOCK]`). The Browser is then not in the tree and not floating; `BROWSER.docked` covers both. `DOCK_place_band` (in `DOCK_layout`, after the columns) lays it across `DOCK_LX..DOCK_RX` under the menu + text bar (`DOCK_TOPBAR_H`) or above `dockY2`, and sets `DOCK_SHIFT_Y` -> **`SCRN.panelShiftY%`**, added to every vertical canvas-position expression (the twin of `panelShiftX%`; 38 sites, `(SCRN.h& - zh&) \ 2 + SCRN.offsetY% + SCRN.panelShiftY%`). The room stays reserved while a stroke auto-hides the Browser. Drop targets `DOCK_TGT_BAND` (Browser only, within `DOCK_EDGE_ZONE` of the canvas area's top / bottom), its title bar is the handle (`DOCK_band_title_at%`), its inner edge resizes it (`DOCK_handle_band_resize%`, vertical cursor), menu actions 7 / 8. Any move of the Browser elsewhere clears the band.

## Persistence

Snapshot text (`DOCK_snapshot$` / `DOCK_load_snapshot`): `CUSTOM=0|1`, `LEFT.n=`, `RIGHT.n=`, `FLOAT.name=x,y,w,h`.

- **DRAW.cfg:** `DOCK_CUSTOM`, `DOCK_LEFT_n`, `DOCK_RIGHT_n`, `DOCK_FLOAT_name` (`CFG_DOCK_SPEC`, `CONFIG_save_dock`). Loaded in `DRAW.BAS` before `WS_startup`.
- **Workspace:** `[DOCK]` / `[FLOAT]` sections (`WS_apply_dock`). Leaving restores `WS_DOCK_USER_SNAP` when `WS_DOCK_TOUCHED`. A workspace with `*_DOCK` keys but no `[DOCK]` gets the default tree so its sides apply.
- **Saving a layout:** `WSC_capture_layout` (Save Current Layout As / Update) writes the tree; the configurator's **Dock** tab shows `[DOCK]`/`[FLOAT]` lines with *Use current* / *Default*.

Grammar, one line per column, outermost first:

```ini
[DOCK]
LEFT.1=AUTO; toolbox | organizer | drawer
RIGHT.1=WIDTH:180; layers@2 | *preview+colormixer | !browser
[FLOAT]
pen=640,120,220,300
```
`AUTO` or `WIDTH:px`; slots `|`; tabs `+`; `*` active tab; `@n` share; `!` collapsed. Toolbox and bar **column counts** stay in their own keys (`TOOLBOX_COLUMNS`, …), not in `[DOCK]`.

## Testing

**Live layout dump:** `--option DOCK_DUMP=<path>` (QA-OPTIONS `DOCK_DUMP=QA/.dock-dump.txt`) makes `DOCK_layout` write `SEQ / TREE / BAND / SCR / COL / SLOT / P` lines (every rect, handle rect, tab rect, auto-collapse) whenever they change (`DOCK_dump_write`). `QA/dock-lib.sh` reads it: `dk_move NAME TARGET` (edge-left/right, newcol, above, below, tab, bottom, float, band-top/bottom), `dk_move_expect`, `dk_check` invariants (each panel once, docked <=> in the tree, on screen, no overlaps, saved == on screen, floats + band saved), `dk_fuzz SEED STEPS PANELS...` (seeded random chains). Tests: `dock-separate*`, `dock-combine-<panel>` x6, `dock-after-combine`, `dock-fuzz-*`, `dock-windows*`, `dock-persist`, `dock-browser-band`, `dock-float-bar`, `dock-startup`, `dock-small`, `dock-tabs`, `dock-arrange`.

### Bugs these tests found (all fixed)
- A stacked chromeless panel's 3px grip sat on the divider above it - the divider won, so the panel could never be moved (`DOCK_slot_grip%`).
- A narrow bar docked on a screen edge could not be stacked onto / tabbed with: the 16px screen-edge zone covered it (now 4px where a column lines the edge).
- Dragging a tab strip moved only the active tab (now the whole slot: `DOCK_UI.mvGroup`).
- Tab strips ran past narrow columns (and off-screen): `DOCK_tab_rect%` fits them, labels are cut (`DOCK_fit_text$`).
- A slot inserted into a column after a divider drag got share 1 next to px shares (a sliver): it takes the column's average.


- `DEV/tools/dock-baseline.sh shoot DIR` / `compare BASE NEW`: 12 pixel shots via the QA harness with fixtures in `QA/fixtures/workspaces/` (scratch `XDG_DATA_HOME`). Refactors must stay AE = 0 against a main-branch baseline.
- `QA/unit/dock-unit.bas` (tree), `QA/unit/ws-unit.bas` (workspace files).
- QA files: `dock-resize`, `zorder-hit-targets`, `workspace-*`, `ui-preview`, `drag-drop-targets`.

## Gotchas found building it

- `EDITBAR_COLS` collided with `EDITBAR_cols%` (names are case-insensitive) → `EDITBAR_NCOLS`. `base`, `any`, `ns` are rejected as identifiers.
- Title strips must use the layer panel's header font/colors; `THEME.MENU_BAR_FG` is unset (0).
- A floating native window draws onto the display **after** the canvas is scaled, so any overlay on `SCRN.CANVAS&` is under it: the drop label for a window drag sits above the window's title bar.
- [Linux] the QA harness at 958×514 @2x: press a floating window's title a few px below its top edge — the top 3–4px is its resize edge.
