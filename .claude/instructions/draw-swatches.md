# Swatches panel (View > Swatches, actions 2600-2602)

A grid of color swatches from a swatch set, beside the palette strip (the strip
stays the document palette). Two layers:

| Layer | Files | Role |
|---|---|---|
| Data | `includes/QB64_GJ_LIB/SWATCH/SWATCH.BI/BM` (`SWS_`) | The set: load / save / edit. Pure data, no host globals, unit-tested headless by `SWATCH-TEST.BAS` (44 checks). Needs `QB64_GJ_LIB/COLOR/COLOR-SPACES` (sorting, Lab swatches). |
| Panel | `GUI/SWATCHES.BI/BM` (`SWP_`) | The window: layout, render, menus, input, sets list, import, QA dump. |

## The set (SWS_)

- `SWS(1 .. SWS_N)` of `SWATCH_ENTRY`: `c` (&HFFRRGGBB), `kind` (`SWS_KIND_COLOR` / `SPACE` = an empty cell / `BREAK` = next entry starts a row), `flags` (`SWS_FLAG_LOCK`, `SWS_FLAG_GROUP` + `grp` label), `sel`, `nm`.
- `SWS_COLS` = the columns the layout was made for (0 = unknown). `SWS_NAME`, `SWS_ERR` (why a load / save failed).
- Formats: `.aco` (v1 + v2 names; RGB / HSB / CMYK / Lab / gray), `.gpl` (`Columns:`; DRAW extras in `#SWS: SPACE | BREAK | LOCK | GROUP` comment lines other apps ignore), `.act`, `.pal` (JASC + RIFF), `.hex`, `.txt` (Paint.NET). `SWS_load%` dispatches on the extension, `SWS_can_load%` checks it. Saves: `.gpl`, `.aco`, `.hex`.
- Photoshop's auto names ("Swatch 12") are dropped on load (`SWS_auto_name%`).
- **Order for an .aco:** `SWS_COLS = SWS_guess_cols%` **before** `SWS_black_to_spaces TRUE`. The guess reads the black padding that lines the ramps up; after the conversion it is gone. Both `SWP_load_set` and `SWATCH-TEST --convert` follow this order.
- Edits (phase 2 will wire them to the panel): delete / move / copy / sort (`SWS_SORT_HUE / LIGHT / SAT / LUMA`, 0 = reverse) the selection with **locked entries staying exactly where they are**, remove duplicates, `SWS_snapshot$` / `SWS_restore` for undo.

## The panel (SWP_)

- FPANEL family member (title bar, drag, close, dock, per-panel scale, auto-hide while drawing over it, F11). Native image `SWP.panelImg`, `renderScale = FPANEL_scale% / displayScale`.
- **Floating** it has its own size: `CFG.SWATCHES_W / _H` (native px, 0 = default width `FPANEL_panel_w%` x 150), corner grip `SWP_GRIP`. **Docked** it is `DP_H_FLEX` like the Preview: `DOCK_apply_rect` -> `FPANEL_fit` -> `SWP_fit nw, nh` (0, 0 = floating) and the grid scrolls.
- IDs: `DP_SWATCH` = 15, `REGION_SWATCHES` = 33, `WZ_` slot in `GUI/WINZ`, `FPANEL_FLOAT_COUNT` slot 9, `WS_EL_SWATCHES` = 18 (workspaces), Settings → Panels → Panel Scale row.
- Layout (`SWP_layout`, two passes: the second when a scroll bar is needed): `SWATCHES_COLS` 0 = the set's own, -1 = fit, N; `CELL`, `GAP`, `STRETCH` (grow or shrink to the width), `SQUARE`, `BORDER`. `SWP_reflow` places entries (a BREAK ends the row) into `SWP_ER` / `SWP_EC`.
- Pick: `SWP_pick i, toBG` sets the same fields a palette-strip click sets (`PAINT_COLOR`, `DRAW_COLOR`, `PAL_FG_IDX` by find_index / closest, `POINTER.C`; the BG equivalents). Left = FG, right = BG.
- Menus are their own native image drawn after the panel (`SWP_render_menu`), not a POPUP: `POPUP_note_rect` would reblit canvas pixels over it. `SWP_MENU_SETS` (the set list) and `SWP_MENU_GEAR` (layout chips + checks, Load Swatches…, Open My Swatches Folder). Chips and checks keep the menu open; items close it. An open menu captures every click (the MOUSE gate lets it through even where `WZ_blocked` would stop it). `Esc` closes it (`INPUT/KEYBOARD.BM`, next to the dock-handle menu).
- Sets list (`SWP_scan_sets`): 0 = Document Palette (16 to a row, refreshed when `SWP_pal_sig$` changes), then My Swatches (`PATHS_data$("SWATCHES/")`), `ASSETS/SWATCHES/`, `ASSETS/PALETTES/`, My Palettes (+ `CREATED/`).
- **Listing never writes.** Only `SWP_import` and action 2602 create the My Swatches folder: a normal QA run does not isolate `XDG_DATA_HOME` (only `QA_USER_PROFILE=1` does), so a scan that created it would write into the real `~/.local/share/DRAW`.
- Import (`SWP_import`, action 2601): load any format -> guess columns -> (aco) black -> spaces -> save a `.gpl` copy in My Swatches with a unique name -> load that. The original is never written.

