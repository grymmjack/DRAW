# Workspaces, screen capture & annotate tools

Built on branch `workspaces` (2026-10-06). User docs: `docs/MANUAL/22-workspaces-capture.md`.
Plan + decisions: `PLANS/_/WORKSPACES-AND-CAPTURE-PLAN.md`; review notes:
`PLANS/_/WORKSPACES-REVIEW-NOTES.md`.

## Modules

| File | Prefix | Role |
|------|--------|------|
| `CFG/WORKSPACE.BI/BM` | `WS_` | File layer: scan built-in `ASSETS/WORKSPACES/*.workspace` + user `<data>/WORKSPACES/` (user id wins), INI parse, `BASED_ON` flattening (`WS_resolve%` → `WS_RES_*`), `WS_get$`/`WS_has%`/`WS_next_in_section%`, comma lists. In `CFG/` (not `GUI/`) because `--workspaces` runs at include time from `CFG/CLI-QUERY.BI` and needs the arrays DIMmed first. Unit test: `QA/unit/ws-unit.bas`. |
| `GUI/WORKSPACE-APPLY.BI/BM` | `WS_` | The overlay: `WS_apply%` / `WS_restore`, the `CONFIG_save` guard, F11 reveal, `[START]` tick, toolbox/bars/menus/keys appliers, switcher + actions 2400-2449, startup (`WS_startup`), status badge. |
| `GUI/WORKSPACE-CONFIG.BI/BM` | `WSC_` | Configurator dialog (action 2401), on DIALOG_* + SW_* (same pattern as Settings). Edits a flattened store, saves a complete file to the user folder. |
| `GUI/CAPTURE.BI/BM` | `CAP_` | Capture backends, hide/delay/grab/show, region picker (`CAP_pick_region&`), 4096 fit, new document, `--capture` startup + mailbox handoff poll. Action 2450. |
| `GUI/ANNOTATE.BI/BM` | `ANN_` | Arrow / highlighter / redact / callout / quick save / Done; actions 2451-2457; armed modes polled by `ANN_tick`. Also holds the capture stash vars (`CAP_STASH_*`). |
| `GUI/WORKFLOW.BI/BM` | `WF_` | Workflow buttons (PLANS/PERSONAS.md, 2026-11-12): the labelled strip at the top of the toolbox, one button per id in `CFG.WORKFLOW_BUTTONS` (global, DRAW.cfg; `CFG.WORKFLOW_BAR` shows it). See below. |

## The overlay contract (`WS_apply%` / `WS_restore`)

