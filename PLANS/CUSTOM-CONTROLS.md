User: ## CUSTOMIZABLE CONTROLS
- [ ] Allow the user to customize keyboard shortcuts
- [ ] For each shortcut-enabled function:
  - [ ] Show an icon if relevant to the function (from toolbox/bars)
  - [ ] Show the description of the function
  - [ ] Controls:
    - [ ] HOLD Key (optional) (button)
      - [ ] This key is required to be held for a gate to enable the PRESS key(s)
      - [ ] User clicks button, and it shows a dialog Waiting for input | Press the key to hold down to gate this shortcut.
    - [ ] PRESS Key(s) (button)
      - [ ] These keys (plus optional HOLD key) are used to trigger the function/shortcut
      - [ ] User clicks PRESS Keys button and dialog shows Waiting for input | Press the key(s) to trigger (description/name of function with optional icon).
    - [ ] MOUSE Button(s) (radio)
      - [ ] Left Click
      - [ ] Right Click
      - [ ] Middle Click
    - [ ] MOUSE Wheel
      - [ ] ...


```
Fig 1 - CONTROL CUSTOMIZATION WINDOW
____________________________________________________________________________________________________________________________
| CUSTOMIZE CONTROLS                                                                                                   [x] |
|--------------------------------------------------------------------------------------------------------------------------|
|                                                                                                                          |
|  FIND: {e.g. "fill" auto-refreshes below}                                                                                |
|                                                                                                                          |
|                                                  ======= CURRENT ASSIGNMENT ====  ======= NEW ASSIGNMENT =========  ___  |
| |ICON | FUNCTION                                 | HOLD | PRESS | CLICK | WHEEL | | HOLD | PRESS | CLICK | WHEEL |  | |  |
| |-----|------------------------------------------|------|-------|-------|-------| |------|-------|-------|-------|  |-|  |
| | *1  | FILL: Engage Tool                        |      |   f   |       |       | | (  ) | (  )  | (  )  | (  )  |  |S|  |
| |     | FILL: Execute Flood Fill                 |      |   L   |       |       | | (  ) | (  )  | (  )  | (  )  |  |C|  |
| | *2  | FILL: Flood Fill Globally using FG Color |   f  |       |   L   |       | | (  ) | (  )  | (  )  | (  )  |  |R|  |
| | *3  | FILL: Flood Fill Globally using BG Color |   f  |       |   R   |       | | (  ) | (  )  | (  )  | (  )  |  |O|  |
| | *4  | Toggle Grid Cell Fill Mode               |      |       |       |       | | (  ) | (  )  | (  )  | (  )  |  |L|  |
| |     |                                          |      |       |       |       | | (  ) | (  )  | (  )  | (  )  |  |L|  |
| |     |                                          |      |       |       |       | | (  ) | (  )  | (  )  | (  )  |  | |  |
| |-----|------------------------------------------|------|-------|-------|-------| |------|-------|-------|-------|  |_|  |
|                                                                                                                          |
| (SAVE) (LOAD) (RESET) (PRINT)                                                                                            |
|                                                                                                                          |
|                                                       [   OK  ]                                                          |
|__________________________________________________________________________________________________________________________|
     
...

(  ) = Button to engage control assignment
  *1 = Toolbox Fill Icon
  *2 = Edit Bar Fill with FG Icon
  *3 = Edit Bar Fill with BG Icon
  *4 = Advanced Bar Grid Cell Fill Icon
---

Fig 2 - CONTROL ASSIGN DIALOG(s)

_______________________________________________
| ASSIGNING HOLD KEY                       [x]|
|---------------------------------------------|
| FUNCTION: {function}                        |
|                                             |
|       is currently assigned to: {key}       |
|                                             |
|       Press key to assign for >HOLD<        |
|                                             |
| [ CLEAR ]       [  OK  ]         [ CANCEL ] |
|_____________________________________________|

Same dialog but with HOLD changed to PRESS for PRESS Key
_______________________________________________
| ASSIGNING PRESS KEY(s)                   [x]|
|---------------------------------------------|
| FUNCTION: {function}                        |
|                                             |
|     is currently assigned to: {key, key}    |
|                                             |
|          Press key(s) to assign...          |
|                                             |
| [ CLEAR ]       [  OK  ]         [ CANCEL ] |
|_____________________________________________|
Where key can be any legal ascii key, case sensitive and also modifiers:
ALT, CTRL, SHIFT

Same dialog but with HOLD changed to CLICK and KEY changed to BUTTON
_______________________________________________
| ASSIGNING MOUSE BUTTON                   [x]|
|---------------------------------------------|
| FUNCTION: {function}                        |
|                                             |
|     is currently assigned to: {button}      |
|                                             |
|          Press button to assign...          |
|                                             |
| [ CLEAR ]       [  OK  ]         [ CANCEL ] |
|_____________________________________________|


Same dialog but with HOLD changed to WHEEL, Press changed to Scroll, key changed to wheel
_________________________________________________
| ASSIGNING WHEEL                            [x]|
|-----------------------------------------------|
| FUNCTION: {function}                          |
|                                               |
|          is currently assigned to:            |
| WHEEL: [ SCROLL UP ] [ SCROLL DOWN ] [ BOTH ] |
|                                               |
|                  change to:                   |
| WHEEL: [ SCROLL UP ] [ SCROLL DOWN ] [ BOTH ] |
|                                               |
| [ CLEAR ]        [  OK  ]          [ CANCEL ] |
|_______________________________________________|

BOTH is only enabled and available for bidirectional operations like brush size, opacity, font size, etc. where a value can be increased or decreased.

```