## Config (DRAW.cfg)

`SWATCHES_VISIBLE / SCALE / X / Y / W / H`, `SWATCHES_SET` (path; empty = the document palette; relative paths resolve from the DRAW folder), `SWATCHES_COLS` (0 / -1 / N), `CELL` (10), `GAP` (1), `STRETCH` (FALSE), `SQUARE` (TRUE), `BORDER` (FALSE), `BLACK_SPACERS` (TRUE).

## Shipped sets

`ASSETS/SWATCHES/*.gpl` are generated copies of Rick's Photoshop swatch sets (his `.aco` originals are never edited): GJ - Pixel Swatches (14 columns), GJ - Pixel Swatches 2 (26), GJ - Pixel Swatches All (26), Grymmjacks Essential Swatches - CS (16). Regenerate with `SWATCH-TEST --convert IN.aco OUT.gpl` (absolute paths: a QB64 program changes to its own folder at start).

## QA

- Dump lines (dock dump, after `ADVCP_dump$`), viewport px:
  - `SWAT entries colors cols cellW cellH gap rows scrollY maxScroll fgIdx bgIdx menu menuRows setKey`
  - `SWATG` grid rect, set-button rect, gear rect
  - `SWATS selected anchor i ...` (up to 64 selected entries)
  - `SWATC i x y w h kind hex` (first 48 entries, every entry showing in the grid (up to 400), the last)
  - `SWATM x y w h rowH top`, `SWATMI row kind id chk x y w h label`, `SWATMC id k x y w h label` (chip k of chips row `id`; COLUMNS = 10, CELL = 11, GAP = 12)
- Helpers: `QA/swatches-lib.sh` (`sw_read`, `sw_sel`, `sw_cell`, `sw_click N [shift|ctrl|right]`, `sw_pitch`, `sw_empty_xy`).
- Fixtures: `QA/fixtures/make-swatch-fixtures.py` -> `swatches-edit.gpl` (8 columns: row 0 = 1-8 reds, row 1 = 9-12 greens (12 LOCKED) + a BREAK (13), row 2 = 14-19 blues, 20 SPACE, 21 Gold; row 1 columns 4-7 empty), `swatches-ramps.gpl` (8 columns, 160 colors, a SPACE at 6, entry 3 "Named Teal") and `swatches-pad.aco` (6 wide, 4 ramps + 2 black per row: 22 entries, 5 empty, 17 colors after loading).
- Tests: `swatches-panel.sh` (layout, FG/BG pick, wheel, gear chips, set list, Esc, dock + float), `swatches-aco.sh` (aco guess + black filler), `dock-native-swatches.sh` (the dock-native family), `swatches-dock-resize.sh`, `swatches-select.sh` (click / Shift / Ctrl / box / Ctrl+box / Ctrl+A / Esc / right-click), `swatches-select-scroll.sh` (scrolled range, box autoscroll, set switch clears, docked). `swatches` is in `dock-lib.sh`'s `DK_NATIVE` list (its floating position is saved in its own CFG keys, not `DOCK_FLOAT_*`).

