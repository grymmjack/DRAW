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

## The overlay contract (`WS_apply%` / `WS_restore`)

- **Snapshot → apply → restore.** Only elements the workspace names (`SHOW`/`HIDE`, dock `LEFT`/`RIGHT`, `[OPTIONS]` keys) are touched; `KEEP`/absent = untouched. Restore puts back the snapshot (visibility, `ManuallyHidden`, CFG `*_VISIBLE`, dock CFG + `dockSide`, option values).
- **Elements** (`WS_EL_*`, 16): menubar, toolbox, layers, edit/advanced bar, status bar, preview, color mixer, charmap, 3D color space, adv color picker, pen panel, browser, organizer, drawer, palette strip. Floating panels are switched through their own `*_toggle` (first-show init, auto-position) — but never through toggles that call `CONFIG_save` mid-apply.
- **Hides set `ManuallyHidden% = TRUE`** so `MOUSE_handle_ui_autohide_restore` never brings them back (gotcha #12).
- **DRAW.cfg never sees the overlay.** `CONFIG_save` brackets its write with `WS_cfg_guard_begin` / `WS_cfg_guard_end`: touched CFG fields get the user's snapshot values for the write, then the workspace's back. Option originals are captured by running `CONFIG_save` into a scratch file with `WS_GUARD_BYPASS` and reading the lines back (exact `CONFIG_apply_key%` text, no per-key getters). `MAIN_shutdown`'s live→CFG copies are covered because they go through `CONFIG_save`.
- **Drawer visibility lives in `.draw` files** (`DRAWER_save_state_binary`): it writes `WS_drawer_file_visible%`; loads/resets call `WS_on_drawer_loaded` so the hide survives a document change.
- **Hidden organizer** collapses to zero height (`ORGANIZER_render` still sets `panelX1..Y2`) so the drawer keeps its anchor; `ORGANIZER_is_over_area%` returns FALSE → every click/drag/hover gate is off.
- **F11**: `WS_f11%` runs first in action 403; when the workspace hides anything it toggles `WS_REVEALED` (fixed chrome always revealed, floating panels only if the user had them showing).
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
- **Save Current Layout (2405) / Update Workspace From Layout (2406):** `WSC_capture_layout` writes every panel's SHOW/HIDE, the docks, the columns and the layers width into the WSC store (buttons, menus, keys, options, [START] stay); `WSC_save_and_use` saves, re-applies the workspace and cancels its `[START]`.
- QA: `tests/dock-resize.sh` (Default, greps QA/DRAW.qa.cfg). Workspace saves write the user's workspaces folder, so they are only checked by hand with `XDG_DATA_HOME` pointed at a scratch dir.

## The dock tree in workspaces (branch `docking`, 2026-10)

Full guide: `.claude/instructions/draw-docking.md`.

- **`[DOCK]` / `[FLOAT]`** sections (`WS_apply_dock`): loaded as a custom tree over the user's; `WS_DOCK_USER_SNAP` + `WS_DOCK_TOUCHED` put the user's tree back in `WS_restore`. A workspace with `*_DOCK` keys but no `[DOCK]` gets the default tree (built from the keys) so its sides apply.
- **Saves:** any hand arrangement in a workspace → `WSC_save_dock` (user copy of a built-in); `WSC_capture_layout` (2405/2406) writes `[DOCK]` via `WSC_store_dock DOCK_snapshot$` (a `CUSTOM=0` snapshot stores none). Configurator tab **Dock** (`WSC_TAB_DOCK` = 6, appended so older tab indices stay): kv rows for `DOCK.*` / `FLOAT.*` + Use current / Default.
- **Side keys vs tree:** the overlay snapshots only the `WS_DK_*` keys a workspace touches, so nothing may write dock keys from the tree (a mirror would leak into DRAW.cfg). Readers use `DOCK_side_now%`; writers call `DOCK_side_request` after setting a key.

## Capture

- `_SCREENIMAGE` is Windows-only (GLFW_TODO elsewhere → blank). [Linux] Plasma 6.3 Wayland via XWayland: `spectacle -b -n -f -o` (0.47 s, 4K); `grim` refused by KWin; `_SCREENHIDE` unmaps the XWayland window during the delay.
- Tests use `CAPTURE_BACKEND=COMMAND` + `QA/fixtures/fake-capture.sh` (fixed 640×400 PNG) so they never touch the display.
- The picker draws on screen 0 at native pixels (`_MOUSEX` is native), text at UI scale (`CAP_text`).
- Capture stashes a named/changed document to `<cache>/capture-previous.draw` (+ zoom/pan) instead of the discard prompt; Done reloads it.
- A cold `--capture` launch is one-shot (`CAP_ONE_SHOT`): no splash (DRAW.BAS), Done → `ANN_EXIT_FRAMES` (10 frames so a clipboard manager can take the image) → action 212; Esc in the picker → exit too. Capture/Done workspace switches use `WS_NO_REMEMBER` (not the next launch's workspace). Test: `DRAW_EXTRA_ARGS=--capture ./draw-qa.sh tests/capture-oneshot.sh`.
- `--capture` with a live instance: `INSTANCE_bootstrap` posts `capture.request` to that slot's mailbox *before claiming a slot* and exits; `CAP_tick` polls (`INSTANCE_take_request%`, ~0.3 s).

## Action ids

| Range | Owner |
|-------|-------|
| 2400 switcher · 2401 configure · 2402 folder · 2403 reload · 2404 leave · 2405 save current layout as · 2406 update from layout · 2410-2441 workspace slot n | WORKSPACE-APPLY |
| 2450 capture · 2451 quick save · 2452 done · 2453 arrow · 2454 highlighter · 2455 redact · 2456 callout · 2457 restart numbers | CAPTURE / ANNOTATE |

## Gotchas met on the way

- QB64 identifiers are case-insensitive: `SUB WSC_tab_panels` collides with `CONST WSC_TAB_PANELS` ("Name already in use"), and `DIM SHARED EDITBAR_COLS` with `FUNCTION EDITBAR_cols%`. `chain` and `base` are reserved too.
- `--option KEY=VALUE` used to be persisted by the first `CONFIG_save` (and leaked QA-OPTIONS into later tests in a run). Now `CFG_cli_guard_begin/_end` write the file's own value for overridden keys.
- Command palette: `CMD_execute_selected` hides the palette *before* running the action (a trailing `CMD_hide` closed a palette the action re-opened — Workspace Switcher). Do NOT also `SCREEN_render` there: rendering mid key-handler broke Stroke Selection from the palette.
- [Linux] QA drags: DRAW idles at 15 fps; the harness's quick `drag` can put press + move in one frame (zero-length line). Use a slow multi-frame drag (`mouse_down`/`hover`/`mouse_up`) for shape tools.
