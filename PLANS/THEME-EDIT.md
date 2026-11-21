# THEME EDIT MODE

## IDEA

I would like the ability to hold down ctrl+shift+right click to edit any part of my theme that is present on screen. automatically load into DRAW the source image, let me edit it, then on save, automatically refresh it. 

this way I can make modifications very easily in use of the theme.

i would also like the ability to do this with non images, including all properties that area present in the editor that make the visual display.

colors, fonts, metrics, all of it. 

anything exposed for the control I am inspecting ... and I have a better idea for this than the CTRL+SHIFT+Right click.

Let's use `--theme-edit` [theme] [base-theme] --theme-edit-autosave-mins --theme-edit-keep-num-backups` switches/command line args. 

- which will expose a property panel that allows me to edit/inspect (like chrome devtools sorta), which if i press CTRL+ALT+~ it goes into inspect mode, and hovering over things, shows them in the inspector. clicking will let me focus that, and edit it.

if [theme] doesn't exist, create it from the base theme passed in or default theme if not passed a base theme. you would do this in advance before DRAW loads up to show the new theme. if the theme already exists the user would edit that one. this should also keep a running version control with auto-save

buttons for all the colors, fonts, sizes, metrics, and images to edit directly - ....

## NEW CLI ARGS

```
./DRAW.run \
  --theme-edit \                        # enable theme editor functions
  --theme-name my-new-theme \           # theme name to edit (if blank current theme chosen in .cfg)
  --theme-edit-base default \           # theme to base new theme on (if theme-name doesn't exist) / blank = curren theme chosen in .cfg -copy
  --theme-edit-autosave-mins 5 \        # blank = 0 = none. min = 1, max = 60
  --theme-edit-keep-num-backups 3 \     # blank = 0 = none. min = 1, max = 10
  --theme-edit-start-inspector \        # start the theme editor inspector on program start
  --theme-edit-inspect [id-name]        # name of theme component to dump it's propreties to CLI as key=val pairs
  --theme-edit-unattended \             # blank = 0 = no, or 1 for yes - let's AI know it's doing the editing
```

## THEME EDITOR FUNCTIONS

### INPSECTOR (CTRL+ALT+~)
- Panel that can be docked on any edge. 
- [OPEN THEME DIR] / [EDIT THEME FILE]
- Expose all properties that can be changed including:
  - Colors: foreground, background
  - Fonts: name, size, format style
  - Metrics: width, height, left, top. etc.
  - Alignments: left, center, right, top, middle, bottom
  - Padding: n
  - Margin: n
  - Images:  (clicking EDIT opens in DRAW keeping inspect mode on lets user make changes, and on CTRL-S auto-updates)
    - [EDIT]
    - Idle: [EDIT]
    - Over: [EDIT]
    - Down: [EDIT]
  - Change and update in realtime, just like chrome devtools
  - Double click to start editing
  - SHIFT+arrows = select text
  - SHIFT+CTRL+arrows = select word
  - CTRL-A = select all
  - Click off selection = deselect, or use arrows
  - Arrows = move cursor
  - BACKSPACE = delete left char
  - DEL = delete left char
  - Type, then enter
  - ESC = abort edit
  - MWHEEL = inc/dec val +/- 1 (after a click on the value - a plain wheel scrolls)
  - SHIFT+MWHEEL = inc/dec val +/- 10
  - MIDDLECLICK = reset to previous value on load (revert setting)
  - If there are choices in an ENUM or something present as dropdown menu/combobox
  - For inspector use TINY5 font

---

# PLAN (2026-11-21)

## Goals

1. **Theme Edit mode** in DRAW: inspect any part of the UI, see every theme property behind it,
   change it live, edit its images in DRAW, save with backups / autosave.
2. **The real goal behind it** (Rick 2026-11-21): DRAW's UI becomes a reusable QB64-PE UI library.
   Writing a theme editor forces the decomposition: every component named, every property typed,
   one API for "what is this thing and what can be changed about it". The editor is the first
   client of that API; other QB64-PE programs are the next ones.

So the work is split in two layers, and the line between them is the point of the exercise:

| Layer | Knows about | Lives in (now) | Moves to |
|---|---|---|---|
| **UIKIT** (library) | components, typed properties, theme files, the inspector widget | `GUI/UIKIT/` | `QB64_GJ_LIB/UIKIT/` once the API settles |
| **DRAW adapter** | `THEME.*`, `REGION_*`, CLI flags, DRAW's render / input pipeline | `CFG/THEME-PROPS`, `CFG/THEME-EDIT` | stays in DRAW |

