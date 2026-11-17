# Docking: the panel tree (GUI/DOCK)

Photoshop/GIMP-style panel arrangement: dock, stack, tab, collapse, float, dock
back. Plan and decisions: `PLANS/_/DOCKING-PLAN.md`. Built on branch `docking`
(2026-10), on top of the flexible widths in `GUI/DOCK-RESIZE` (#156).

**Fixed rules:** panels dock in LEFT / RIGHT columns and in TOP / BOTTOM rows (the columns turned
sideways, 2026-11-16 - see "Top / bottom rows" below). The menu bar is always on top (the text bar
is a dock panel since 2026-11-16, `DP_TEXTBAR` - see "Text bar" below);
the status bar and color strip are always at the bottom.

## Files

| File | Role |
| --- | --- |
| `GUI/DOCK.BI` | Types + state: `DPANEL()` registry, `DOCK_COL()`, `DOCK_SLOT()`, `DOCK_TAB(slot, tab)`, `DOCK_UI` (hover/menu/divider/move/target), constants |
| `GUI/DOCK-TREE.BM` | **Pure** tree code, unit-tested by `QA/unit/dock-unit.bas`: registry, editing, `[DOCK]` grammar, snapshots, moves. No SCRN/CFG/THEME here, so the unit test compiles it alone |
| `GUI/DOCK.BM` | Everything that touches the app: layout, per-panel adapters, handles, menu, dividers, move/drop, float host, native windows, legacy-key bridge |
| `GUI/DOCK-RESIZE.BM` | Inner-edge width drag; `DOCK_handle_mouse%` calls chrome → divider → move → edges, in that order |

## Model

- **Panel** (`DP_*`, 16): TOOLBOX, ORGANIZER, DRAWER, LAYERS, EDITBAR, ADVBAR, CHARMAP, WORKFLOW (dock panels, ids 1-8) and PREVIEW, MIXER, ADVCP, CS3D, PEN, BROWSER, ANIM, SWATCH (native floating windows, ids 9-16: `id < DP_PREVIEW` = a dock panel, and loops over the windows run `DP_PREVIEW TO DP_COUNT`). A panel added later is missing from older saved trees: `DOCK_adopt_new_panels` (in `DOCK_layout`) places it - see the workflow buttons in `draw-workspaces.md`. `DPANEL(id)`: name, title, `hmode` (`DP_H_FIXED` own height / `DP_H_FLEX` shares), `tall` (makes its column full height), `bordered`, `floats` (has its own window), `slot` (0 = not docked), float rect, dock-back memory (`hside/hcol/hslot/halone`), and this frame's rect (`rVis, rx..rh`).
- **Column** `DOCK_COL`: `side` (`DOCK_LEFT` 1 / `DOCK_RIGHT` 2 / `DOCK_TOP` 3 / `DOCK_BOTTOM` 4 - sides 3 / 4 are ROWS: `DOCK_is_row%(c)`, `DOCK_side_is_row%`, `DOCK_in_row%(id)`), `ord` (1 = outermost), `wpx` (0 = the panels' own width; a row's height). `DOCK_MAX_COLS` = 16 holds both.
- **Slot** `DOCK_SLOT`: `col`, `ord` (1 = top), `share`, `collapsed`, `ntabs`, `act`. `autoc` = collapsed by the layout this frame (not saved).
- **Default tree:** while `DOCK_CUSTOM = FALSE`, `DOCK_build_default` rebuilds the tree **every layout** from the old side keys (`TOOLBOX_DOCK_EDGE`, `LAYERS_PANEL_DOCK_EDGE`, edit/adv bar and charmap `dockSide`). Any user arrangement sets `DOCK_CUSTOM` (`DOCK_change_begin`) — otherwise a live drag is undone the next frame.

## Layout (`DOCK_layout`, called from `SCREEN_compute_layout`)

Sizes are solved by `QB64_GJ_LIB/LAYOUT` (flexbox-style lines; see `draw-layout.md`): every panel states its sizes in **one** place, `DOCK_panel_box`, and the dock turns them into lines.

1. **The screen row** (`DOCK_row_solve`) is one line: left columns (outermost first), the canvas (at least `DOCK_MIN_CANVAS_W` = 160, takes the rest), right columns. A column's width is `DOCK_col_width%`: the widest of its panels' boxes, or its `WIDTH:` override. **Small windows:** while the line overflows, the outermost column of the wider side is dropped (`autoh`, toolbox column last) by hand and the line solved again. Columns holding a `tall` panel are FULL height; full height **spreads outward** (any column outside a full one is full too). The menu bar spans between the full-height columns (`DOCK_MENU_LX/RX`).
2. **Each column** (`DOCK_stack_column`) is one line in flex mode: fixed panels take their own height, bordered neighbours share a frame row (`lead -1`), flex panels split the rest by `share` and **never go below their minimum: the others give way** (before 2026-10-09 a too-small share was bumped afterwards and the column ran past the dock; test `dock-column-min-share`). Titled slots (tabs, collapsed, docked native window) get an 11px strip (`DOCK_TITLE_H`). Too short even at the minimums: slots collapse to their strips from the bottom, never the first (`autoc`, the line's drop order).
4. `DOCK_apply_rect` hands each visible panel its rect (the fields its own code reads). `DOCK_live%(id)` gates every panel's render and hit tests.
5. Canvas edges `DOCK_LX/RX` → `SCRN.uiLeftEdge/uiRightEdge`, `panelShiftX`.

**The window x range the docks get (`DOCK_WX1/WX2`, 2026-11-16).** Everything above lays out in
`DOCK_WX1..DOCK_WX2`, not `0..SCRN.w-1`: the colour strip can dock down the left / right edge
(`CFG.PALETTE_STRIP_EDGE` 0 bottom, 1 top, 2 left, 3 right) and the docks sit beside it.
`SCREEN_compute_layout` sets them from `PALETTE_STRIP_left_w%` / `_right_w%` and adds
`PALETTE_STRIP_top_h%` to `barY1` (and the char-map / text-bar tops) **before** `DOCK_layout`, then calls
`PALETTE_STRIP_geom` after it (the strip's rect depends on the menu bar span `DOCK_MENU_LX/RX` and the full
columns). The row solve, `DOCK_place_rows` full mode, `DOCK_row_span`, the native-seam outer edges and the
edge drop zones all use WX1/WX2 - a new "the window's edge" in dock code must too. Everything that draws or
hit-tests the strip reads `PSG` (`GUI/PALETTE-STRIP.BI`); dump lines `PSTRIP` / `PSTRIPG` / `PALNAME`.
Test: `palette-strip-edges.sh`.

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
- Floating, the window's own title drag calls `DOCK_native_drag` (targets + preview) and `DOCK_native_drag_end%` on release (docks if over a target). `DOCK_native_drag` applies the same `DOCK_DRAG_START` (5 px) threshold as a docked panel's handle: until the pointer has travelled that far there is no target, so a click on the title only raises the window. Without it, a click on a window lying over a dock target docked it (found by `gui-float-zorder` on Windows, 2026-11-17).
- `DOCK_native_undock` restores the floating size and saves the position to its CFG keys. The Browser keeps its floating size in `CFG.BROWSER_WIDTH/HEIGHT` — every write of those is guarded with `docked = 0` so the slot size never overwrites it.
- **A window that stretches to its slot (Preview, Browser) never holds its column wide** (`DOCK_panel_box` marks it stretchy; `DOCK_col_width%` combines). In a column beside other panels it asks only for its minimum width, and the column follows the others. Alone in a column it sets the width from its floating width (`DOCK_panel_w%`: `CFG.PREVIEW_W` × render scale, `CFG.BROWSER_WIDTH`), never its live slot width. A live width feeds back: the column is as wide as its widest panel, the window takes the column's width, and the column never shrinks again. Using the floating width alone also failed, for a floating width of 800. Rick's layers, dragged to 400 with the Preview docked above them, could not be narrowed back. The Mixer, Advanced Color Picker, 3D and Pen keep their own size and center in the slot.
- **Never past the slot (2026-11-17, `workspace-builtins-load.sh` on Rick's workspaces).** A row squeezed between wide side docks can be narrower than a window's floor. The Browser floors its dialog at `BROWSER_narrowest_w%` (KITCHEN SINK: 194 px slot, 282 floor): `BROWSER_render` keeps the slot's dispW/H after `BROWSER_compute_display_size` and the blit cuts the dialog at the slot. Pen Pressure in a row (`PENP_layout`) takes the slot width and narrows its five columns below `PENP_ROW_COL_MIN` (TABLET: 504 for 520) - centred and wider, it covered the bars beside it. The harness check is `dk_check`'s "window X outside its slot".
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
- **Rows** (top / bottom): a native window in a row has its frame painted out
  (`DOCK_render_native_seams`), and every row gets one seam row on its canvas
  side (`DOCK_row_seam_y%`, `EDIT_BAR_RIGHT_BORDER_COLOR`), plus a vertical line
  between side-by-side slots and after the last one (`DOCK_render_seams`). The
  toolbox family renders before `DOCK_fill_columns`, so a row's fill
  (`DOCK_fill_row`) only covers what no panel draws: under a fixed-height panel,
  under a collapsed strip, an empty drawer, and past the last slot. Docked, `BROWSER_sync_fd_from_display` rounds the dialog size DOWN
  (`INT`, not `+0.5`) so at a fractional render scale it never draws a row past
  its slot (it did: a 221px dialog in a 220px band).
- Test: `dk_seams` in `QA/dock-lib.sh` (also run by every `dk_check`, so all
  dock / fuzz tests check it): per row of every visible column, the inner edge
  is the seam colour, the pixel across it and the one inside are not, and no
  lighter frame line runs beside it (8+ rows); each row's seam row likewise
  (T junctions exempt: a slot separator, a side column's seam meeting it in
  full-width mode). An empty awk result FAILS (an apostrophe in an awk comment
  inside the single-quoted program once made every seam check pass vacuously). `SEAM` line in the dock dump; `DK_SEAM_COLORS="404040 404040"`
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

For drawing with a shaky tablet pen. While locked nothing that changes the arrangement can start: `DOCK_handle_mouse%` returns before the divider / floating-edge / row-edge / handle-move / edge drags (the right-click handle menus above it still work), and each native window's title drag or resize start (`COLORMIXER`, `ADVCP`, `CS3D`, `PENP`, `PREVIEW` move + resize, `BROWSER` move + resize + title double-click maximize) takes `LAYOUT_unlocked%`, which flashes why nothing moved. The resize cursors stay off (`DOCK_wants_cursor%`, `DOCK_wants_vcursor%`, `DOCK_float_cursor_edge%`, the Preview / Browser edges in `POINTER_build`). No drag affordance is drawn either: no handle hover highlight (`DOCK_overlay_render`), and floated panels lose their grip dots, `#` dock mark and resize corner (`DOCK_render_float_frame`); toggling calls `INVALIDATE_scene`. Clicks, tabs, buttons and the Customize Toolbars window are unaffected. Global (saved in DRAW.cfg, not per workspace). Test: `dock-lock-layout`.

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

## Top / bottom rows (2026-11-16; the Browser's old band folded in)

A row is a `DOCK_COL` with side `DOCK_TOP` / `DOCK_BOTTOM`: same slots, tabs, collapse and grammar,
laid out as a horizontal `LAY` line. Any dock panel and any native window can be in one (handle menu
**Dock Along the Top / Bottom**, `DOCK_ACT_BAND_TOP` 7 / `_BOTTOM` 8 -> `DOCK_dock_along id, side`:
joins the end of the innermost row, else a new row).

- **Layout order in `DOCK_layout`:** column widths (rows skipped, `full = FALSE`) -> `DOCK_row_solve` ->
  `DOCK_rows_measure barY1, dockY2` (heights `DOCK_row_h%`; the innermost rows of the taller side are
  hidden while the rows leave less than `DOCK_ROW_CANVAS_MIN` = 60 for the canvas) -> in **full-width**
  mode with top rows the side columns start under them (`colY1 = barY1 + TOPH`, `colY2 = dockY2 - BOTH`)
  -> `DOCK_place_columns` -> `DOCK_place_rows` (x `DOCK_LX..DOCK_RX`, or the window when full width;
  top rows under the menu bar; the text bar is one of the rows now, `DP_TEXTBAR`). Sets `DOCK_ROWS_Y1/Y2/TOPH/BOTH` and
  `DOCK_SHIFT_Y = (TOPH - BOTH) \ 2` -> **`SCRN.panelShiftY%`** (added to every vertical canvas
  position, ~38 sites, the twin of `panelShiftX%`). Scrollbars and `FPANEL_band_trim` read the rows.
- **Width in a row** (`DOCK_row_panel_box`, at the row's height): toolbox = fewest columns whose height
  fits (`DOCK_row_tb_w%`; it reflows because `DOCK_tb_follows%` includes `DOCK_in_row%`); organizer /
  workflow = a 2px-step search for a width that fits; edit / advanced bars = `BL_hbar_w%` at
  `BL_hbar_rows_fit%` (they flow sideways, column-major, through `BL_HROWS(panel)` set by
  `DOCK_apply_rect` - `BL_bar_draw_h%`); drawer / browser / preview / swatches stretch; the rest
  `DOCK_panel_box`. The drawer caps its bins at the row's height and adds columns (`DRAWER_layout`).
  - **Organizer in a row** (Rick 2026-11-16): when the row is too short for whole stacks,
    `ORGANIZER_layout_in% x, y, w, hMax` stands the stack tops side by side and moves each stack's
    last widget (Symmetry / Grid Vis / Grid Snap / Color Mode) into a 2-row grid right of them
    (`ORG_ROW2_X/Y`, which the render reads for those four in every layout). Split size
    `ORGANIZER_split_w%` / `ORGANIZER_split_h%` (`ORG_TOP_H` = 22 units: Pattern 11 + Gradient 11
    from row 1); it is the organizer's row minimum height, so beside the toolbox the row keeps the
    toolbox's height. `DOCK_row_panel_box` searches widths up to the split width with
    `ORGANIZER_height_in%`.
    Shorter than the split (`ORG_TOP_H` units) it lies **flat** (Rick: "get down to 1 button in
    this bar"): `ORG_FLAT`, every widget in one line, stack by stack (`ORGANIZER_flat_put`), Opacity
    and Brush Size turned sideways (`BRUSH_H` wide x `COL_W` tall; the brush image is a cached 90°
    CCW copy, `ORGANIZER_rot_img&`; the opacity slider fills from the left; both read clicks along x).
    Every widget's rect is in `ORG_WX/WY/WW/WH` for every layout. Min row height =
    `ORGANIZER_flat_h%` (one column width + 2).
  - **The Advanced Color Picker and the Color Mixer lie sideways in a row** (Rick: "size downward ...
    to fit in bars vertically", "keep it 2 buttons high", "controls flush right"). Their row minimum
    is small (`ADVCP_ROW_WHEEL_MIN` / `COLORMIXER_ROW_FIELD_MIN` + title), and they have no row want,
    so the toolbox sets the row's height; `DOCK_row_panel_box` asks their width at the row's height
    (`ADVCP_row_w%`, `COLORMIXER_row_w%`). ACP: the library's side layout, `ACP_resize_side wheel,
    colW, patchH` - the wheel at the left (ring / inset / padding scale down under 120 px), the
    sections (quantize, the host's VARIATIONS row, each shade row, history: `ACP_BLK_*`) flowed top to
    bottom into `colW` columns to its right (`ACP_side_flow`); every section position goes through
    `ACP_blk_x%` / `ACP_blk_y%` / `ACP_blk_w%`, so stacked is unchanged.
    Round 2 (Rick's screenshots, same day): quantize always **under the wheel** (`ACP_quant_row_y%` =
    wheel, `ACP_quant_w%` = the wheel + the gutter; under a small wheel only the track + value,
    `ADVCP_quant_insets`); a **gutter** (`ACP_STATE.sideGutter` = `ADVCP_ROW_GUTTER` 14) between the
    wheel and the columns holds the gear (always beside the wheel; stacked it sits at the wheel
    square's top right) and VARIATIONS as a 9 px **triangle** (`ADVCP_draw_triangle`, no row - "a
    little triangle that opens it instead of a big more gap"); the shade rows flow in **balanced**
    columns (`per = ceil(lines / ceil(lines / fit))`: 10 rows, room for 5 a column = 5 + 5); a row's
    last patch ends at the column's own edge (`bx0`), so inline labels never overlap the column
    before. **Ring thickness** `CFG.ADV_COLOR_PICKER_RING` 30-100 % (`ACP_set_ring_pct`: thinner
    ring, bigger triangle) - Settings "Ring Thickness %", Ctrl+wheel over the picker
    (`ADVCP_ring_wheel`, steps of 10). Mixer: MORE is a triangle in the title bar left of the close
    box in a row (`COLORMIXER_side_more_rect`; its strip is dropped; `DOCK_native_grab%` stops left
    of it so the title drag doesn't eat the click). Dump `ACPR x y w h` per open shade row. Mixer: the CP library still lays out stacked (`CP_STATE.svHFix` sets
    the SV field's height); the host copies the stacked rows below the field as strips into columns
    (`COLORMIXER_side_flow%`, `CMX_SY0/SY1/DX/DY`, composed in `COLORMIXER_side_compose` into
    `COLORMIXER.sideImg&`, one title bar across) and maps the pointer back (`COLORMIXER_to_cp`; a
    press remembers its strip so a drag keeps the mapping; `COLORMIXER_from_cp` for the hex box and
    the dump). Both relayout when they enter / leave a row (`fitRow`). Dump `ACPW x y w h side`,
    `CMXM ... side`. Test: `dock-row-color.sh`. Opening VARIATIONS / MORE widens the panel; a row
    wider than the window drops a slot (the panel hides) - keep them closed in a crowded row.
  - **Bars in a row are one even grid:** `BL_bar_draw_h%` / `BL_hbar_w%` skip dividers and gaps there,
    so every column is full but the last (they used to end a column at each divider).
  - **Character map in a row:** stretchy (`DOCK_row_panel_box`: min 4 cells, basis 16), and
    `CHARMAP_cells_per_row%` = as many whole cells as the slot's width holds (`CHARMAP_in_row%`; no
    side-column fit scale) - Rick: "extend to the right when i make room for it, snapping many
    cells". Dump `CMAPC cols cellW pad panelW inRow`. Test: `dock-row-charmap.sh`.
  - **Zoom to fit** keeps the canvas between the rows: `ZOOM_viewport_rect` clips to `DOCK_ROWS_Y1/Y2`
    (it only knew the old Browser band). Dump `CANVR x y w h`. Test: `dock-row-zoomfit.sh`.
  - **Drawer zoom in a row:** Ctrl+wheel sets `CFG.DRAWER_ROW_BIN_ROWS` (bin rows in the row's height,
    0 = 1; workspace key too), not `DRAWER_BIN_COLS` - bins per row fill any width, so that zoom
    did nothing in a wide row.
- **The Alt eyedropper over chrome reads the frame as shown** (Rick: "i can't pick colors or use
  the loupe over the docked vertical bars"): docked panels (`PSURF_blit_docked`) and native windows
  draw straight to screen 0 after `SCENE_CACHE` is saved, so sampling the cache gave what is under
  them. `PICKER_LOUPE_screen_pass` (end of `SCREEN_render_windows`) copies screen 0 into
  `PICKER_LOUPE.SNAP` while Alt is held (or an Alt drag-pick is on) and draws the chrome loupe there,
  over the windows (`WIN_PASS`; the canvas-time call skips chrome). `MOUSE_eyedrop_screen` reads
  SNAP; a held Alt press drag-picks (`PICKER_LOUPE.DRAG_BTN`) until the button lifts. Dump `LOUPE
  ok x1 y1 x2 y2 RRGGBB`. [Linux, Xvfb] an Alt-held press never arrives (memory
  `qa-xvfb-alt-press-lost`), so QA checks the loupe on hover only.
- **Browser column width:** `DOCK_panel_max_w%(DP_BROWSER)` = the window less 200 px (was 600).
  Test: `dock-browser-wide.sh`.
- **Pen Pressure in a row** (Rick 2026-11-16: "should fan out to columns"): `PENP_layout` sees
  `DOCK_in_row%(DP_PEN)` and lays USE + meter | SIZE | OPACITY | MIX | CURVE + TIP side by side, every
  group from the top, the response graph a square as tall as the row on the right. Each control has
  its own column and track span (`PENP_ctlX0/X1`, `PENP_ctlTX0/TX1`; stacked they are all the panel's
  width) - `PENP_hit%`, `PENP_draw_*` and `PENP_track_frac!(ctl, nx)` read them. The dock: min height
  `PENP_row_h%`, basis / min width `PENP_row_w%(h, PENP_ROW_COL_W / _MIN)`, stretchy; short of room
  beside other row panels the slot is dropped like any too-wide row panel. `PENP_fit` relayouts when
  the row state flips. Dump `PENPL inRow panelW panelH gx0 gx1 yGraph graphH` + `PENPC ctl x0 x1 y
  tx0 tx1`. Test: `dock-row-pen.sh`.
- **Popups from a row panel** (Rick 2026-11-16): docked panels draw on screen 0 after the GUI layer,
  so anything a panel opens must be reblitted over them (`POPUP_reblit_to_screen0`). The Smart
  Shapes flyout maps its parent button through `PSURF_rect_to_view` when the toolbox has its own
  Scale (GUI_TB holds surface units then) and, with the toolbox in a top / bottom row, drops down /
  up as a column (`SUBTOOL_FLYOUT.VERTICAL`). The text bar's font / size / style lists are
  `POPUP_K_TEXT_BAR` (their boxes in `TBDD_X/Y/W/H`, noted as drawn). Dumps `SUBFLY`, `TEXTBAR`.
  Test: `dock-row-popups.sh`.
- **Text bar** (`DP_TEXTBAR` = 9, the last dock panel - the native windows moved up one, `WZ_TBED`
  = 18; Rick 2026-11-16 "scaleable, like the other panels" + "dockable left, right, top, bottom"):
  it used to be a fixed strip (`DOCK_TOPBAR_H`, now always 0). Shown = `TEXT_BAR_wanted%` (text tool
  or a text layer edited, not under F11). `DP_H_FIXED`: its height = `TEXT_BAR_h_for%(w)` = the
  lines its controls wrap into at width w (`TEXT_BAR_lines_for%` runs the render into a 4x4 scratch
  image with `TEXT_BAR.measuring` set, restores the whole `TEXT_BAR` record + `TEXT_BAR_BY`, caches
  by a key of what changes widths + `TEXT_BAR_MEASURE_GEN`); stretchy in rows / columns (min
  `TEXT_BAR_MIN_W`), a row's height from its last width (`DOCK_textbar_row_w%`); floating, the
  window is exactly its lines. Old trees adopt it as the outermost top row (`DOCK_adopt_new_panels`
  / `DOCK_textbar_place`). PSURF member (Scale = `CFG.TEXT_BAR_SCALE`): the bar and its dropdowns
  all live in its units - `TEXT_BAR_render` draws into the current destination, the dropdowns are
  a separate pass after the floats (`TEXT_BAR_render_dropdowns`; at a Scale into its surface,
  grown to the viewport in units, and `TEXT_BAR_blit_dropdowns` from the popup pass); the pointer
  is mapped once at the public entry points (`TEXT_BAR_handle_click%` / `_wheel%` / `_in_bounds%`
  / `_ui_in_bounds%` / `_update_dropdown_hover` -> the `_u` bodies; `TEXT_BAR_reachable%` = live,
  not under a window unless a list is open). Lists open upward in a bottom row or low in the
  window (`TEXT_BAR_dd_up%`, every list top via `TEXT_BAR_font/size/style_dd_y%`). The work area
  reads `TEXT_BAR_top_edge%` (the rows' end when it is in a top row, else 0). Test:
  `dock-textbar.sh`.
- **Browser in a side column** (Rick 2026-11-16): `DOCK_edge_at%` grabs the column edge over a
  docked window's own region too (`DOCK_region_docked_side%`) - it used to work only by the title
  bar; the Browser stacks its preview UNDER the folder list (`FD_STATE.pvStack`, set in
  `BROWSER_sync_fd_from_display` from `DOCK_panel_side%`; FD layout `placesH / previewY / previewH`,
  the side width kept in `pvSideW`, the bar between them drags `pvStackH`); the places drag down to
  an icon + a letter (`FD_places_tiny_w%`). Its path field and search box take typing:
  `BROWSER_keys%` / `BROWSER_text_focused%` in `KEYBOARD_input_handler` + `CTX_TEXT_ACTIVE`, like the
  mixer's hex box (`FD_STATE.searchFocus`, `FD_INPUT_search_key%`). Dumps `BROWSERV`, `BROWSERF`.
  Tests: `dock-browser-stack.sh`, `dock-browser-text.sh`, `gui-browser-pane-fit.sh`.
- **Pixel Art Analyzer chrome:** its frozen chrome (`paChrome`) is the screen as shown (`bgSnap`) with
  the canvas viewport cut out - `SCRN.GUI&` lacks the docked panels, so the rows showed as empty
  outlined boxes while it was on.
- **Slot width along a row:** a slot's right edge (`DOCK_row_slot_edge_at%`: 2px either side, under
  the handle strip, never through a floating window) drags its width - `DOCK_handle_row_slot_resize%`
  stores px in `DOCK_SLOT.share` (> 1 in a row = a width; 1 = auto), saved as `@px` like a column's
  shares; a double-click on the edge = auto. `DOCK_lay_row` gives such a slot basis = share, min =
  what fits the row's height (`DOCK_row_slot_min_w%`), shrink 1. The horizontal resize cursor via
  `DOCK_wants_cursor%`. Test: `dock-row-fit.sh` (all four).
- **Height:** `wpx` (0 = the tallest panel's want, `DOCK_row_want_h%`); its inner edge resizes it
  (`DOCK_row_edge_at%`: a bottom row's zone is the 3px ABOVE it - canvas side only, so a panel's grip on
  its first row is not an edge; a top row's is `ey-2..ey+1`), `DOCK_handle_band_resize%`, "Dock row: N px".
- **No slot dividers in a row:** its slots lie side by side, each its own width, so
  `DOCK_divider_at%` skips rows. Before it did, two flex slots in a row (edit bar | layers) got a
  full-row-width "divider" at the second slot's top - the seam row - which ate every first-row handle:
  no panel in that row could be dragged out (dock-fuzz-windows-5, 2026-11-16 [Linux]).
- **Drop targets:** `DOCK_row_drop_target%` (tried before columns): a row's outer / inner 6px = a new
  row before / after it, a slot's left / right third = split beside, the middle = tab, the empty rest =
  the end of the row; the canvas area's top / bottom edge zone = NEWCOL on side TOP / BOTTOM (a new
  innermost row). Labels "new row along the top/bottom", "beside here".
- **Width setting** `DOCK_ROWS_FULL` (snapshot `ROWSPAN=FULL`, DRAW.cfg `DOCK_ROWSPAN=FULL`; Settings >
  Panels > Docks "Top/Bottom Docks: Between Side Docks | Full Width", `CFG.DOCK_ROWS_FULL_WIDTH` is the
  Settings field only). Default = between the side columns.
- **Legacy `BAND=TOP|BOTTOM,h`** (DRAW.cfg `DOCK_BAND`) still loads: the innermost row on that side
  holding the browser, `wpx = h` (220 if under 80). It is never saved again; `DOCK_BAND_SIDE` stays 0.
  `BROWSER.docked` = `DPANEL(DP_BROWSER).slot > 0`.

## Persistence

Snapshot text (`DOCK_snapshot$` / `DOCK_load_snapshot`): `CUSTOM=0|1`, `LEFT.n=`, `RIGHT.n=`, `TOP.n=`, `BOTTOM.n=`, `ROWSPAN=FULL`, `FLOAT.name=x,y,w,h` (old `BAND=` loads as a row).

- **DRAW.cfg:** `DOCK_CUSTOM`, `DOCK_LEFT_n`, `DOCK_RIGHT_n`, `DOCK_TOP_n`, `DOCK_BOTTOM_n`, `DOCK_ROWSPAN`, `DOCK_FLOAT_name` (`CFG_DOCK_SPEC`, `CONFIG_save_dock`). Loaded in `DRAW.BAS` before `WS_startup`.
- **Workspace:** `[DOCK]` / `[FLOAT]` sections (`WS_apply_dock`). Leaving restores `WS_DOCK_USER_SNAP` when `WS_DOCK_TOUCHED`. A workspace with `*_DOCK` keys but no `[DOCK]` gets the default tree so its sides apply.
- **Saving a layout:** `WSC_capture_layout` (Save Current Layout As / Update) writes the tree; the configurator's **Dock** tab shows `[DOCK]`/`[FLOAT]` lines with *Use current* / *Default*.

Grammar, one line per column, outermost first:

```ini
[DOCK]
LEFT.1=AUTO; toolbox | organizer | drawer
RIGHT.1=WIDTH:180; layers@2 | *preview+colormixer | !browser
TOP.1=AUTO; editbar | toolbox
BOTTOM.1=HEIGHT:220; browser
ROWSPAN=FULL
[FLOAT]
pen=640,120,220,300
```
`AUTO` or `WIDTH:px` (`HEIGHT:px` for a row); slots `|` (side by side in a row); tabs `+`; `*` active tab; `@n` share; `!` collapsed. Toolbox and bar **column counts** stay in their own keys (`TOOLBOX_COLUMNS`, …), not in `[DOCK]`.

## Testing

**Live layout dump:** `--option DOCK_DUMP=<path>` (QA-OPTIONS `DOCK_DUMP=QA/.dock-dump.txt`) makes `DOCK_layout` write `SEQ / TREE / BAND / ROWS / SCR / COL / SLOT / P` lines (`COL` includes rows, side 3 / 4; `BAND` = the Browser's row: side 1 top / 2 bottom, slot x, row y, slot w, row h, shiftY; `ROWS full y1 y2 toph both`) (every rect, handle rect, tab rect, auto-collapse) whenever they change (`DOCK_dump_write`). `QA/dock-lib.sh` reads it: `dk_move NAME TARGET` (edge-left/right, newcol, above, below, left, right, tab, bottom, float, band-top/bottom - any panel), `dk_rows`, `dk_expect_row`, `dk_rmenu` / `dk_pick` (handle menus), `dk_move_expect`, `dk_check` invariants (each panel once, docked <=> in the tree, on screen, no overlaps, saved == on screen, floats + band saved), `dk_fuzz SEED STEPS PANELS...` (seeded random chains). Tests: `dock-separate*`, `dock-combine-<panel>` x6, `dock-after-combine`, `dock-fuzz-*`, `dock-windows*`, `dock-persist`, `dock-browser-band`, `dock-rows`, `dock-float-bar`, `dock-startup`, `dock-small`, `dock-tabs`, `dock-arrange`.

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


## Panel surfaces: a docked panel at its own Scale (GUI/PANEL-SURFACE, 2026-11-14)

The dock panels (toolbox family, layers, edit / advanced bars, charmap, workflow buttons) draw
into the viewport, so one panel px = displayScale screen px. Rick wanted "real
1x like the floating panels": `CFG.<PANEL>_SCALE` (`EDIT_BAR_SCALE`,
`ADV_BAR_SCALE`, `TOOLBOX_PANEL_SCALE`, ... 0 = Auto) through the FPANEL scale
family (`FPANEL_has_scale%` / `_scale_setting%` / `_auto_scale%` /
`FPANEL_set_scale`, the handle menu's Scale rows, Settings > Panel Scale).

- `PSURF_on%(id)`: a Scale set and not equal to its Auto (displayScale x the
  panel's own widget scale). Off = the old path, untouched.
- On: `DOCK_apply_rect` calls `PSURF_set_rect` (the footprint = the dock rect,
  viewport px) and gives the panel a rect of `uw x uh` **panel units** from the
  same top-left (`PSURF_u%` = v x ds / k). The panel's code is unchanged: it
  draws at its usual absolute coords into `PSURF(id).img` (`PSURF_render`,
  called where the render lists called the panel's render SUB), the footprint
  in SCRN.GUI& gets the background, its REGION gets the footprint.
- `PSURF_blit_docked` (start of `SCREEN_render_windows`, every present path)
  puts the surface on screen 0 at k screen px a unit, then the column seam
  back over it - and a top / bottom row's seam (`DOCK_row_seam_y%`: the
  row's canvas-side pixel row is inside the slot; a scaled Toolbox in a row
  painted over it, Rick's GJ2 / GRAFX2 workspaces, 2026-11-17); floating
  ones blit in their WZ turn.
- Sizes the dock asks for go through `DOCK_panel_w%` = `PSURF_v%(id,
  DOCK_panel_w_units%(id))` (and `DOCK_float_content_h%`).
- Hit tests: map the pointer with `PSURF_mx%` / `PSURF_my%` (from
  `MOUSE.WIN_X/Y` = `_MOUSEX/_MOUSEY`, so 1x resolves single screen px) **in
  the leaf functions only** (`EDITBAR_hit_test%`) - never twice. "Is over the
  panel" tests use the footprint (`PSURF_in%`). Rects read by others (toolbar
  editor marks, BTN dump) go through `PSURF_rect_to_view`.
- Dump: `PSURF id on k vx vy vw vh uw uh ready`, `PSURFP id ux uy` (the
  pointer in its units), `PTR rawX rawY winX winY`, `BARHOVER bar idx`.
  Test: `panel-scale-bars.sh`.
- **Toolbox family (P5).** Their widget scale (`TOOLBAR_scale%`,
  `ORGANIZER_scale%`, `DRAWER_scale%` = `PSURF_unit_scale%`) is 1 at their own
  Scale - a unit is one icon px, k screen px - and their Auto (CFG.TOOLBAR_SCALE
  / USCALE.organizer / .drawer) otherwise; every read of those scales in their
  code goes through the accessors. They share a column width in **different
  units**: convert through the viewport with `PSURF_u_of%(b, a, u)`
  (`TOOLBAR_reflow`, `DOCK_panel_w_units%`). `DOCK_fixed_h%` wraps
  `DOCK_fixed_h_units%`; `DOCK_tb_inset%` is 1 at its own Scale (its top border
  row inside its surface). Their render code must draw into **`_DEST`**, never
  `SCRN.GUI&` by name (the surface is the destination) - that was the one real
  trap - and must not leave a font it may free bound to a surface
  (`PSURF_font_release`). Hit tests map at the entry points that take raw
  coords and pass them down (`TOOLBAR_handle_*`, `ORGANIZER_handle_*`,
  `TOOLTIP_get_hovered_btn/org_idx%`) or at the drawer's leaves
  (`DRAWER_slot_at%`, `_palette_cell_at%`, `_select_palette_color`), the
  workflow buttons (their own panel since P12) in `WF_is_over_area%` / `WF_click%`. Dumps `ORGW i x y w h`,
  `DRWB x y w h`, `DRWAT slot` (viewport px). BTN's id is the **button** id,
  VIEW's the **tool** id (marquee button 7 = tool 5). Test:
  `panel-scale-toolbox.sh`.
- **Character map (P7).** Like the bars (a unit = a viewport px at Auto).
  `CHARMAP_render` used to `_DEST SCRN.GUI&` itself - at its own Scale that drew
  the grid into the viewport at unit coords, spilling over the next column
  (the QA dumps were all right; only a picture showed it). Now it draws into
  the current destination. `CHARMAP_fit_scale!`'s width cap is in its units;
  `CHARMAP_fill_stub` (viewport) fills the footprint's columns. Dump `CMAPV x y
  w h` (cell A, viewport px). Test: `panel-scale-charmap.sh` - with a "nothing
  spilled onto the panel beside it" region check.
- **Layers (P8).** A unit = a viewport px at Auto. `LAYER_PANEL_render` used to
  `_DEST SCRN.GUI&` and blit thumbnails / icons `_PUTIMAGE ..., SCRN.GUI&`; now
  the current destination (`oldDest&`). The leaf hit tests (`handle_click`,
  `opacity_drag`, `wheel`, `vis_swipe`, `drag`, `scroll_drag`,
  `get_row_slot`, the context menu) map the pointer; `LAYER_PANEL_in_bounds%`
  is the footprint. Code outside the panel that used its x2 / bottom in
  viewport px (POINTER.BM `WF_track`, PICKER-LOUPE, MOUSE.BM's loupe guard)
  goes through `LAYER_PANEL_view_x2%` / `LAYER_PANEL_view_bot%`. The tooltip's
  layer rows map with `PSURF_my%`. Dumps `LPHIT slot` (row under the pointer),
  `LPGEO header row btnbar` (viewport px). Test: `panel-scale-layers.sh`.
- **Grep a panel's render path for `SCRN.GUI&` by name** before putting it on
  a surface: `_DEST SCRN.GUI&`, `_PUTIMAGE ..., SCRN.GUI&`, `_FONT f, SCRN.GUI&`.