- **Snapshot → apply → restore.** Only elements the workspace names (`SHOW`/`HIDE`, dock `LEFT`/`RIGHT`, `[OPTIONS]` keys) are touched; `KEEP`/absent = untouched. Restore puts back the snapshot (visibility, `ManuallyHidden`, CFG `*_VISIBLE`, dock CFG + `dockSide`, option values).
- **Elements** (`WS_EL_*`, 16): menubar, toolbox, layers, edit/advanced bar, status bar, preview, color mixer, charmap, 3D color space, adv color picker, pen panel, browser, organizer, drawer, palette strip. Floating panels are switched through their own `*_toggle` (first-show init, auto-position) — but never through toggles that call `CONFIG_save` mid-apply.
- **Hides set `ManuallyHidden% = TRUE`** so `MOUSE_handle_ui_autohide_restore` never brings them back (gotcha #12).
- **DRAW.cfg never sees the overlay.** `CONFIG_save` brackets its write with `WS_cfg_guard_begin` / `WS_cfg_guard_end`: touched CFG fields get the user's snapshot values for the write; `WS_CFG_LIVE = CFG` (a whole-struct copy, taken first) is put back after, so whatever is live comes back - including an `[OPTIONS]` key the user toggled inside the workspace (until 2026-11 the end step re-applied the file's value: Num 0 in Animate snapped the lightbox back on). `CFG_cli_guard_*` (--option) does the same with `CFG_CLI_LIVE`. Side effect: the few clamps CONFIG_save does in place (FD_*) land in the file, not in the live struct, during a guarded save. Option originals are captured by running `CONFIG_save` into a scratch file with `WS_GUARD_BYPASS` and reading the lines back (exact `CONFIG_apply_key%` text, no per-key getters). `MAIN_shutdown`'s live→CFG copies are covered because they go through `CONFIG_save`.
- **Drawer visibility lives in `.draw` files** (`DRAWER_save_state_binary`): it writes `WS_drawer_file_visible%`; loads/resets call `WS_on_drawer_loaded` so the hide survives a document change.
- **Hidden organizer** collapses to zero height (`ORGANIZER_render` still sets `panelX1..Y2`) so the drawer keeps its anchor; `ORGANIZER_is_over_area%` returns FALSE → every click/drag/hover gate is off.
- **Shift+F11** (`WS_ACT_REVEAL` 2407): `WS_f11%`; when the workspace hides anything it toggles `WS_REVEALED` (fixed chrome always revealed, floating panels only if the user had them showing).
- **F11** (action 403, `UIALL_toggle` in WORKSPACE-APPLY.BM): snapshots every `WS_EL_*` element (`UIALL_VIS` / `UIALL_MH`), hides them by their live fields only (`UIALL_set` - never the panels' toggles, which write `CFG.*_VISIBLE`, so a CONFIG_save while hidden keeps the real state), and the second F11 restores the snapshot. `WS_apply%`, `WS_restore` and `WSC_capture_layout` call `UIALL_show` first, so F11's empty screen is never a workspace's layout. Organizer / drawer / workflow follow the toolbox, the strip the status bar. Dump: `UIALL hidden tbed NAME=0/1 ...`; test `f11-toggle-all.sh`.
- **`[START]`** runs from `WS_tick` (post-render) so `ZOOM=FIT` sees the new layout and a command-line file has loaded. Not undone on leaving.
- `CFG.WORKSPACE` remembers the last workspace (`WS_NO_REMEMBER` for `--workspace NAME`).

## Customization layers

- **Toolbox (W2):** the 4×7 grid is the DEFAULT; slots go to 40 (`TB_MAX_SLOTS`). Every loop/geometry reads `TB_LIVE_COUNT/COLS/ROWS`, never `TB_TOTAL/TB_COLS/TB_ROWS`. Columns: `TB_WANT_COLS` is what was asked for (`CFG.TOOLBOX_COLUMNS`, `[TOOLBOX] COLUMNS`, an edge drag; 0 = take the cfg on the first layout); `TOOLBAR_reflow` (start of `SCREEN_compute_layout`) sets `TB_LIVE_COLS/ROWS`, adding columns while buttons + organizer + a usable drawer don't fit the height, and `TOOLBOX_PANEL_W` (px) = those columns, never narrower than one organizer stack / one drawer bin. Tooltip text is keyed by the button's *default* slot (`TOOLBAR_default_slot%`). Names → buttons: `TOOLBAR_button_by_name%`.
- **Bars (W3):** `EDITBAR_SHOW()` / `ADVBAR_SHOW()` / `ORG_HIDDEN()` filters (no reordering; dividers only between kept groups). Names: `WS_editbar_name$` / `WS_advbar_name$` / `WS_org_name$` keyed by action id. `PALETTE_STRIP_HIDDEN` makes `PALETTE_STRIP_get_height%` 0 (43 layout callers follow).
- **Menus (W4):** registration is positional and children name their root by a literal ordinal. `MENUBAR_register_item` translates through `MENU_ROOT_REMAP(orig)` (−2 = hidden root → child skipped). Post-registration code must use `MENU_ROOT_REMAP(n)` / `MENU_RT_AUDIO`, never literal root numbers. Filtered flyout parents return −9 so their children are skipped. A rebuild that would leave zero roots drops the filter.
- **Keys (W5):** `WS_key_action%` runs in `INPUT_dispatch_frame` *before* the first-match table (so nothing in the table is swapped). Guards: text active, dialogs/settings/popups/palette/menu, chord-held keys, a held mouse button. Ctrl/Alt combos via `WS_KEY_MODS`. Keys with no table binding get edges from `WS_detect_keys` (the table loop only watches bound keycodes — Enter had none). Mapped letters don't raise their held-chord ctx. Menus + palette relabel hotkeys (`WS_relabel_hotkeys`, re-applied by `MENUBAR_rebuild`).

## Flexible side docks (branch `workspace-flexible-chrome`, 2026-10-07)

Only the LEFT/RIGHT screen edges dock; the menu bar is always on top, the status bar + color strip always at the bottom.

- **Everything in the toolbox column reflows to `TOOLBOX_PANEL_W`.** Organizer: 4 widget *stacks* (`ORGANIZER_stack_of%`) placed by `ORGANIZER_layout%` in as many columns as fit (centered; a stack whose widgets are all hidden takes no room); its background spans the whole panel. Drawer: `DRAWER_layout` picks `DRAWER_COLS` (classic 3 up to the default 4-column width, up to `DRAWER_MAX_COLS` = 6 in a wider one), `DRAWER_STACKED` (mini palette under the bins when one bin doesn't fit beside the rail), `DRAWER_VIS_ROWS` and `DRAWER_ROW0` (Shift+wheel scrolls; the plain wheel still switches `.dset` sets). Slot index = `(row + DRAWER_ROW0) * DRAWER_COLS + col + 1` everywhere (`DRAWER_slot_at%`, render, drag highlights, tooltip). `TOOLBOX_fill_column` paints the column below the stack as panel when the drawer doesn't fill it.
- **Edit / advanced bars:** `EDITBAR_cols%` / `ADVBAR_cols%` (live `EDITBAR_NCOLS` / `ADVBAR_NCOLS`, 0 = `CFG.EDIT_BAR_COLUMNS` / `ADV_BAR_COLUMNS`), width `*_width%`; icons flow left→right, a divider ends the row. A variable can't share a FUNCTION's name (case-insensitive), hence `_NCOLS`.
- **Layers width:** `[CHROME] LAYER_PANEL_WIDTH` sets `LAYER_PANEL.width%` (`WS_LW_TOUCHED`, restored from `CFG.LAYER_PANEL_WIDTH`); `LAYERS_clamp_width%` = 60-400.
- **Edge drag (`GUI/DOCK-RESIZE`):** `SCREEN_compute_layout` registers each side panel's inner edge (`DOCK_set_edge`). `DOCK_handle_mouse%` runs in `MOUSE_process_frame` before `MOUSE_handle_gui_early%` (the press must not also be a panel click); `DOCK_edge_at%` is inert under menus, popups, palettes, flyouts and anything whose `REGION_hit_test%` isn't a docked panel / the canvas / GLOBAL. Live: `DOCK_apply_value`; drop: `DOCK_save_value` → `WSC_save_key` (active workspace, user copy of a built-in) or CFG + `CONFIG_save` (Default). Cursor: `DOCK_wants_cursor%` in `POINTER_build`.
- **CURRENT (2026-10-11):** `WS_CURRENT_ID$ = "current"`, always `WS_LIST(2)` (`WS_scan` pins it; virtual - `fpath = ""`, resolves to an empty overlay - until a save writes `current.workspace`). Title forced to "Current"; `WSC_id_for_name$` treats it like Default (reserved: New / Save As / exit prompt never write it by name; rename blocked). **A change in stock Default goes into CURRENT, no name asked:** `WSC_from_default_begin%` (both callers: `WS_layout_change_in_default` for dock moves / edge drags, `TBED_save%` for Customize Toolbars) starts the store afresh (`WSC_N = 0`, Default + `WSC_capture_layout`) and `WSC_save_and_use` switches to it. `WSC_save%` sets `WS_CURRENT_DIRTY` whenever it writes CURRENT. **Exit prompt:** action 212 calls `WS_exit_prompt` before `MAIN_shutdown` when CURRENT is active + dirty + `CFG.WORKSPACE_SAVE_PROMPT%` (skipped under `DRAW_HEADLESS=1`): `WS_exit_prompt_dialog$` (DIALOG + one-line TI field + 2 `SW_` checkboxes + OK; Esc / blank = skip) → copy of CURRENT under the name (`WSC_load` current → new `WSC_ID` → `WSC_save%`), replace-confirm for an existing name, "Make this my default" → `CFG.WORKSPACE$` = the new id (saved by `MAIN_shutdown`'s `CONFIG_save`), "Don't show again" → `WORKSPACE_SAVE_PROMPT=0`. The harness pins `WORKSPACE_SAVE_PROMPT=0` so no other test blocks on exit; `tests/workspace-current-exit.sh` turns it on. Menu: rules after Default/Current, before SWITCHER and before RELOAD (`MENUBAR_register_submenu_divider`; generic flyouts size / hover / click by `MENUBAR_gen_row_h%`).
- **Save Current Layout (2405) / Update Workspace From Layout (2406):** `WSC_capture_layout` writes every panel's SHOW/HIDE, the docks, the columns and the layers width into the WSC store (buttons, menus, keys, options, [START] stay); `WSC_save_and_use` saves, re-applies the workspace and cancels its `[START]`.
- **`[WINDOWS]` (2026-11-14):** the floating native windows' places + sizes, as DRAW.cfg keys (all of `WS_window_keys$` except docked windows since 2026-11-14 (was `DOCK_native_cfg_lines$`: shown + floating ones only) - PREVIEW_X/Y/W/H, COLOR_MIXER_X/Y, ADV_COLOR_PICKER_X/Y, COLOR_SPACE_3D_X/Y, PEN_PANEL_X/Y, ANIM_PANEL_X/Y, SWATCHES_X/Y/W/H, BROWSER_POS_X/Y + BROWSER_WIDTH/HEIGHT). `WS_apply%` appends them to the `WS_OPT_*` list, so the `[OPTIONS]` machinery does the rest (origs, guard, restore); `WS_WIN_TOUCHED` then runs `DOCK_native_from_cfg` after the apply and after `WS_restore` (window inits read CFG once). `WS_capture_option_origs`' scratch save skips the `--option` guard too (`CFG_cli_guard_begin` exits on `WS_GUARD_BYPASS`), else an `--option` key's orig was the file's value, not the live one.
- **Panel state (`[PANELS]`, 2026-11-14):** while a workspace is active, EVERY panel key (`WS_panel_keys$`: the 16 panel scales, Drawer bin cols / mini palette, layer thumbnails, charmap zoom / cells per row, workflow bar, Lock Layout, the color strip's rows / columns / chip size, Preview zoom / follow / mode / picking / quick look / reference image, Mixer MORE, the Advanced Color Picker's options, the 3D view, Swatches set / columns / view / cells, Browser view / zoom / sort / preview, X-sheet, lightbox strip) and every window key (`WS_window_keys$`) is in the `WS_OPT_*` overlay - `WS_OPT_KIND` = `WS_OK_PANEL` / `WS_OK_WINLIVE` (followed live) next to `WS_OK_OPTION` / `WS_OK_WINDOW`; a key the workspace has no `[PANELS]` value for takes the live one (VAL = ORIG, not applied). So the guard keeps DRAW.cfg the user's, `WS_restore` puts the user's back, and `WS_panels_push` makes the panels take CFG (preview fields, mixer relayout, ADVCP shade config, C3D_set_*, SWP_load_set, BROWSER_apply_defaults + thumb reload, then `SCREEN_compute_layout`); `WS_panels_pull` copies the state that lives in structs until exit (preview zoom / follow, the browser's FD_CFG) into CFG first. **Change → workspace: see "Remember the whole layout" below** (the per-key `WS_panels_save` is gone). Forced looks: `WS_restore` (before leaving), `WS_exit_prompt`, `MAIN_shutdown`. Stock Default (no workspace): changes go to DRAW.cfg as before. `WSC_capture_layout` writes all of `[PANELS]` (`WSC_capture_panels`). Limits raised: `WS_MAX_OPTS` 256, `WS_MAX_KV` / `WSC_MAX_KV` 512. `WS_apply%` re-finds its index after `WS_restore` (a save rescans the list). Dump: `WSPN on saves drawerCols editbarScale palRows palPerRow chipH chipW previewZoom swatchCols`. Test: `workspace-panel-state.sh`. Also kept since 2026-11-14 (later): the preview's pan, the strip's min rows / row threshold, Swatches live edit / overwrite, the workflow buttons (Rick: "i want the workflow bar to be saved per workspace!" - so a click on one can change the bar), Lightbox on/off, Snap Panel Edges, every Pen Pressure setting, the Browser's hidden files + pane minimum widths. Not kept: folders / last dirs, Settings-only sizes (charmap cells, browser font / icon scale, group indent).
- **All floating:** a layout with every docked panel floating has no column; `DOCK_load_snapshot` keeps it custom when a docked panel has a `FLOAT.` line (before 2026-11-14 it built the default tree and re-docked everything - on Save As, recall and reload). Test: `workspace-all-floating.sh` (stock-Default mode, also checks [WINDOWS]); dump line `WSA <active id>`.
- **Remember the whole layout (2026-11-14, Rick: "EVERY SINGLE PANEL ... MUST BE REMEMBERED ... RECALLED just the way they were REMEMBERED"):**
  - **Everything is the workspace's while it is active.** `WS_apply%` marks every `WS_EL_*` element and every `WS_DK_*` side TOUCHED (`WS_EL_NAMED` / `WS_DK_NAMED` = the file names it, so apply sets it; an unnamed one starts as it is). So the guard keeps every visibility / side out of DRAW.cfg, `WS_restore` puts all of them back, and `WS_apply_dock` always snapshots the user's tree (`WS_DOCK_TOUCHED`) - a panel shown, hidden or moved in a workspace never leaks into Default. (A variable can't share a SUB's name: `WS_EL_SET` collided with `WS_el_set`.)
  - **Sides come from the tree.** `WSC_capture_layout` writes `[CHROME] *_DOCK` from `WS_dk_side_now$` (`DOCK_side_now%` of `WS_dk_panel%`), not the side keys (they were stale: files said `LAYER_PANEL_DOCK=LEFT` with layers in `RIGHT.1`). After a `[DOCK]` tree loads, `WS_dock_keys_from_tree` sets each docked panel's side key from it (`DOCK_key_set`; the toolbox flyouts read `CFG.TOOLBOX_DOCK_EDGE`) - guarded, so DRAW.cfg keeps the user's.
  - **One comparison, one save.** `WS_layout_state$` = the whole capture (`WSC_capture_layout` into a borrowed WSC store: visibility, sides, columns, layers width, `[DOCK]`/`[FLOAT]`, `[WINDOWS]`, `[PANELS]`) as sorted-insensitive `K=V` lines. `WS_panels_poll` compares it with `WS_STATE_SEEN` (first look after an apply = baseline) and on any difference `WS_remember_save` writes the whole capture into the active workspace (`WSC_load` + capture + `WSC_save%` + `WS_resolve%`; buttons / menus / keys / options / [START] untouched; the WSC store put back) and sets `WS_EL_WANT` = what shows now. Looks are wanted after a click / drag / wheel, a `CONFIG_save` and **every `CMD_execute_action`** (keyboard / palette commands), at least 6 frames apart with no button held; forced at `WS_restore`, the exit prompt and `MAIN_shutdown`.
  - **F11 / Shift+F11 are not layout.** `WS_el_vis_kept%`: F11-hidden counts as `UIALL_VIS`, a Shift+F11-revealed element as hidden. `WSC_capture_layout` no longer calls `UIALL_show`.
  - **`[WINDOWS]` = every window, shown or not** (`WSC_capture_panels`: `WS_window_keys$` from the scratch save, then `DOCK_native_cfg_lines$` for the live ones), **except docked ones** (`WS_window_key_docked%`): their place is `[DOCK]`, and the cfg's floating place is whatever the dock wrote last (made `SWATCHES_Y` drift on a round trip).
  - QA dump: `<DOCK_DUMP>.wsreq` → `<DOCK_DUMP>.ws` (`WS_state_dump_check`, `dk_ws_state FILE` in dock-lib.sh; ends `WSA=<id>`). Test: `workspace-recall-all.sh` (A changed → B → Default (= its own, DRAW.cfg unchanged) → A exact → restart exact → F11 + quit + restart exact); run it in user-profile mode too.
- QA: `tests/dock-resize.sh` (Default, greps QA/DRAW.qa.cfg). **The harness gives every normal-mode test its own empty `WORKSPACES_DIR`** (`adapter_pre_launch`, `$RESULTS_DIR/draw-qa-workspaces`) unless it pins one - a workspace now saves itself, and DRAW's user workspaces folder is outside the QA config (profile mode uses its copied data dir).

## The dock tree in workspaces (branch `docking`, 2026-10)

Full guide: `.claude/instructions/draw-docking.md`.

- **`[DOCK]` / `[FLOAT]`** sections (`WS_apply_dock`): loaded as a custom tree over the user's; `WS_DOCK_USER_SNAP` + `WS_DOCK_TOUCHED` put the user's tree back in `WS_restore`. A workspace with `*_DOCK` keys but no `[DOCK]` gets the default tree (built from the keys) so its sides apply.
- **Saves:** any hand arrangement in a workspace → `WSC_save_dock` (user copy of a built-in); `WSC_capture_layout` (2405/2406) writes `[DOCK]` via `WSC_store_dock DOCK_snapshot$` (a `CUSTOM=0` snapshot stores none). Configurator tab **Dock** (`WSC_TAB_DOCK` = 6, appended so older tab indices stay): kv rows for `DOCK.*` / `FLOAT.*` + Use current / Default.
- **Side keys vs tree:** in Default nothing may write dock keys from the tree (a mirror would leak into DRAW.cfg). In a workspace every `WS_DK_*` key is guarded, so `WS_dock_keys_from_tree` may (see "Remember the whole layout"). Readers use `DOCK_side_now%`; writers call `DOCK_side_request` after setting a key.

## Capture

- `_SCREENIMAGE` is Windows-only (GLFW_TODO elsewhere → blank). [Linux] Plasma 6.3 Wayland via XWayland: `spectacle -b -n -f -o` (0.47 s, 4K); `grim` refused by KWin; `_SCREENHIDE` unmaps the XWayland window during the delay.
- Tests use `CAPTURE_BACKEND=COMMAND` + `QA/fixtures/fake-capture.sh` (fixed 640×400 PNG) so they never touch the display.
- The picker draws on screen 0 at native pixels (`_MOUSEX` is native), text at UI scale (`CAP_text`).
- Capture stashes a named/changed document to `<cache>/capture-previous.draw` (+ zoom/pan) instead of the discard prompt; Done reloads it.
- A cold `--capture` launch is one-shot (`CAP_ONE_SHOT`): no splash (DRAW.BAS), Done → `ANN_EXIT_FRAMES` (10 frames so a clipboard manager can take the image) → action 212; Esc in the picker → exit too. Capture/Done workspace switches use `WS_NO_REMEMBER` (not the next launch's workspace). Test: `DRAW_EXTRA_ARGS=--capture ./draw-qa.sh tests/capture-oneshot.sh`.
- `--capture` with a live instance: `INSTANCE_bootstrap` posts `capture.request` to that slot's mailbox *before claiming a slot* and exits; `CAP_tick` polls (`INSTANCE_take_request%`, ~0.3 s).

## Workflow buttons (`GUI/WORKFLOW`)

- **List:** `CFG.WORKFLOW_BUTTONS$` (comma ids, default `sprite,animate,scene,annotate`, saved
  as `NONE` when empty) is parsed by `WF_sync` whenever the string changed (signature compare
  against `WF_PARSED`; no dirty flag - CONFIG.BM is included before WORKFLOW). Up to `WF_MAX` = 8.
- **Labels:** `WS_INFO.short` from `[WORKSPACE] SHORT=` (reset in `WS_list_add`, Default and
  Current), else the title, upper-cased; an id with no workspace shows `?ID` and a click says so.
- **A dock panel of its own (2026-11-14, P12):** `DP_WORKFLOW` = 8, the last dock panel (the
  native windows moved up one: `DP_PREVIEW` = 9 ... `DP_SWATCH` = 16, `WZ_TBED` = 17,
  `PSURF_N` = 8), `REGION_WORKFLOW` = 34, `DP_H_FIXED`, bordered, tall like the organizer.
  Default tree: first in the toolbox's stack (`workflow | toolbox | organizer | drawer`); it
  shares the toolbox's top frame row (the toolbox rect starts on the panel's last row).
  Shown = `SCRN.showToolbar% AND WF_on%` (hides with the toolbox, as the strip did).
  `DOCK_apply_rect` → `WF_place x, y, uw, uh` (its units, GUI/PANEL-SURFACE); width units =
  `WF_min_w%` (one square letter button + frame) or the toolbox's width in its column;
  `WF_max_w%` = every button in one row (`WF_LBL_MAX` 48). `WF_cols%(w)`: labelled columns of
  at least `WF_LBL_W` 24 units, rows balanced; **one column = first letters** (`WF_shown_label$`).
  `WF_height%(w)` = rows x (button + 1) + 1. `TOOLBAR_reflow` counts its height / min width
  while it is in the toolbox's column (`DOCK_with_toolbox%`). Scale: `WORKFLOW_PANEL_SCALE`
  (Auto = the display scale), Settings > Panels > Panel Scale.
- **Input:** `WF_is_over_area%(rawX, rawY)` (DOCK_live / WZ_blocked / PSURF footprint) gates
  everything; MOUSE.BM calls `WF_click%` / `WF_right_click%` in the toolbar/organizer/drawer
  chain and **EXIT SUBs** after them (a workspace switch relayouts - no later panel may see
  that press); `WF_track` (POINTER.BM) keeps the hover in viewport px.
- **Old arrangements:** a custom tree saved before the panel existed has no place for it, and a
  dock panel that is neither docked nor floating is never drawn. `DOCK_adopt_new_panels`
  (from `DOCK_layout`, custom trees only) puts it in a slot above the toolbox, over the
  toolbox's window when that floats, else a column of its own on the left; your own
  arrangement is then saved at once (`DOCK_ADOPT_SAVE` → `CONFIG_save` at the end of the
  layout), a workspace's `[DOCK]` is not (it adopts again on each apply).
- **Click:** `WF_press n` = `WS_action WS_ACT_SLOT0 + k`, or `WS_ACT_LEAVE` when the button is the
  active non-default workspace (lit-again = back to Default, PERSONAS Q1).
- **Right-click menu** reuses the dock handle menu: `WF_MENU_NEXT = n` (the button; 0 between
  the buttons = the panel's plain handle menu) then `DOCK_menu_open DP_WORKFLOW`;
  `DOCK_UI.menuWf` routes `DOCK_menu_build` / `DOCK_menu_do` to `WF_menu_build` / `WF_menu_do`
  for values >= 3901 - the button menu's Float / Dock Back / Scale rows (`DOCK_ACT_*`) fall
  through to the dock's own handler. Values: 4000 + WS_LIST index (set), 3901 add (first unused
  named workspace, not Default / Current), 3902 remove, 3903 hide, 3904 / 3905 move. Every
  change → `WF_save_list` (`CONFIG_save`).
- **Dump (viewport px):** `WF on n x y w h active cols laidOut` + `WFB i x y w h lit id label
  shown` in the dock dump (`WF_dump$`); the panel's `P workflow` / `SLOT` lines as any panel.
- **QA:** the harness pins `WORKFLOW_BAR=0` (qa-harness `_qa_cfg_overrides`) so existing toolbox
  coordinates hold; `workflow-buttons.sh` and `workflow-panel.sh` (dock / float / one column /
  Scale / old-tree adoption) turn it on. Tests of built-in workspaces must pin
  `WORKSPACES_DIR` to an empty folder (`/tmp/draw-qa-ws-none`): the harness does not isolate
  XDG_DATA_HOME, and a user workspace with a built-in's id replaces it (memory
  `qa-user-workspaces-override-builtins`).
- **Sprite / Scene** (`ASSETS/WORKSPACES/sprite|scene.workspace`): contents in PLANS/PERSONAS.md
  Q4; `workspace-sprite-scene.sh`. `[MENUS] ROOTS=` knows `ANIM` (WS_apply_menus' list; before,
  a ROOTS naming only ANIM was "names no menu" and ignored).

## Action ids

| Range | Owner |
|-------|-------|
| 2400 switcher · 2401 configure · 2402 folder · 2403 reload · 2404 leave · 2405 save current layout as · 2406 update from layout · 2410-2441 workspace slot n | WORKSPACE-APPLY |
| 2660 View > Workflow Buttons (show / hide) · 2661-2668 Workflow Button 1-8 | WORKFLOW |
| 2450 capture · 2451 quick save · 2452 done · 2453 arrow · 2454 highlighter · 2455 redact · 2456 callout · 2457 restart numbers | CAPTURE / ANNOTATE |

## Gotchas met on the way

- QB64 identifiers are case-insensitive: `SUB WSC_tab_panels` collides with `CONST WSC_TAB_PANELS` ("Name already in use"), and `DIM SHARED EDITBAR_COLS` with `FUNCTION EDITBAR_cols%`. `chain` and `base` are reserved too.
- `--option KEY=VALUE` used to be persisted by the first `CONFIG_save` (and leaked QA-OPTIONS into later tests in a run). Now `CFG_cli_guard_begin/_end` write the file's own value for overridden keys.
- Command palette: `CMD_execute_selected` hides the palette *before* running the action (a trailing `CMD_hide` closed a palette the action re-opened — Workspace Switcher). Do NOT also `SCREEN_render` there: rendering mid key-handler broke Stroke Selection from the palette.
- [Linux] QA drags: DRAW idles at 15 fps; the harness's quick `drag` can put press + move in one frame (zero-length line). Use a slow multi-frame drag (`mouse_down`/`hover`/`mouse_up`) for shape tools.