**Rule:** nothing under `GUI/UIKIT/` reads a DRAW global (`THEME`, `CFG`, `SCRN`, `MOUSE`, `REGION_*`).
It talks to its host through two host hooks and plain parameters, the way `QB64_GJ_LIB/LAYOUT`
and `SWATCH` already do. That is what makes it liftable.

## UIKIT layer (host-independent)

### Property registry — `GUI/UIKIT/UIP.BI/.BM` (`UIP_`)

- `UIP_prop_add key, type, section, desc` - one row per themable value. Types:
  `COLOR` (R,G,B,A), `INT`, `REAL`, `TEXT`, `BOOL`, `IMAGE`, `FONT`, `SOUND` (file-valued text).
- Values cross the boundary **as strings** (the theme-file form). The host implements
  `UIP_host_get$ (key)` and `UIP_host_set% (key, val)`; QB64 has no function pointers, so these
  are a link-time contract (a host that uses UIKIT must define both).
- Change tracking per property: `orig` (value at session start - middle-click reverts to it),
  `pending` (changed since the last save), `UIP_dirty%`.
- Value helpers: `UIP_rgba_str$`, `UIP_rgba_parse~&`, `UIP_num_str$`, `UIP_nudge$` (wheel +/- on a
  number or on one channel of a colour).

### Component registry (same module)

