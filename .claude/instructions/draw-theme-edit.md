# Theme Edit mode + UIKIT inspector

Spec and plan: `PLANS/THEME-EDIT.md`. This file is the working guide.

## Layers

| Layer | Files | Rule |
|---|---|---|
| UIKIT (library-to-be) | `GUI/UIKIT/UIP.BI/BM` (`UIP_` property + component registry, node tree `UIP_N`, value parse / normalise / nudge, theme-file patch-save, backups, dir copy), `GUI/UIKIT/UIP-INSPECTOR.BI/BM` (`UIPI_` devtools panel: ELEMENTS tree + properties, Scale / dock menu, state string) | **Reads no DRAW global.** Input comes in as parameters, results go out as events (`UIPI_next_event$`). Destined for `QB64_GJ_LIB/UIKIT`. |
| Generated | `CFG/THEME-PROPS.BM` (`THEMEP_register_all`, `THEMEP_get$`) | Written by `DEV/theme-props-gen.py` from `THEME_apply_kv%`. **Never hand-edit.** `make` fails when stale. |
| DRAW adapter | `CFG/THEME-EDIT.BI/BM` (`THEMEED_`), `native/file_stamp.h` | Defines the host contract `UIP_host_get$` / `UIP_host_set%`, components, CLI, hooks. |

## Adding a theme key

1. Add the `CASE "KEY": THEME.field = ...` to `THEME_apply_kv%` in `CFG/CONFIG-THEME.BM` (the one
   key list; file loading and live editing both go through it).
