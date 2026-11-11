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

Sizes are solved by `QB64_GJ_LIB/LAYOUT` (flexbox-style lines; see `draw-layout.md`): every panel states its sizes in **one** place, `DOCK_panel_box`, and the dock turns them into lines.

1. **The screen row** (`DOCK_row_solve`) is one line: left columns (outermost first), the canvas (at least `DOCK_MIN_CANVAS_W` = 160, takes the rest), right columns. A column's width is `DOCK_col_width%`: the widest of its panels' boxes, or its `WIDTH:` override. **Small windows:** while the line overflows, the outermost column of the wider side is dropped (`autoh`, toolbox column last) by hand and the line solved again. Columns holding a `tall` panel are FULL height; full height **spreads outward** (any column outside a full one is full too). The menu bar spans between the full-height columns (`DOCK_MENU_LX/RX`).
2. **Each column** (`DOCK_stack_column`) is one line in flex mode: fixed panels take their own height, bordered neighbours share a frame row (`lead -1`), flex panels split the rest by `share` and **never go below their minimum: the others give way** (before 2026-10-09 a too-small share was bumped afterwards and the column ran past the dock; test `dock-column-min-share`). Titled slots (tabs, collapsed, docked native window) get an 11px strip (`DOCK_TITLE_H`). Too short even at the minimums: slots collapse to their strips from the bottom, never the first (`autoc`, the line's drop order).
4. `DOCK_apply_rect` hands each visible panel its rect (the fields its own code reads). `DOCK_live%(id)` gates every panel's render and hit tests.
5. Canvas edges `DOCK_LX/RX` → `SCRN.uiLeftEdge/uiRightEdge`, `panelShiftX`.

## The panel contract

A dockable panel renders inside the rect it is given and hit-tests inside it.
To add one: a `DP_` id + `DOCK_panel_def` in `DOCK_init_panels`; cases in
`DOCK_panel_shown%`, `DOCK_panel_box` (its size rules for the layout, both
axes - `DOCK_panel_w%` / `DOCK_fixed_h%` / `DOCK_min_h%` are its helpers),
`DOCK_apply_rect`; gate its render with `DOCK_live%`. Native windows also need
the adapter below.

## Native floating windows (Preview, Mixer, ACP, 3D, Pen, Browser)

They keep their own look and code; a `docked` field switches them over:
- `docked` = **in the tree** (`DOCK_native_reset_docked` sets it from `DPANEL().slot` each layout), not "has a rect". `DOCK_native_off%(id)` is TRUE for a docked window whose slot shows nothing this frame (collapsed, inactive tab, hidden column); its render calls (`SCREEN.BM`, 3 places) and `*_hit_window%` check it. Without this a window in a hidden tab fell back to floating at its old spot.
- While docked: the work-area clamp exits early, resize/maximize are off, the slot sets position (Preview/Browser are sized to the slot).
- **Docked fill (2026-11-10, Rick's `PLANS/FLEXPANELS.svg`):** the five floating-family panels (Animation, Pen, 3D, Mixer, Advanced Color Picker) lay themselves out to their slot instead of sitting centered with gaps. `DOCK_apply_rect` calls `FPANEL_fit dp, w, h` (GUI/FLOAT-PANEL.BM) -> each panel's `*_fit nw, nh` (native px, 0 = natural; relayouts only on a change): rows, sliders, chip rows, the hex input and the shade rows stretch to the width; spare height goes to the big area - Mixer SV field and 3D view up to 1.5x as tall as wide, Pen response graph to square, ACP wheel to the full width then its shade patches (`ADVCP_PATCH_GROW` = 3x). Animation only stretches. Floating (`DOCK_native_reset_docked`, `DOCK_native_undock`) = `FPANEL_fit dp, 0, 0`. The dock sizes columns and fixed heights from the **natural** size (`FPANEL_nat_w%` / `FPANEL_nat_h%`, from each layout's `natW/natH`), never the fitted one, or a docked panel would hold its column at its widest; `DOCK_panel_max_w%` lets a column's width edge widen them to 2x. Spare height: `DOCK_stack_column` adds a fixed panel with `FPANEL_grow_max%` > 0 as a growable item **only when the column has no flex panel** (layers, Preview, Browser, bars keep the spare height). The library widgets grew a size API for it: `C3D_resize w, viewH`, `CP_STATE.fitW/fitH` (+ `natW/natH`) read by `CP_layout_calculate` (rows in `CP_layout_rows%`), `ACP_resize w, wheel, patchH` (`ACP_STATE.wheel` / `patchH`; the wheel is centred across `w`). `FPANEL_panel_w%` reads `COLORMIXER.natW`, not the fitted `dialogW`. Dump: `FIT name natW natH`. Tests: `dock-fill-<panel>.sh` (`QA/dock-fill-lib.sh`).
- `DOCK_native_grab%` = the title bar minus its buttons; docked, that is the slot's handle (`DOCK_native_for_region%` lets the region filter accept it).
- Floating, the window's own title drag calls `DOCK_native_drag` (targets + preview) and `DOCK_native_drag_end%` on release (docks if over a target).
- `DOCK_native_undock` restores the floating size and saves the position to its CFG keys. The Browser keeps its floating size in `CFG.BROWSER_WIDTH/HEIGHT` — every write of those is guarded with `docked = 0` so the slot size never overwrites it.
- **A window that stretches to its slot (Preview, Browser) never holds its column wide** (`DOCK_panel_box` marks it stretchy; `DOCK_col_width%` combines). In a column beside other panels it asks only for its minimum width, and the column follows the others. Alone in a column it sets the width from its floating width (`DOCK_panel_w%`: `CFG.PREVIEW_W` × render scale, `CFG.BROWSER_WIDTH`), never its live slot width. A live width feeds back: the column is as wide as its widest panel, the window takes the column's width, and the column never shrinks again. Using the floating width alone also failed, for a floating width of 800. Rick's layers, dragged to 400 with the Preview docked above them, could not be narrowed back. The Mixer, Advanced Color Picker, 3D and Pen keep their own size and center in the slot.
- **A display scale change at run time** (Settings, or the palette's Display Scale Up / Down / Reset = actions 408 / 409 / 416) must leave the same layout as a fresh start at that scale. The floating panels (Animation, Pen, 3D, Mixer, Advanced Color Picker) work out `dispW/dispH/renderScale` in `*_compute_display_size`, once at open, so `SCREEN_compute_layout` calls `FPANEL_rescale_all` first to redo them (2026-11-10: Rick's Animation panel, docked with the layers, ran off the window edge until a restart). Preview, Browser and Customize Toolbars recompute in their render already. A new floating panel goes into `FPANEL_rescale_all`. Tests: `dock-display-scale-live.sh` / `-float.sh` (`QA/display-scale-lib.sh`: live change vs a fresh start at that scale and viewport, the harness's `DISPLAY_SCALE` / `VIEWPORT_W/H` set to match). Those panels draw straight to the window at `USCALE.mixer`, which `SCALE_resolve_widgets` resolves with the ratio doubled (`SCALE_RATIO_MIXER` 0.5 = the master: the menus' pixel size, so every UI Scale step resizes them); plain `ROUND(master * .5)` gave 1x at both UI 1 and 2 (Rick 2026-11-10: "the animation panel isn't actually resizing"). **QA pins `TOOLBAR_SCALE` (an override that bypasses the ratios)**, so scale tests that need a user's real resolution must clear it in QA-OPTIONS (`TOOLBAR_SCALE=0`), as `dock-display-scale-ratios.sh` does - the pinned tests never saw this. **Per-panel scale:** each of the five has `CFG.*_SCALE` (`ANIM_PANEL_SCALE`, `COLOR_MIXER_SCALE`, `PEN_PANEL_SCALE`, `ADV_COLOR_PICKER_SCALE`, `COLOR_SPACE_3D_SCALE`; 0 = Auto); every place that draws or sizes one reads `FPANEL_scale%(DP_*)` (GUI/FLOAT-PANEL.BM), never `USCALE.mixer` directly. Set from the handle menu or Settings → Panels → Panel Scale. The dump's `DMENUR row value y h checked` lines give the open handle menu's rows (test `panel-scale-menu.sh`).
- **The layers' narrowest width** is `LAYERS_min_width%`: the bottom bar's 6 buttons ((w − 18) \ 6 each) must each fit the widest button icon. That is 108px with the default 15px icons; it was a hard-coded 60px, where the icons overlapped. `LAYERS_clamp_width%` applies it to drags and workspace values, and `DOCK_panel_w%` applies it to saved widths below it. Test: `dock-layers-shrink-preview` (120 → 400 → 140 → stops at 108).

## Seams: the one line between columns (2026-11-07)

The dock owns the border between a column and its neighbour. Every visible
column draws **one 1px line on its inner edge** (toward the canvas), the whole
column height: one line between the innermost column and the canvas, one
between each pair of columns, none at the window edge. Colour: the edit bar
border colours (`DOCK_seam_color~&`; a right column's line uses
`EDIT_BAR_LEFT_BORDER_COLOR`, a left column's `..._RIGHT_...`).
- `DOCK_render_seams` (SCRN.GUI&, after the docked panels, before
  `DOCK_render_float_stack`; both GUI render blocks in `SCREEN.BM`). It draws
  over the panel's edge pixel (the toolbox / organizer black frame there).
- **Panels draw no side borders.** The edit / advanced bars (both sides), the
  layers (right) and a column's empty part (`DOCK_fill_rect`) used to - a
  boundary then had two lines beside some neighbours and none beside others
  (Rick: a double line right of the toolbox column with the Drawer floated; no
  line between a right-docked toolbox and the canvas). `lbw/rbw` still pad
  the bars' icons.
- **Docked native windows** draw on screen 0 after the canvas is presented, over
  the GUI layer: `DOCK_render_native_seams` (end of the docked block in
  `SCREEN_render_windows`) draws their column's seam again over their rows, and
  paints out their own side frame where it lies within 2px of a seam (inner edge,
  or outer edge with a column beyond it) - `DOCK_frame_px%` measures the frame's
  width in screen pixels from its edge colour. A window centred away from the
  edges keeps its frame.
- **The Browser's band** (top / bottom): its ends' side frames are painted out
  onto the columns' seams, and its canvas side gets one seam row on the band's
  last (top) / first (bottom) row, its own frame and any gap up to it painted
  out. Docked, `BROWSER_sync_fd_from_display` rounds the dialog size DOWN
  (`INT`, not `+0.5`) so at a fractional render scale it never draws a row past
  its slot (it did: a 221px dialog in a 220px band).
- Test: `dk_seams` in `QA/dock-lib.sh` (also run by every `dk_check`, so all
  dock / fuzz tests check it): per row of every visible column, the inner edge
  is the seam colour, the pixel across it and the one inside are not, and no
  lighter frame line runs beside it (8+ rows); with a band, its seam row
  likewise. `SEAM` line in the dock dump; `DK_SEAM_COLORS="404040 404040"`
  stands in for it to run the check against a build from before it.
  `dock-seams-left`, `dock-seams-right`, `dock-seams-band`.
  The capture can come up a few rows short of the window: `dk_seams` pads it to
  the exact scale before shrinking (stretching it to WxH slid rows by one and
  showed a seam one row off) and skips the rows it does not have.

## Float host (docked panels floating)

`DOCK_place_floats` hands the panel `(fx+1, fy+th, fw-2, fh-th-1)`, `th = DOCK_float_title_h%`: a 6px grip strip (`DOCK_FLOAT_GRIP_H`) for the edit / advanced bars and anything under 64px wide (a title wouldn't fit), else the 11px title bar. A floated bar opens at its own column width and `contentH` tall (`DOCK_float_content_h%`); `DOCK_float_clamp` keeps it in the work area. The bars draw only **whole** icons (a partial one spilled past the rect).

## Interaction

| Gesture | Code |
| --- | --- |
| Hover a slot's handle (title strip, layers header, or a 3px grip drawn after `SkipToPointer:`) | `DOCK_handle_at%`, `DOCK_overlay_render` |
| Right-click a handle: Move to Left/Right Edge, Collapse/Expand, Float/Dock Back, Reset Arrangement; Scale for the floating-panel family (`DOCK_menu_add_scale`, `DOCK_ACT_SCALE` 20 = Auto, 21-28 = 1x-8x -> `FPANEL_set_scale`) | `DOCK_menu_build`, `DOCK_menu_do` |
| Drag the divider between two flex slots | `DOCK_handle_divider%` |
| Drag a handle (5px threshold) → drop on an edge / between columns (new column), a slot's top/bottom third (split), middle (tab), elsewhere (float) | `DOCK_handle_move%`, `DOCK_drop_target`, `DOCK_drop_apply`, `DOCK_move_render` |
| Click a tab / chevron, double-click a title | `DOCK_title_click`, `DOCK_toggle_collapse` |
| Double-click a floating title / Dock Back | `DOCK_dock_back` (`halone` → its own column again) |
| Drag a floating panel's right / bottom edge or corner | `DOCK_handle_float_resize%` (`DOCK_RZ`, `DOCK_float_edge_at%` — region-guarded like the handles; cursor via `DOCK_float_cursor_edge%` in `POINTER_build`) |

Every tree change: `DOCK_change_begin` … `DOCK_change_commit msg` (saves to the
active workspace via `WSC_save_dock`, else `CONFIG_save`).

## Lock Layout (`CFG.LAYOUT_LOCKED`, action 2470, `Ctrl+Shift+L`, View → Lock Layout)

For drawing with a shaky tablet pen. While locked nothing that changes the arrangement can start: `DOCK_handle_mouse%` returns before the divider / floating-edge / Browser-band / handle-move / edge drags (the right-click handle menus above it still work), and each native window's title drag or resize start (`COLORMIXER`, `ADVCP`, `CS3D`, `PENP`, `PREVIEW` move + resize, `BROWSER` move + resize + title double-click maximize) takes `LAYOUT_unlocked%`, which flashes why nothing moved. The resize cursors stay off (`DOCK_wants_cursor%`, `DOCK_wants_vcursor%`, `DOCK_float_cursor_edge%`, the Preview / Browser edges in `POINTER_build`). No drag affordance is drawn either: no handle hover highlight (`DOCK_overlay_render`), and floated panels lose their grip dots, `#` dock mark and resize corner (`DOCK_render_float_frame`); toggling calls `INVALIDATE_scene`. Clicks, tabs, buttons and the Customize Toolbars window are unaffected. Global (saved in DRAW.cfg, not per workspace). Test: `dock-lock-layout`.

## Snap Panel Edges (`CFG.SNAP_PANEL_EDGES`, action 2471, View → Snap Panel Edges)

On (default): a dragged floating window (dock float or native) snaps to the other floating windows' edges and the chrome, and the no-overlap placement keeps them apart (`GUI/FLOAT-PANEL.BM`). Holding a drag still against a snap for `FPANEL_SNAP_HOLD` (1.5 s) sets `FPANEL_HOLD_FREE` for that drag ("Snap released - drop it anywhere"), so it can be dropped over another window. Off: windows move freely and may overlap. Overlapping windows stack by `GUI/WINZ` (a press raises one; see `draw-zorder.md`). Global, saved in DRAW.cfg. Test: `dock-float-snap-hold`.

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