- `UIP_comp_add% (id, title, sections, images)` - a component is a named part of the UI. It owns
  property **sections** (space-separated, matching the theme file's `[SECTION]`s) and **image
  folders** (relative to the theme root). `parent` gives the tree (TOOLBOX > BUTTON).
- An **element** is the specific thing under the pointer inside a component (one toolbox
  button): `UIPI_set_element label, files` - the host knows its own hit testing.

### Theme files — `UIP_cfg_save%`, `UIP_backup%`, `UIP_dir_copy%`

- Save **patches** the existing INI in place: a pending key's line keeps its alignment and gets the
  new value; a key the file lacks goes at the end of its `[SECTION]` (a new section at the end of
  the file). Comments and layout are kept.
- Backups: before each save the file is copied to `<theme>/.history/THEME.CFG.<yyyymmdd-hhmmss>`;
  only the newest N are kept (`--theme-edit-keep-num-backups`, 0 = none).
- `UIP_dir_copy%` - recursive copy (for "create theme from base").

### Node tree — `UIP_N` (same module)

The on-screen hierarchy, like devtools' Elements pane. The host fills it depth-first
(`UIP_node_add%(parent, nkey, label, comp, x, y, w, h, files)`, boxes in window px) and rebuilds
it whenever its screen changes; `UIP_node_sig$` lets it tell the inspector only when something
moved. `nkey` is a stable id, so the open / selected state survives rebuilds.

### Inspector widget — `GUI/UIKIT/UIP-INSPECTOR.BI/.BM` (`UIPI_`)

- **Units:** everything crossing the API is window px (screen size, pointer, `UIPI.x/y`, node
  boxes). The panel draws in its own px at `UIPI.sc` window px each - the **Scale** menu (Auto =
  `UIPI.autoScale`, the host's UI scale; or 1x - 6x in half steps, to 8x when Auto or the setting
  is larger - the same list as DRAW's own panels). `UIPI_draw_to dest` composites it.
- **ELEMENTS tree** above the properties (beside them when the panel is wide and short, docked
  top / bottom), with a draggable divider. Roots and their children start open, deeper nodes
  closed (a closed node shows its child count). Hover a row = the host outlines that node on
  screen; click = select (the properties pane shows its component, plus its own files as the
  ELEMENT); click the arrow or double-click = open / close; arrows (while the tree has focus and
  the pointer is on the panel) = up / down / close-or-parent / open-or-first-child. Picking on
  screen **reveals** the node (opens its ancestors, scrolls, selects) - `UIPI_tree_reveal`.
- **Panel menu** (right-click the title, or its scale button): Scale, Dock left / right / top /
  bottom / Float, Elements tree on / off, Close. A small UIKIT menu of its own (the ENUM
  dropdowns of phase 2 will reuse it).
- **Resize:** floating - any edge or corner (the far edge stays put; min 120 x 90 panel px);
  docked - the inner edge (dock width / height). The grabbed edge lights up; `UIPI_cursor_edges%`
  gives the host the `UIPI_RS_*` edges for a resize cursor (DRAW: `THEMEED_pointer_cursor%` in
  `POINTER_build`, which also shows the arrow anywhere on the panel).
- **State:** `UIPI_state$` / `UIPI_state_load` (edge, scale, dock sizes, tree on / size, float
  rect, IMAGES order); the `STATE` event says when to save it.

- Renders into any image the host gives it; input is passed in as local coordinates and button /
  wheel / key state; results come back as an **event queue** (`UIPI_next_event$`: `SAVE`,
  `OPENDIR`, `EDITCFG`, `EDITIMG <path>`, `EDITPROP <key>`, `CHANGED <key>`, `PICK 1|0`,
  `TAKECOLOR <key>`, `GIVECOLOR <key>`, `CLOSE`) the host acts on. Docking is the widget's own
  state (`UIPI.edge`), not an event. The widget never launches, saves or reloads anything itself.
- Fixed dark devtools look, **not themed by the theme being edited** (a broken theme must never
  make the editor unreadable). Font: Tiny5 (proportional; columns are measured with `_PRINTWIDTH`).
- Layout: title + edge buttons (L R T B F) / toolbar (INSPECT, SAVE, DIR, CFG, ALL) / component +
  element line / filter box / scrolling property list (section headers, rows) / status line.
- Editing (the spec above): double-click a value -> text field (`QB64_GJ_LIB/TEXT_INPUT`: Shift+arrows,
  Ctrl+Shift+arrows, Ctrl+A, Backspace / Del, Enter commits, Esc aborts, click off = commit);
  wheel = +/-1, Shift+wheel = +/-10 (over a colour channel: that channel) - **only after a click on
  the value** (it arms, outlined, until the pointer leaves the row or another press; `UIPI.wheelRow`),
  so scrolling the list never edits what passes under the pointer; middle-click = revert;
  BOOL rows toggle on click. Image rows: [EDIT].
- Colour rows: swatch + `R G B A`, wheel per channel; values also typed as `#RRGGBB[AA]`.
  Left-click the swatch = `TAKECOLOR` (DRAW sets it from the FG), right-click = `GIVECOLOR`
  (DRAW makes it the FG).
- Row markers: `*` = differs from the theme file (pending save; reverting or setting the saved
  value back clears it); name in amber = changed since the session started.

## DRAW adapter

### Properties — `CFG/THEME-PROPS.BI/.BM` (GENERATED)

`DEV/theme-props-gen.py` reads the loader's `SELECT CASE` in `CFG/CONFIG-THEME.BM` (the one
authoritative key list: 640 keys), the field comments in `CONFIG-THEME.BI` and the sections /
comments / sample values of `ASSETS/THEMES/DEFAULT/THEME.CFG`, and writes
- `THEMEP_register_all` - every key with type, section, description;
- `THEMEP_get$ (key)` - the live value as theme-file text (the inverse of the loader).

The setter is the loader itself: the `SELECT CASE` moved out of `THEME_load_theme` into
`THEME_apply_kv% (key, val)`, so file loading and live editing are the same code path. **Re-run
the generator after adding a theme key** (the only manual step; `make` runs
`theme-props-gen.py --check` and fails on a stale file).

### IMAGES order

A component's IMAGES rows default to **screen order**: by where the node using each file sits
(`UIP_node_with_file%` over the node tree - top to bottom, left to right), then the files no node
uses, A-Z and dimmed. The SCREEN / A-Z button on the IMAGES header (or IMAGES IN SCREEN ORDER in
the title menu) switches; kept as `FILEAZ=` in the inspector state. Hovering an image row outlines
the node using it and the status line names it (`text.png - BUTTON TEXT`, or NOT ON SCREEN).

### Session — `CFG/THEME-EDIT.BI/.BM` (`THEMEED_`)

- **CLI** (flags above). `--theme-name X` acts like `--option THEME=X` (never saved into DRAW.cfg,
  via the `CFG_cli_*` guard). Missing theme -> copied from `--theme-edit-base` (else the current
  theme, else DEFAULT) **before** the first `THEME_load`, so DRAW opens already wearing it.
  A created theme gets a `.theme-base` file naming its base.
- **Name taken by another base.** `--theme-name X --theme-edit-base B` where X exists but was not
  made from B (its `.theme-base`, else the `ASSETS/THEMES/<name>/THEME.CFG` header line a copy
  keeps from its source): on a terminal DRAW asks before the window opens - **N** (Enter) edit
  `X-2` (the first `X-n` made from B, else the first free `X-n`, created from B), **E** edit X as
  it is, **R** replace X with a fresh copy of B (asks y/N; the old X is *moved* - one rename, nothing
  deleted - to `ASSETS/THEME-BACKUPS/X-<yyyymmdd>-<hhmmss>/`, beside THEMES so it stays off the
  theme list; gitignored), **Q** quit, or type a new name. No terminal (stdin or stdout not a tty) or
  `--theme-edit-unattended`: takes `X-n` without asking - never a replace. The inspector's status line then says
  `X IS FROM A - CREATED / EDITING X-2 FROM B`. No `--theme-edit-base`: X is edited, no question.
- `--theme-edit-inspect ID` prints `KEY=VALUE` for a component id, a section or one key, and exits
  (window never shown; works headless). `ALL` dumps everything; `COMPONENTS` lists the ids.
- `--theme-edit-unattended`: no confirmations, autosave on exit, events also logged as
  `THEMEED ...` lines (for an AI or a script driving the edit).
- **Hooks into DRAW** (each one line): `RENDER_gui_elements` + the GUI-only path of
  `SCREEN_render` (`THEMEED_regions_seen`), `TOOLTIP_update` (no tooltips under the inspector),
  `MOUSE_process_frame%` (inspector first),
  `KEYBOARD_input_handler` (Ctrl+Alt+` shows the inspector straight into picking / hides it;
  Esc ends picking; editing takes the keys),
  `INPUT_update_context` (`CTX_TEXT_ACTIVE` while typing), the three present paths in
  `SCREEN_render` (`THEMEED_render_screen0` after `POPUP_reblit_to_screen0`, so it is above
  everything), main loop `THEMEED_tick`, `MAIN_shutdown`.
- **Live apply:** colours repaint (`INVALIDATE_scene`); metrics also relayout; images / fonts /
  cursors go through `THEME_reload_all` - which re-reads THEME.CFG, so the session re-applies its
  pending edits right after (edits survive an asset reload).
- **Elements tree from the screen:** `THEMEED_tree_build` (twice a second while shown, and on
  every pick) - WINDOW > MENU BAR, LEFT DOCK > panels, CANVAS > checker / guides, RIGHT DOCK >
  panels (TOOLBOX / EDIT BAR / ADVANCED BAR > every button - tools **and** the commands Customize
  Toolbars placed, boxes via `PSURF_rect_to_view`), COLOR STRIP, STATUS BAR,
  FLOATING > windows, OVERLAYS > menus / dialogs / tooltip. Docked panels go left / right by their
  centre. **Source:** `REGION_BOUNDS_TABLE` is cleared at the top of every `SCREEN_render` and only
  a GUI redraw fills it all in (cursor-only frames leave most panels unregistered), so
  `THEMEED_regions_seen` copies it right after the GUI is drawn (both render paths) and
  `THEMEED_regions_merge` adds the overlays drawn later at present time.
- **Inspector state** is kept in `<config>.theme-edit` (beside the DRAW config in use).
- **Hover -> component:** `REGION_hit_test%` -> component (table in `THEMEED_comp_for_region%`);
  the element is the **tree's** smallest node under the pointer - an open menu / popup first, else
  inside that region (`THEMEED_node_at%`), its component the node's own - so whatever gets a node
  is pickable, revealed and editable, with no per-panel hit test. The element's box (else the
  region's) is outlined.
- **Every part is a node.** Worked out from a panel's data (`THEMEED_kid%`: toolbox / bar
  buttons, menu titles, colour chips, organizer widgets, workflow / selection bar / text bar
  controls, flyout children, layers header / bar / buttons) or said by the draw code as it draws
  (`THEMEED_seen dst, pkey, nkey, label, x, y, w, h, fls`: floating-panel title bars / close boxes
  / chips / checkboxes / sliders, panel sliders, popup menus and their items, the menu bar's
  dropdown, the palette menu, status bar parts, layer rows and their icons, drawer bins). Boxes
  are mapped to window px from the image drawn into (the GUI / canvas, or a panel / window
  through its last `HSC_put`), so a part drawn at any Scale, docked or floating, lands right.
- **Rule: everything on screen is editable** (Rick). Command buttons list the theme-path art even
  when the button falls back to DEFAULT's, a bar icon or a text tile (`THEMEED_cmd_art$`: toolbox
  `IMAGES/COMMANDS/TOOLBOX/<slug>.png`; bars their own icon file, else `IMAGES/COMMANDS/<slug>.png`).
  A missing file shows **NEW:** and EDIT makes it (`THEMEED_seed_make%`): DEFAULT's copy, else the
  art drawn now - toolbox art centred unscaled in the smallest 11 x k square (toolbox art is
  stretched to the cell, so that is pixel-exact at k x). The theme reload (`BL_free_tiles`) then
  picks up the saved file.
- **Image editing:** [EDIT] opens the PNG in a new DRAW window (`INSTANCE_launch_new_with_file`);
  the session watches that file (mtime + size, `native/file_stamp.h`) and on change reloads the
  theme's images (`THEMEED_reload_assets`). Ctrl+S in the other window = the update. THEME.CFG
  itself is watched too, so [CFG] (edit in a text editor) reloads on save.
- **Autosave** every N minutes while dirty (`--theme-edit-autosave-mins`, 0 = off, 1-60).

### Why the inspector is an overlay, not a dock panel (yet)

Docking "on any edge" is offered by the widget itself (L / R / T / B / float). A real `DP_` dock
panel would put a new panel into every saved dock tree (`DOCK_adopt_new_panels`) and into the
dock QA baselines, for a mode most runs never enable. The overlay touches nothing outside
theme-edit mode. Phase 3 revisits it once UIKIT owns panels too.

## Phases

| Phase | Scope | Status |
|---|---|---|
| 1 | Generator + `THEME_apply_kv%`; UIKIT props / components / theme files / inspector; DRAW session: CLI, create-from-base, dump, overlay inspector, hover / pick, editing, save + backups + autosave, image edit + file watch | **this branch** |
| 2 | Finer elements: per-button for edit / advanced bars, layer rows, menu items; ENUM types (`TOOLBAR_x` = L / R / n, alignments) with a dropdown; font picker; history browser (restore a backup); undo of property edits | next |
| 3 | **Library extraction:** component inventory doc (every DRAW panel, its parts, its properties - generated from the registry), move `GUI/UIKIT` to `QB64_GJ_LIB/UIKIT`, a standalone demo program that themes a few widgets with the same inspector | after 2 |
| 4 | Decompose DRAW's widgets onto UIKIT one by one (buttons, sliders, lists, title bars, menus - `FPANEL_*`, `DIALOG_draw_*`, Settings widgets are the candidates), each reading its look from registered properties instead of `THEME.*` fields directly | long-term |

## Testing

- `DEV/theme-props-gen.py --check` (run by `make`): the generated file matches the loader.
- `QA/tests/theme-edit-inspect.sh` (console, no window): COMPONENTS / a component / ALL / one key
  dump, an unknown id exits 2, `--theme-edit-base DARK` makes a byte-identical copy that is the
  theme loaded.
- `QA/tests/theme-edit-live.sh`: new theme from DEFAULT with the inspector docked right; the tree
  has menu titles, status swatches, colour chips, layer rows + icons, layer buttons, toolbox
  buttons (dock dump `TEN` lines); picking a status swatch names it (`TEPICK`); pick the canvas,
  wheel GRID_SIZE_X, SAVE (THEME.CFG + `.history/`), middle-click revert + SAVE, an open popup's
  items are in the tree, Ctrl+Alt+` hides the panel.
- By hand (2026-11-21, Xvfb): typed hex colour + Enter, wheel per channel, dock L / T / B / F,
  THEME.CFG edited outside -> reloaded live. Round trip: load -> `THEMEP_get$` for DEFAULT and
  DARK reproduces every value (one cosmetic diff: `SMART_GUIDES_PATTERN` 61680 is printed as the
  same 16-bit pattern -3856).

## Status / known limits (phase 1)

- Image [EDIT] -> new DRAW window -> save -> reload is wired but was **not exercised under test**
  (launching a second instance from the harness was avoided); the file watch itself is the same
  poll that reloads THEME.CFG, which is tested.
- Not yet exercised: TAKECOLOR / GIVECOLOR (swatch clicks), autosave timer, save-on-exit with
  `--theme-edit-unattended`, DIR / CFG buttons (they open the OS file manager / editor).
- Font keys apply on the next start (DRAW loads its fonts once); the inspector says so.
- The overlay covers whatever is under it on its edge; DRAW does not lay out around it (dock it
  on the other side, or float it, to see a panel it covers - the tree outline is drawn over it).
- Modal dialogs: Theme Edit runs inside every `DIALOG_CTX` dialog (Settings, image adjustments,
  ...) through the `DIALOG_*` helpers - the inspector is drawn over it, picks its frame, title,
  tabs, buttons, sliders, labels, Settings rows; edits show live. The inspector's DIALOGS button
  opens a list of them. Not reached yet: message / input boxes and the file dialog (QB64_GJ_LIB,
  no `DIALOG_*`); the inspector cannot take arrow keys inside a dialog. Shown as
  their panel only: the Color Mixer / Advanced Color Picker / 3D Color Space / Browser bodies, the
  Swatches grid, the Pen graph, Customize Toolbars' rows, dock title strips / tabs, command
  palette rows, menu bar flyouts. Open / closed nodes are not kept between runs.
- No undo of property edits beyond middle-click revert and the `.history/` backups.