GitHub Copilot: Explore keyboard/input binding system

Explore CFG file format and action system

Read [](file:///home/grymmjack/git/DRAW/INPUT/KEYBOARD.BM#1-1), lines 1 to 200

Read [](file:///home/grymmjack/git/DRAW/CFG/CONFIG.BI#1-1), lines 1 to 150

Read [](file:///home/grymmjack/git/DRAW/GUI/COMMAND.BM#1-1), lines 1 to 100

Read [](file:///home/grymmjack/git/DRAW/GUI/COMMAND.BM#1-1), lines 1 to 150

Searched for files matching `**/KEYBIND*`, 2 matches

Read [](file:///home/grymmjack/git/DRAW/_COMMON.BI#1-1), lines 1 to 100

Read [](file:///home/grymmjack/git/DRAW/CFG/CONFIG.BM#1-1), lines 1 to 150

Read [](file:///home/grymmjack/git/DRAW/GUI/COMMAND.BM#100-100), lines 100 to 180

Read [](file:///home/grymmjack/git/DRAW/INPUT/MOUSE.BM#1-1), lines 1 to 100

Read [](file:///home/grymmjack/git/DRAW/GUI/SETTINGS.BI)

Read [](file:///home/grymmjack/git/DRAW/GUI/SETTINGS.BM#1-1), lines 1 to 80

Read [](file:///home/grymmjack/git/DRAW/GUI/COMMAND.BM#150-150), lines 150 to 400

Read [](file:///home/grymmjack/git/DRAW/CFG/CONFIG.BM#150-150), lines 150 to 400

Read [](file:///home/grymmjack/git/DRAW/CFG/CONFIG.BI#1-1), lines 1 to 150

Read [](file:///home/grymmjack/git/DRAW/GUI/MENUBAR.BM#1-1), lines 1 to 60

Read [](file:///home/grymmjack/git/DRAW/GUI/COMMAND.BM#180-180), lines 180 to 350

Read [](file:///home/grymmjack/git/DRAW/CFG/CONFIG.BI#150-150), lines 150 to 400

Searched for files matching `**/COMMAND.BI`, 1 match

Read [](file:///home/grymmjack/git/DRAW/GUI/MENUBAR.BM#60-60), lines 60 to 200

Read [](file:///home/grymmjack/git/DRAW/GUI/COMMAND.BI)

Searched for regex `KEYBINDING|KEY_BINDING|hotkey|HOTKEY|binding` (`**/*.BI`), 20 results

Searched for regex `EXPORT_ACT_|EXPORT_QB64_ACTION|ACTION_SETTINGS` (`**/*.BI`), 12 results

Read [](file:///home/grymmjack/git/DRAW/GUI/SETTINGS-WIDGETS.BI)

Good context gathered. Before drafting the full plan, I have a few critical questions — the scope here is very large and the answers will significantly shape the architecture. 

Analyzing your answers...

Explore dialog/widget infrastructure details

Read [](file:///home/grymmjack/git/DRAW/GUI/SETTINGS-WIDGETS.BI)

Read [](file:///home/grymmjack/git/DRAW/GUI/SETTINGS.BM#1-1), lines 1 to 120

Read [](file:///home/grymmjack/git/DRAW/GUI/SCROLLBAR.BI)

Read [](file:///home/grymmjack/git/DRAW/CFG/CONFIG.BI#1-1), lines 1 to 60

Read [](file:///home/grymmjack/git/DRAW/GUI/DIALOG.BI)

Read [](file:///home/grymmjack/git/DRAW/GUI/SETTINGS.BM#120-120), lines 120 to 200

Searched for text `CONST ACTION_` (`**/COMMAND.BI`), no results

Searched for text `CONST ACTION_` (`**/GUI/COMMAND.BI`), no results

Searched for files matching `**/COMMAND.BI`, 1 match

Searched for regex `CONST ACTION_` (`DRAW` · `GUI/COMMAND.BI`), no results

Read [](file:///home/grymmjack/git/DRAW/GUI/COMMAND.BI)

Searched for regex `CMD_register|CMD_add` (`DRAW` · `GUI/COMMAND.BM`), 5 results

Searched for regex `ACTION_|CONST.*=\s*[0-9]` (`DRAW` · `_COMMON.BI`), 10 results

Searched for regex `CMD_register` (`DRAW` · `GUI/COMMAND.BM`), 200 results

Read [](file:///home/grymmjack/git/DRAW/GUI/COMMAND.BM#265-265), lines 265 to 400

Searched for regex `scrollY|scrollDrag|SCROLL_W|contentH|SETTINGS_OBJ|TYPE SETTINGS` (`DRAW` · `GUI/SETTINGS.BI`), 15 results

Read [](file:///home/grymmjack/git/DRAW/GUI/SETTINGS.BI)

Now I have enough to write the full plan. Let me also check one detail about how icons are stored per-action: 

Explore icon/action associations

Read [](file:///home/grymmjack/git/DRAW/GUI/COMMAND.BI)

Read [](file:///home/grymmjack/git/DRAW/GUI/TOOLBAR.BM#1-1), lines 1 to 60

Read [](file:///home/grymmjack/git/DRAW/GUI/EDITBAR.BI)

Read [](file:///home/grymmjack/git/DRAW/INPUT/KEYBOARD.BM#1-1), lines 1 to 60

Searched for regex `iconHandle|icon_handle|GUI_TB.*icon|TOOLBAR.*icon|_LOADIMAGE.*icon` (`**/TOOLBAR.BM`), 3 results

Searched for regex `KEY_LSHIFT|KEY_CTRL|KEY_ALT|KEY_SHIFT|KEY_RSHIFT|KEY_RCTRL|KEY_LCTRL` (`**/*.BI`), 10 results

Searched for regex `GUI_TB_OBJ|TYPE GUI_TB|iconHandle|icon_file|imgIcon` (`**/TOOLBAR.BI`), no results

Searched for regex `TYPE GUI_TB_OBJ|iHnd|iHndAlt|icon_file|icon_path|GUI_TB\(` (`**/TOOLBAR.BI`), 20 results

Read [](file:///home/grymmjack/git/DRAW/GUI/TOOLBAR.BM#60-60), lines 60 to 140

Read [](file:///home/grymmjack/git/DRAW/INPUT/MODIFIERS.BI)

Read [](file:///home/grymmjack/git/DRAW/GUI/TOOLBAR.BI#1-1), lines 1 to 130

Read [](file:///home/grymmjack/git/DRAW/_COMMON.BI#28-28), lines 28 to 60

Searched for regex `TYPE GUI_TB_OBJ|END TYPE|iHnd|iSrc` (`**/TOOLBAR.BI`), 20 results

Searched for files matching `**/GUI/GUI.BI`, 1 match

Searched for regex `TYPE GUI_TB_OBJ|END TYPE|iHnd|iSrc|DIM SHARED GUI_TB` (`**/GUI/GUI.BI`), 6 results

Read [](file:///home/grymmjack/git/DRAW/GUI/GUI.BI#1-1), lines 1 to 40

Now I have all the context needed. Let me save and present the plan. 

Created memory file [](file:///home/grymmjack/.config/Code/User/workspaceStorage/afe1129462ed0794a73d895d6663976c/GitHub.copilot-chat/memory-tool/memories/M2I3OTBmNzUtMmJjMC00Mzk2LWFlMDUtNmM4YmIzOWQzNzY3/plan.md)

## Plan: Customizable Controls System

**TL;DR**: Build a full runtime-rebindable input system — keyboard HOLD+PRESS combos, mouse buttons, and mouse wheel — covering all 165 registered actions. An override layer sits on top of all existing hardcoded defaults (no existing code removed). Custom bindings are stored in `DRAW.bindings` (overrides only, text key=value format). The UI is a wide modal dialog with a scrollable 9-column list plus 3 capture sub-dialogs.

---

### Phase 1 — Data layer (no UI yet)

1. Add `bidirectional AS INTEGER` to `CMD_OBJ` TYPE in COMMAND.BI — enables "BOTH" direction in wheel assign dialog for zoom, brush size, opacity, font size, etc.
2. **Create `CFG/BINDINGS.BI`** — `DRAW_BINDING` TYPE (fields below), `DIM SHARED BINDINGS(CMD_MAX_COMMANDS)`, key-code helpers
3. **Create `CFG/BINDINGS.BM`** — `BINDINGS_init`, `BINDINGS_load`, `BINDINGS_save`, `BINDINGS_reset`, `BINDINGS_key_name$`, `BINDINGS_parse_hotkey_string`, `BINDINGS_find_conflict%`
4. Update _ALL.BI / _ALL.BM to include `BINDINGS.BI` / `BINDINGS.BM` (after `CONFIG`, before GUI)
5. In DRAW.BAS: call `BINDINGS_init` → `BINDINGS_load` immediately after `CONFIG_load`

**`DRAW_BINDING` TYPE** (one entry per action, indexed parallel to `CMD()` array):
| Field | Type | Purpose |
|---|---|---|
| `holdKey` | `LONG` | `_KEYDOWN` physical code (0=none) |
| `holdMods` | `INTEGER` | bitmask: 1=ctrl 2=shift 4=alt |
| `pressKey` | `LONG` | `_KEYDOWN` physical code (0=none) |
| `pressMods` | `INTEGER` | bitmask |
| `mouseBtn` | `INTEGER` | 0=none 1=left 2=right 3=middle |
| `wheelDir` | `INTEGER` | 0=none 1=up 2=down 3=both |
| `hasCustom` | `INTEGER` | TRUE = user override (written to file) |

Defaults populated in `BINDINGS_init` by parsing existing `CMD_OBJ.hotkey$` strings via `BINDINGS_parse_hotkey_string` ("Ctrl+S" → pressMods=1, pressKey=83). File `DRAW.bindings` at `PATHS_config$("DRAW.bindings")` stores **only** `hasCustom=TRUE` rows, keeping the file compact.

---

### Phase 2 — Dispatch override layer *(parallel with Phase 3; depends on Phase 1)*

6. **`KEYBOARD_check_custom_bindings%`** in KEYBOARD.BM: called at the very top of `KEYBOARD_input_handler`, before the existing `SELECT CASE`. Scans `BINDINGS()` for matching hold+press state (using `MODIFIERS.*` + `_KEYDOWN()` with `STATIC` transition guard). On match → `CMD_execute_action` → returns `TRUE` (exits sub). Falls through if no match — existing hardcoded shortcuts still work.
7. **`MOUSE_check_custom_bindings%` / `WHEEL_check_custom_bindings%`** in MOUSE.BM: inserted before `MOUSE_dispatch_tool_hold` and wheel handler respectively.

---

### Phase 3 — Main dialog *(parallel with Phase 2; depends on Phase 1)*

8. **Create `GUI/CONTROLS.BI`** — `CONTROLS_CTX` TYPE, dimension constants:
   - `CONTROLS_W = 720`, `CONTROLS_H = 440` (unscaled, scaled by `CFG.TOOLBAR_SCALE%`)
   - `ROW_H = 18`, `COL_ICON_W = 20`, `COL_NAME_W = 190`, 4×current cols (50px each), 4×new cols (60px each, buttons), 10px scrollbar
9. **Create `GUI/CONTROLS.BM`** — `CONTROLS_open()` blocking modal (same structure as `SETTINGS_show_dialog`):
   - `CONTROLS_CTX` holds: `filter$`, `scrollY`, scroll drag state, `pendingChanges(CMD_MAX_COMMANDS) AS DRAW_BINDING` shadow copy, `visibleItems()` filtered index array, `hasChanges%` dirty flag
   - **FIND input** at top → live-filters `CMD().name` (case-insensitive) into `visibleItems()`
   - **Category divider headers** (e.g. "TOOLS", "FILE", "EDIT") rendered as non-clickable separators in list
   - **Icon lookup**: `CONTROLS_get_icon_handle&(actionID%)` — tries `EDIT_BAR_ITEMS` first (has `actionID` ↔ `iconHandle` map), falls back to toolbar `TOOLBAR_BUTTON_TO_TOOL` lookup, returns -1 if none → blank cell
   - **Current assignment** columns (HOLD / PRESS / CLICK / WHEEL): read-only display from `BINDINGS()` defaults + `hasCustom` overrides
   - **New assignment** columns: clickable buttons `( key )` → open corresponding sub-dialog. Inline red "⚠ {name}" conflict badge when `BINDINGS_find_conflict% ≠ -1`
   - **Bottom row**: `(SAVE)` `(LOAD)` `(RESET)` `(PRINT)` buttons left-aligned; `[ OK ]` centered
10. Update _ALL.BI / _ALL.BM includes for `CONTROLS.BI` / `CONTROLS.BM`

---

### Phase 4 — Capture sub-dialogs *(depends on Phase 3)*

All three sub-dialogs live in `GUI/CONTROLS.BM` as local blocking modal loops (identical structural pattern to `SETTINGS_show_dialog`). **Conflict check fires before enabling OK.**

11. **`CTRL_assign_key_open%`** (handles both HOLD and PRESS capture): title changes dynamically. Shows "currently assigned to: {key}", drains `_KEYHIT` loop for capture. `[ CLEAR ]` sets key to 0. Returns captured key code or 0 on cancel.
12. **`CTRL_assign_mouse_open%`**: waits for `_MOUSEINPUT` button press inside the dialog. Left/Right/Middle shown as toggle buttons. `[ CLEAR ]` removes.
13. **`CTRL_assign_wheel_open%`**: radio group `[ SCROLL UP ] [ SCROLL DOWN ] [ BOTH ]`. "BOTH" is disabled (greyed) when `CMD_OBJ.bidirectional = FALSE` for the current action.

---

### Phase 5 — Integration *(depends on Phases 2–4)*

14. Add `CONST ACTION_CUSTOMIZE_CONTROLS = 2300` in COMMAND.BI
15. Register it in `CMD_init` and add `CASE 2300: CONTROLS_open` in `CMD_execute_action` in COMMAND.BM
16. Set `bidirectional = TRUE` in `CMD_init` for: zoom in/out, brush size, opacity, font size, scroll canvas (all bidirectional wheel-eligible)
17. Add "Customize Controls..." menu item in MENUBAR.BM under Edit menu (before the Settings separator)
18. **PRINT**: `DRAW_save_file$(".txt", ...)` → write formatted hotkey reference with all 165 actions + their current assignments
19. **LOAD**: `DRAW_open_file$(".bindings", ...)` → `BINDINGS_load` from chosen path → re-populate `pendingChanges`

---

### Relevant files to use as templates
- SETTINGS.BM — blocking modal loop structure, scroll track pattern
- DIALOG.BI — `DIALOG_CTX` infrastructure
- GJ-DIALOG-SCALE.BM — `DRAW_save_file$` / `DRAW_open_file$` for PRINT/LOAD
- EDITBAR.BI — `EDIT_BAR_ITEMS.iconHandle` for action→icon lookup
- CONFIG.BM — `CONFIG_load` / `CONFIG_save` text-file format pattern

---

### Verification
1. Build clean: `qb64pe -w -x -o DRAW.run DRAW.BAS`
2. Open dialog via Edit → Customize Controls... → dialog appears
3. Type "fill" in FIND → list filters to fill-related actions only
4. Click HOLD button → ASSIGNING HOLD KEY modal → press `f` → confirms assignment
5. Click CLICK button → conflict with existing → OK disabled; CLEAR unblocks it
6. Assign unique combo → OK → NEW column shows it; CURRENT unchanged until SAVE+restart
7. Click SAVE → `DRAW.bindings` written to config dir with only override rows
8. Restart DRAW → `DRAW.bindings` loaded → custom binding fires correctly via override layer
9. RESET → all `hasCustom` flags cleared → defaults restored in dialog
10. PRINT → file save dialog → `.txt` hotkey reference written and readable

---

**Decisions / scope boundaries**
- Existing hardcoded `SELECT CASE` in `KEYBOARD.BM` is **not removed** — override layer only
- `DRAW.bindings` stores **overrides only** — keeps file small and forward-compatible
- `bidirectional` field added to `CMD_OBJ` (1 byte per slot × 200 slots = negligible)
- Icon display in dialog is best-effort — actions with no icon in editbar or toolbar show a blank cell
- Mouse rebinding of canvas interactions (left=paint, right=pick) is supported but modifying those defaults requires the user to explicitly assign them — there is no guard preventing it

**Further consideration**
- The `BINDINGS_parse_hotkey_string` function needs to handle at least: single letters, `Ctrl+`, `Shift+`, `Alt+`, `Ctrl+Shift+`, `Ctrl+Alt+`, named keys (`Esc`, `Del`, `PgUp`, `PgDn`, `F1`–`F12`, `Tab`, `Enter`, arrow names). The ~90 currently-assigned actions all use one of these patterns — coverage of just those ensures defaults initialize correctly.