## Selection (phase 2)

`SWS(i).sel` is the selection (the library's ops act on it). `SWP_click_entry` (plain = alone + FG via `SWP_pick`, Shift = range from `SWP.anchor`, Ctrl = toggle), box drag from an empty place (`SWP.boxing`, content coords so it survives scrolling; autoscrolls past the grid; Ctrl / Shift adds on top of `SWP.selBase`), `SWP_select_all`. Keys only while the pointer is on the panel (`SWP_has_keys%`): `SWP_key_input%` in `KEYBOARD_input_handler` (Esc, Ins), the rest through `SWP_take_action%`. `SWP_load_set` clears the selection.

## Editing (phase 2)

Every edit: `SWP_edit_begin%` (copy to My Swatches via `SWP_make_own%` if `SWP_is_mine%(setKey)` is false - the source is never written; a new undo step = `SWS_snapshot$`; the set's redo chain dropped) -> change `SWS()` -> `SWP_edit_end` (relayout + `SWP_save_now`, `.gpl` with `#SWS:` extras). Undo list `SWP_UNDO_*` (200 steps, keyed by set path, kind 0 undo / 1 redo), `SWP_undo redo%`. Keys while the pointer is on the panel: Del / Edit > Clear (CMD 306/308, intercepted at the top of `CMD_execute_action`), Ctrl+Z / Ctrl+Y (CMD 301 / 302). Dump `SWATE undo redo saves mine`. Tests run on a scratch data dir: `sw_isolate` (see memory qa-data-dir-not-isolated). Tests: `swatches-undo.sh`, `swatches-copy-names.sh`.

The edit menu (`SWP_MENU_EDIT` = 3): the ☰ button (`SWP_menu_btn_xy`, gear x - 15; `SWP_bar_at%` = 3) or Shift+right-click in the grid (`SWP.menuAtMouse` places it at the pointer; an unselected swatch is selected alone first). `SWP_build_edit` items 201 Add FG, 202 Delete, 203 Lock / Unlock, 206 Duplicate, 204 Insert Empty Cell, 205 Insert Row Break, 207 Remove Duplicates, 208 / 209 Select All / None, 210 / 211 Undo / Redo; header "N SELECTED". Subs `SWP_add_fg`, `SWP_lock_toggle`, `SWP_insert_kind`, `SWP_duplicate`, `SWP_remove_dups` (0 removed -> `SWP_edit_cancel` drops the undo step), `SWP_scroll_to`. Ops with nothing selected flash "nothing selected" BEFORE `SWP_edit_begin%`, so they make no copy and no undo step. Keys over the panel: `SWP_take_action%` at the top of `CMD_execute_action` takes 306 / 308 Del, 105 L (lock - else the Line tool), 310 Ctrl+A, 307 Ctrl+D, 301 / 302 undo / redo; `SWP_key_input%` takes Ins (`_KEYDOWN(20992)`) and Esc. **Esc with a menu open is handled in `SWP_key_input%` too** - closing it elsewhere left the edge memory stale, so the still-held Esc cleared the selection a frame later. Dump: `SWATG` adds the ☰ rect, `SWATC` adds flags (row breaks have no cell, so their numbers are skipped). QA helpers: `sw_menu_edit`, `sw_menu_click ID`, `sw_hexes` ("-" empty, "|" break from the numbering gap), `sw_empty_xy`. Tests: `swatches-edit-menu.sh`, `swatches-edit-ops.sh` (every op, then undo all back to the file), `swatches-edit-edges.sh` (nothing selected, locked duplicate, restart round trip).

## Phases

1. Panel + loading (done).
2. Editing: select ranges, add FG, delete, lock, move, sort, ramps, undo via `SWS_snapshot$`, save back to the `.gpl`.
3. More formats + bridges: `.ase` groups, strip <-> swatches, swatches from an image.