2. `python3 DEV/theme-props-gen.py` - regenerates `CFG/THEME-PROPS.BM`. The type is inferred from
   the CASE line (`VAL` -> INT/REAL, `THEME_parse_rgba` -> COLOR, `val$` -> TEXT, re-typed
   IMAGE / FONT / SOUND from the DEFAULT sample value's extension); the section and description
   come from `ASSETS/THEMES/DEFAULT/THEME.CFG` and the `CONFIG-THEME.BI` field comment.
3. A new panel / section the inspector should map to: `THEMEED_register` (component sections and
   image folders) and `THEMEED_comp_for_region%` (REGION_ -> component).

## Units

UIKIT speaks **window px** (screen 0 = viewport x `SCRN.displayScale%`): the host passes
`MOUSE.WIN_X/Y`, `UIPI_layout SCRN.w * ds, top * ds, bottom * ds`, node boxes x ds. The panel
draws in panel px, `UIPI.sc` window px each (Scale menu; Auto = `UIPI.autoScale` = the display
scale). QA at Auto with DISPLAY_SCALE 2: 1 panel px = 1 viewport px.

## Hooks (one line each - keep them that way)

`RENDER_gui_elements` (inside its `IF GUI_NEEDS_REDRAW%`) + the GUI-only path of `SCREEN_render`
(`THEMEED_regions_seen`, right after `POPUP_render_gui`), `TOOLTIP_update`
(`THEMEED_owns_pointer%`), `POINTER_build` (`THEMEED_pointer_cursor%`: resize cursors on the
panel's edges, the arrow on it), `CFG_cli_collect` / `CONFIG_apply_cli_overrides` (CLI, create-from-base before the first
`THEME_load`), `SCREEN_init` (`THEMEED_cli_dump`, exits), the 3 present paths of
`SCREEN_render` (`THEMEED_render_screen0` after `POPUP_reblit_to_screen0`), `POPUP_blocks_partial%`
(full presents while the panel shows), `MOUSE` (`THEMEED_mouse%` first), `KEYBOARD_input_handler`
(`THEMEED_keys%` first), `INPUT` (`THEMEED_typing%` -> `CTX_TEXT_ACTIVE`), `DRAW.BAS`
(`THEMEED_session_start`, `THEMEED_tick`, `THEMEED_shutdown`, file-arg skip of value flags).

## IMAGES order

`UIPI_add_folder` sorts by a key string: `"0" + y(5) + x(5) + NAME` for a file some node's `fls`
holds (`UIP_node_with_file%`), `"1" + NAME` otherwise; `UIPI.fileAZ` = plain A-Z. FILE rows carry
1 / -1 (on screen / not) in `UIPI_ROW_PROP` for the dimming. `UIPI_tree_changed` sets `rebuild` in
screen order, since the rows follow node positions. Only nodes with files count (toolbox / bar
buttons, layer icons and buttons, organizer widgets, text bar icons, flyout children, pattern bins).

## Everything on screen is editable (Rick's rule)

Picking uses the tree (`THEMEED_node_at%`: the smallest node with a box under the pointer - first
under `OVER` (open menus / popups, drawn over everything), else inside the hovered region's node;
the node's own `comp` wins over the region's). So to make a part inspectable, give it a node -
never a per-panel hit test. Two ways:

- **Computed** in `THEMEED_tree_region%` / `THEMEED_tree_extra` from the panel's own data, via
  `THEMEED_kid%(parent, key, label, dp, x, y, w, h, fls)` (dp = its `DP_*` surface: units ->
  `PSURF_rect_to_view`; 0 = viewport px). Done: toolbox slots, `BL_` bars (`THEMEED_tree_bar`),
  menu bar titles + `>>`, colour strip chips / arrows / palette name, organizer `ORG_WIDGETS`,
  workflow `WF_B*`, selection bar `SB_*`, text bar controls (`THEMEED_tree_textbar`: x / w from
  `TEXT_BAR.*BtnX/W`, line `TEXT_BAR_BY`, icons `THEME.TEXT_BAR_ICON_*`) + `TBDD_*` dropdowns,
  subtool flyout children, layers header / layer bar / 6 buttons.
- **Drawn parts:** the draw code says what it drew -
  `IF THEMEED.started THEN THEMEED_seen dst, pkey, nkey, label, x, y, w, h, fls` with dst the
  image it drew into (`_DEST`). The tree turns boxes into window px itself: `SCRN.GUI&` /
  `SCRN.CANVAS&` are viewport px; any other image through its last `HSC_put` (noted by
  `THEMEED_hsc_note` with the region it shows - every dock surface and native window passes
  there; Customize Toolbars notes its own `_PUTIMAGE`). `pkey` "" = the region it lands in;
  another part's key (same image) nests it; `"OVER"` = an overlay; `"R:<rg>"` = that region.
  `nkey` "" = `"D:" + label@x,y`. Hooked: `FPANEL_title_bar` (TITLE BAR + CLOSE), `_chip`,
  `_checkbox`, `_disclosure`, `_track`, `PSL_draw` (so Pen / Swatches / Animation / Customize
  Toolbars / Preview / Brushes / MyPaint settings get theirs for free), `POPUP_MENU_render` (box +
  items, `POP:x:y`), the menu bar dropdown (`MENU:DD` + rows), the palette menu (`PALMENU`), the
  status bar (`SB:*`), layer rows (`LR:<idx>` + `:EYE` `:LOCK` `:THUMB` `:NAME`), drawer bins
  (`DB:<slot>`), the Preview's minimize box.
- **Lifetime:** an image's parts are replaced the first time it is drawn into after a new render
  began (`THEMEED_GEN`, bumped by `THEMEED_seen_frame` at `SCREEN_render`'s top - which also
  drops `SCRN.CANVAS&`'s, where context popups draw every render). `SCRN.GUI&`'s go when the
  GUI is redrawn (`THEMEED_seen_gui`): parts of it (the status bar) are redrawn alone, so its
  parts are replaced by key instead; a part no longer drawn there is `THEMEED_seen_forget`. The
  menu bar's dropdown and the palette menu also check they are still open (the GUI may not be
  redrawn when they close). A key that changes size every frame churns the tree signature, and
  every change rebuilds the inspector's rows - give such a part a stable box (the status text
  spans to the bar's end).
- QA: the dock dump (`DOCK_DUMP=`) carries `TESTATE` (the inspector's box + state), `TEN <depth>
  <x y w h> <nfiles> <nkey> <label>` per node (window px) and `TEPICK` / `TEELEM` while picking.
- **Modal dialogs** (every `DIALOG_CTX` dialog - Settings, Image adjustments, Lospec, Kit, AI,
  ...) run their own loop, so the main loop's hooks do not run; the `DIALOG_*` helpers call
  Theme Edit's instead: `DIALOG_init` -> `THEMEED_dialog_begin` (depth + 1: `THEMEED_render_screen0`
  stays out of the background copy), `DIALOG_poll_mouse` -> `THEMEED_dialog_input%` (new GEN,
  Ctrl+Alt+`, the inspector's typing - `INKEY$`, then `_KEYHIT` drained so Enter / Esc do not
  close the dialog -, the pointer via `THEMEED_pointer%`; what it takes the dialog does not see:
  `mb1` / wheel zeroed, `mx` parked off-dialog and flipped -9999 / -10000 each frame so a dialog
  that skips idle frames (Settings) keeps drawing), `DIALOG_blit` -> `THEMEED_dialog_present`
  (maps the dialog image, events, tree, draws the inspector), `DIALOG_cleanup` ->
  `THEMEED_dialog_end` (its parts + map entry go). Parts: `DIALOG_draw_frame` = `DLG` under
  `OVER` (comp DIALOG) + `DLG:TITLE`; buttons / toggles / sliders / labels / dropdowns and the
  Settings widgets (`SW_seen`) + tabs go under `DLG`; Settings' scrolled rows are drawn into a
  scratch image and moved onto the dialog by `THEMEED_seen_rehome`. The inspector's **DIALOGS**
  button (the UIKIT host menu: `UIPI.hostBtn`, `UIPI_host_menu_add`, event `HOSTMENU <id>`)
  lists dialogs to open (`THEMEED_dialogs_menu`); the action runs at the next `THEMEED_tick`
  (never inside a modal loop) with picking on. The dock dump is not written while a dialog is
  up (main loop only), so QA cannot see dialog nodes yet.
- Not reached: message / input boxes and the file dialog (QB64_GJ_LIB, their own loops, no
  `DIALOG_*`). The bodies of the Color Mixer / Advanced Color
  Picker / 3D Color Space / Browser (QB64_GJ_LIB renders), the Swatches grid, the Pen graph,
  Customize Toolbars' rows, dock title strips / tabs, the command palette's rows and the menu
  bar's flyouts are their panel's node only. FPANEL sliders have no label of their own ("SLIDER"). Files a node shows
that the theme lacks are noted by `THEMEED_cmd_art$` (`THEMEED_SEED_*`) and made on EDIT by
`THEMEED_seed_make%`. Toolbox command slots are `TOOLBAR_BUTTON_ORDER(i) >= TB_CMD_BASE`; their
art falls back theme -> DEFAULT -> bar icon -> 16px art -> text tile (`TOOLBAR_draw_cmd_cell`).
Testing them needs a workspace with `cmd:` slots: `--option WORKSPACES_DIR=<dir> --workspace NAME`.
EDIT launches a second DRAW on the user's own config (`INSTANCE_launch_new_with_file`) - kill it.

## Gotchas met building it

- **QB64 names are case-insensitive across kinds:** an array `THEMEED_SEEN` and a SUB
  `THEMEED_seen` collide ("Name already in use") - the parts array is `THEMEED_PART`.
- **`WZ_TBED` = `HSC_ADVCP_MENU` = 22.** A slot number does not tell Customize Toolbars from the
  Advanced Color Picker's menu: `THEMEED_hsc_note` takes the region, worked out by the caller.
- **Ctrl+Alt+` hides the inspector when it is shown** (and shows it + starts picking when not):
  a script that presses it to "start picking" closes it instead.
- **Test runs keep the inspector's state beside the config in use** (`QA/DRAW.qa.cfg.theme-edit`,
  gitignored) - delete it to start docked right again. The user's own is
  `~/.config/DRAW/DRAW.cfg.theme-edit`; a `--config` run never touches it.

- **`REGION_BOUNDS_TABLE` is not a picture of the screen between renders.** It is cleared at the
  top of every `SCREEN_render`; only a GUI redraw re-registers every panel (a cursor-only frame
  leaves 2-3 entries). Read it right after the GUI is drawn (`THEMEED_regions_seen`), never from
  the main loop.
- **Arrow keys never reach `KEYBOARD_input_handler` through `_KEYHIT`** (drained earlier): use
  `_KEYDOWN` edges with your own repeat (`THEMEED_arrow_key&`).
- While the inspector is under the pointer, DRAW's tooltips are off and (tree focus) its
  shortcuts too (`THEMEED_typing%` -> `CTX_TEXT_ACTIVE`).
- Reserved names bit repeatedly in UIKIT code: `key`, `files`, `font`, `lines`, `base`, `names`
  (gotcha 20). The registry field is `pk`, not `key`.
- Hex colour CONSTs: suffix on the literal (`CONST UIPI_C_BG = &HFF202226~&`).
- `pending` = differs from the file's value (`UIP_PROP.saved`), not "was touched": revert and
  outside reloads (`UIP_reapply`) recompute it.
- The press that opens a field (double-click) must not also move the caret, or it kills the
  select-all and typed text is inserted mid-value.
- `THEME_reload_all` re-reads THEME.CFG, so any asset reload re-applies the pending dump after it.
- Testing by hand under Xvfb: hold clicks (`mousedown`, ~70 ms, `mouseup`) and hold hotkeys
  (`keydown ctrl alt grave`, 150 ms, `keyup`) - an instant `xdotool click` / `key` falls between
  frames and `_KEYDOWN` polling never sees it.

## Existing theme, other base

`THEMEED_cli_apply` (include time, window still hidden): `--theme-name X` that exists but was not
made from `--theme-edit-base B` -> `THEMEED_ask_theme$` asks on the terminal (N = `X-n` from
`THEMEED_variant$`, E, R -> y/N then `THEMEED_theme_move_aside$` renames the folder into
`ASSETS/THEME-BACKUPS/` and the name is created anew, Q -> `SYSTEM 0`, or a typed name; `native/cli_tty.h` `gj_stdin_isatty` /
`gj_stdin_getc`). No tty or unattended -> `X-n` silently (never R). Base comes from `.theme-base` (written on
create) else the THEME.CFG header path. The `--option THEME` entry `THEMEED_cli_collect` made is
rewritten to the chosen name. Test it with a pty (python `pty.fork`, `os.execvp`), never stdin
redirection - that is the no-tty path.

## Tests

`QA/tests/theme-edit-inspect.sh` (console dumps, create-from-base) and
`QA/tests/theme-edit-live.sh` (pick, unarmed wheel = no edit, click + wheel, SAVE + `.history`, revert, tree hover outline, Scale
1x + state file, hotkey hide). Geometry is derived from the `UIPI_*_H` constants and the 120px
default tree - update the test header if they change. The test removes
`QA/DRAW.qa.cfg.theme-edit` (the inspector's state) first and last.
