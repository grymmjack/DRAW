# DRAW Input Handling Analysis
## Comprehensive Analysis Report

Generated: February 11, 2026

---

## EXECUTIVE SUMMARY

The DRAW codebase has a well-structured input handling architecture with:
- **Central handlers** in `INPUT/MOUSE.BM` and `INPUT/KEYBOARD.BM` 
- **Main loop integration** in `DRAW.BAS` (lines 104-196)
- **GUI widget handlers** distributed across `GUI/*.BM` files
- **Tool-specific handlers** in `TOOLS/*.BM` files

### Call Flow Overview
```
DRAW.BAS (main loop)
├── k& = _KEYHIT (line 104) - capture keypress
├── MOUSE_input_handler (line 160) - central mouse processing
├── KEYBOARD_input_handler (line 162) - central keyboard processing
├── STICK_input_handler (line 164) - joystick processing
├── SCREEN_render (line 202) - rendering (includes pointer update)
├── MOUSE_input_handler_loop (line 218) - post-render mouse cleanup
├── KEYBOARD_input_handler_loop (line 219) - post-render keyboard cleanup
└── STICK_input_handler_loop (line 220) - post-render stick cleanup
```

---

## CSV DATA FORMAT

Device,File,Line,Function,Description,GUIRefresh,OSWorkaround,CallDepth,FunctionLines

---

## 1. CENTRAL HANDLERS (Entry Points from Main Loop)

### Mouse Central Handler

| Device | File | Line | Function | Description | GUIRefresh | OSWorkaround | CallDepth | FunctionLines |
|--------|------|------|----------|-------------|------------|--------------|-----------|---------------|
| Mouse | INPUT/MOUSE.BM | 14 | MOUSE_init | Initializes MOUSE state object | No | No | 1 | 16 |
| Mouse | INPUT/MOUSE.BM | 37 | MOUSE_reset_buttons | Syncs button states after dialogs | No | No | 2 | 20 |
| Mouse | INPUT/MOUSE.BM | 63 | MOUSE_force_buttons_up | Forces all buttons UP, sets SUPPRESS_FRAMES | No | No | 2 | 14 |
| Mouse | INPUT/MOUSE.BM | 85 | MOUSE_input_handler | Main mouse processing - drain-then-process pattern | Yes | Yes (macOS) | 1 | 1676 |
| Mouse | INPUT/MOUSE.BM | 1762 | MOUSE_input_handler_loop | Post-render cleanup, deferred action processing | Yes | No | 1 | 22 |

### Keyboard Central Handler

| Device | File | Line | Function | Description | GUIRefresh | OSWorkaround | CallDepth | FunctionLines |
|--------|------|------|----------|-------------|------------|--------------|-----------|---------------|
| Keyboard | INPUT/KEYBOARD.BM | 15 | KEYBOARD_colors | Color selection via number keys 0-9 | GUI_NEEDS_REDRAW% | No | 2 | 40 |
| Keyboard | INPUT/KEYBOARD.BM | 55 | KEYBOARD_tools | Tool switching via letter keys | GUI_NEEDS_REDRAW% | No | 2 | 298 |
| Keyboard | INPUT/KEYBOARD.BM | 353 | KEYBOARD_brush_size | Brush size with [ ] F1-F4 keys | GUI_NEEDS_REDRAW% | No | 2 | 21 |
| Keyboard | INPUT/KEYBOARD.BM | 374 | KEYBOARD_assistants | Toggle assistants via F6-F8, ~ \ keys | GUI_NEEDS_REDRAW% | No | 2 | 23 |
| Keyboard | INPUT/KEYBOARD.BM | 397 | KEYBOARD_input_handler | Main keyboard processing | Yes | Yes (macOS) | 1 | 471 |
| Keyboard | INPUT/KEYBOARD.BM | 1592 | KEYBOARD_layers | Layer keyboard shortcuts ([ ] for opacity, etc) | GUI_NEEDS_REDRAW% | Yes (macOS) | 2 | 196 |
| Keyboard | INPUT/KEYBOARD.BM | 1788 | KEYBOARD_input_handler_loop | Post-render keyboard cleanup | No | No | 1 | 1 |

---

## 2. RAW QB64-PE INPUT FUNCTION USAGE

### _MOUSEINPUT (Buffer Drain Pattern)

| File | Line | Function | Description | Purpose |
|------|------|----------|-------------|---------|
| INPUT/MOUSE.BM | 39 | MOUSE_reset_buttons | `DO WHILE _MOUSEINPUT : LOOP` | Clear pending input after dialogs |
| INPUT/MOUSE.BM | 65 | MOUSE_force_buttons_up | `DO WHILE _MOUSEINPUT : LOOP` | Clear pending input after dialogs |
| INPUT/MOUSE.BM | 98-106 | MOUSE_input_handler | Drain with wheel accumulation | macOS: capture buttons during drain |
| INPUT/MOUSE.BM | 159 | MOUSE_input_handler | `DO WHILE _MOUSEINPUT : LOOP` | Suppress frames after dialogs |
| INPUT/MOUSE.BM | 245-253 | MOUSE_input_handler | Main drain loop with wheel | Normal mode processing |
| INPUT/MOUSE.BM | 321 | MOUSE_input_handler | `DO WHILE _MOUSEINPUT : LOOP` | Late-arriving events suppression |
| TOOLS/BRUSH.BM | 391 | (custom brush dialog) | `DO WHILE _MOUSEINPUT : LOOP` | Post-dialog cleanup |
| TOOLS/SAVE.BM | 43, 83, 142, 179, 196, 224, 263 | SAVE_* | `DO WHILE _MOUSEINPUT : LOOP` | Post-dialog cleanup |
| TOOLS/LOAD.BM | 39, 67, 82, 114, 179 | LOAD_* | `DO WHILE _MOUSEINPUT : LOOP` | Post-dialog cleanup |
| TOOLS/DRW.BM | 173, 185, 451, 486, 520, 543 | DRW_* | `DO WHILE _MOUSEINPUT : LOOP` | Post-dialog cleanup |
| GUI/LAYERS.BM | 354 | LAYERS_rename | `DO WHILE _MOUSEINPUT: LOOP` | Post-dialog cleanup |
| GUI/TOOLBAR.BM | 356 | TOOLBAR_handle_* | `DO WHILE _MOUSEINPUT : LOOP` | Post-dialog cleanup |
| GUI/PALETTE-PICKER.BM | 162 | PALETTE_PICKER_show | `WHILE _MOUSEINPUT: WEND` | Modal dialog processing |
| OUTPUT/SCREEN.BM | 127 | SCREEN_set_display_scale | `DO WHILE _MOUSEINPUT: LOOP` | Post-resize cleanup |
| DRAW.BAS | 294 | Main loop (after resize) | `DO WHILE _MOUSEINPUT : LOOP` | Post-resize cleanup |

### _MOUSEX / _MOUSEY (Raw Position)

| File | Line | Function | Description |
|------|------|----------|-------------|
| INPUT/MOUSE.BM | 116-117 | MOUSE_input_handler | imp_rawX% = _MOUSEX / imp_rawY% = _MOUSEY (import mode) |
| INPUT/MOUSE.BM | 270-271 | MOUSE_input_handler | rawX% = _MOUSEX / rawY% = _MOUSEY (normal mode) |
| OUTPUT/SCREEN.BM | 302-303 | SCREEN_set_display_scale | new_mx% = _MOUSEX / new_my% = _MOUSEY |
| OUTPUT/SCREEN.BM | 1043 | SCREEN_render | cmx% = _MOUSEX: cmy% = _MOUSEY (crosshair) |
| OUTPUT/SCREEN.BM | 1116-1117 | POINTER_update | POINTER.PREV_DRAW_X% = _MOUSEX (pointer tracking) |
| GUI/POINTER.BM | 83-84, 366-367, 901-902, 957-958, 1031-1032 | POINTER_update/render | mx% = _MOUSEX / my% = _MOUSEY |
| GUI/PALETTE-PICKER.BM | 165-166 | PALETTE_PICKER_show | mx% = _MOUSEX - dialog_x% |

### _MOUSEBUTTON (Button State)

| File | Line | Function | Description |
|------|------|----------|-------------|
| INPUT/MOUSE.BM | 45-47 | MOUSE_reset_buttons | current_b1% = _MOUSEBUTTON(1) etc |
| INPUT/MOUSE.BM | 101-103, 148-154, 248-250, 308-314 | MOUSE_input_handler | Button state capture |
| GUI/POINTER.BM | 140 | POINTER_update | _MOUSEBUTTON(3) for pan mode |
| GUI/POINTER.BM | 492 | POINTER_draw_preview | is_painting% = (_MOUSEBUTTON(1) <> 0) |
| GUI/PALETTE-PICKER.BM | 167 | PALETTE_PICKER_show | mb% = _MOUSEBUTTON(1) |

### _MOUSEWHEEL (Scroll)

| File | Line | Function | Description |
|------|------|----------|-------------|
| INPUT/MOUSE.BM | 99, 107, 246, 254 | MOUSE_input_handler | wheel_delta% = wheel_delta% + _MOUSEWHEEL |

### _MOUSEMOVE (Cursor Warp)

| File | Line | Function | Description |
|------|------|----------|-------------|
| TOOLS/BRUSH.BM | 392 | (custom brush dialog) | _MOUSEMOVE _WIDTH \ 2, _HEIGHT \ 2 |
| TOOLS/SAVE.BM | 45, 84, 144, 180, 197, 226, 264 | SAVE_* | Center cursor after dialog |
| TOOLS/LOAD.BM | 41, 83, 116, 180 | LOAD_* | Center cursor after dialog |
| TOOLS/DRW.BM | 453, 487, 522, 544 | DRW_* | Center cursor after dialog |
| DRAW.BAS | 295 | Main loop (after resize) | Center cursor after window resize |

### _KEYHIT (Keyboard Event)

| File | Line | Function | Description |
|------|------|----------|-------------|
| DRAW.BAS | 104 | Main loop | k& = _KEYHIT - primary key event capture |
| DRAW.BAS | 109-111 | Main loop | macOS ALT tracking via _KEYHIT |
| DRAW.BAS | 132-134 | Main loop | Display scale hotkeys |
| DRAW.BAS | 142 | Main loop | ESC key check |
| GUI/PALETTE-PICKER.BM | 219 | PALETTE_PICKER_show | IF _KEYHIT = 27 THEN (ESC) |

### _KEYDOWN (Key State Polling)

| File | Line | Function | Description |
|------|------|----------|-------------|
| DRAW.BAS | 120-121 | Main loop | CTRL/SHIFT for display scale |
| DRAW.BAS | 125 | Main loop | ALT for display scale (non-Mac) |
| DRAW.BAS | 182 | Main loop | SHIFT held detection for idle |
| OUTPUT/SCREEN.BM | 1031-1036 | POINTER_update | SHIFT/CTRL/ALT for crosshair |
| INPUT/MOUSE.BM | 403, 544, 549, 727, 741, 779-805, 852, 946, 958, 1024, 1033, 1070, 1079, 1206, 1231, 1629, 1673 | MOUSE_input_handler | Modifier key detection throughout |
| INPUT/KEYBOARD.BM | 127, 147, 165, 284, 463-468, 479-482, 553-556, 623-628, 639-662, 697, 700, 719, 730, 741, 779-805, 802, 946-958, 986, 1024-1079, 1146-1147, 1201-1202, 1263-1265, 1441, 1483, 1545, 1550, 1566, 1608-1609 | Various | Modifier detection |
| GUI/POINTER.BM | 140 | POINTER_update | _KEYDOWN(32) for spacebar pan |
| GUI/STATUS.BM | 240 | STATUS_render | SHIFT indicator |
| GUI/PALETTE-STRIP.BM | 434 | PALETTE_STRIP_handle_wheel | SHIFT for page scroll |
| GUI/LAYERS.BM | 1306, 1368, 1392 | LAYER_PANEL_handle_* | ALT/CTRL/SHIFT detection |
| GUI/MENUBAR.BM | 734 | MENUBAR_handle_key | ALT detection |
| TOOLS/MOVE.BM | 135, 137, 270, 430 | MOVE_* | ALT for clone, SHIFT for constrain |
| TOOLS/IMAGE-IMPORT.BM | 425 | IMAGE_IMPORT_* | SHIFT for constrain |

### _KEYCLEAR (Clear Keyboard Buffer)

| File | Line | Function | Description |
|------|------|----------|-------------|
| TOOLS/SAVE.BM | 44, 143, 225 | SAVE_* | Post-dialog keyboard clear |
| TOOLS/LOAD.BM | 40, 68, 115 | LOAD_* | Post-dialog keyboard clear |
| TOOLS/DRW.BM | 452, 521 | DRW_* | Post-dialog keyboard clear |
| GUI/TOOLBAR.BM | 357 | TOOLBAR_handle_* | Post-dialog keyboard clear |

---

## 3. MOUSE STATE OBJECT USAGE (MOUSE.*)

### Coordinate Fields

| File | Line | Function | Field | Description |
|------|------|----------|-------|-------------|
| INPUT/MOUSE.BM | 15-18 | MOUSE_init | X, Y, OLD_X, OLD_Y | Canvas coords initialization |
| INPUT/MOUSE.BM | 120-121, 274-275 | MOUSE_input_handler | RAW_X, RAW_Y | Screen coords storage |
| INPUT/MOUSE.BM | 136-143, 290-303 | MOUSE_input_handler | X, Y | Canvas coord calculation |
| INPUT/MOUSE.BM | 167-168, 230-231, 329-330, 360-361, 378-379, 758-759 | Various | OLD_X, OLD_Y | Previous frame storage |
| DRAW.BAS | 176, 195-196 | Main loop | RAW_X, RAW_Y | Idle detection |
| GUI/STATUS.BM | 185, 197, 204, 211, 220, 232 | STATUS_render | X, Y | Coordinate display |
| GUI/CROSSHAIR.BM | 39-40, 44, 50, 54-55, 61-62 | CROSSHAIR_render | X, Y, CON_X, CON_Y | Crosshair rendering |
| GUI/PALETTE-STRIP.BM | 150-151, 585-586 | Various | RAW_X, RAW_Y | Hover detection |
| GUI/POINTER.BM | 201, 258, 757-758 | POINTER_update | X, Y, RAW_X, RAW_Y | Cursor positioning |
| TOOLS/BRUSH.BM | 135-148, 499-512 | BRUSH_draw | X, Y, OLD_X, OLD_Y, CON_X, CON_Y | Line interpolation |
| TOOLS/MARQUEE.BM | 182, 340 | MARQUEE_* | X, Y | Handle detection |
| TOOLS/POLY-LINE.BM | 16 | POLY_LINE_* | X, Y | Line preview |
| OUTPUT/SCREEN.BM | 855-856 | SCREEN_render | X, Y | Poly line preview |
| GUI/COMMAND.BM | 592 | CMD_execute | X, Y | Paste at cursor |
| INPUT/KEYBOARD.BM | 1330, 1332 | KEYBOARD_* | X, Y | Paste at cursor |

### Button State Fields

| File | Line | Function | Field | Description |
|------|------|----------|-------|-------------|
| INPUT/MOUSE.BM | 22-28, 50-55, 68-73 | Init/Reset | B1, B2, B3, OLD_B1, OLD_B2, OLD_B3 | Button state management |
| INPUT/MOUSE.BM | 148-154, 160-165, 185-186, 227-229, 308-327, 336, 354, 371, 389, 407, 437, 443, 493, 514, 522, 529, 610, 619, 641, 741, 755-757, 775, 798, 856, 890, 899, 907, 912, 920, 928, 933, 952, 1007, 1053, 1099, 1105-1117, 1124, 1129-1132, 1146, 1151-1154, 1168, 1183, 1542 | Various | Click/release detection |
| DRAW.BAS | 175, 192 | Main loop | B1, B2, B3 | Idle detection |
| GUI/STATUS.BM | 235-237, 389, 393 | STATUS_* | B1, B2, B3 | Button indicator |
| GUI/PALETTE-STRIP.BM | 395, 400 | PALETTE_STRIP_* | B1, B2 | Click handling |

### Other Fields

| File | Line | Function | Field | Description |
|------|------|----------|-------|-------------|
| INPUT/MOUSE.BM | 28, 610-619 | Various | B3_CLICK_TIME | Double-click detection |
| INPUT/MOUSE.BM | 1105-1108, 1129-1132, 1151-1154 | MOUSE_input_handler | DRAG | Drag direction tracking |
| GUI/STATUS.BM | 242 | STATUS_render | DRAG | Drag indicator |
| GUI/TOOLBAR.BM | 157-163, 171, 229, 281, 286-287, 308, 392 | TOOLBAR_handle_* | DEFERRED_ACTION, TOOLBAR_CLICKED | Deferred processing |
| INPUT/MOUSE.BM | 1762-1784 | MOUSE_input_handler_loop | DEFERRED_ACTION | Action execution |

---

## 4. OS-SPECIFIC WORKAROUNDS ($IF MAC THEN)

| File | Line | Function | Issue | Workaround |
|------|------|----------|-------|------------|
| INPUT/MOUSE.BM | 93-105 | MOUSE_input_handler | SDL2 trackpad tap-to-click loses button state after drain | Capture button presses DURING _MOUSEINPUT drain loop |
| INPUT/MOUSE.BM | 146-150 | MOUSE_input_handler | Same as above | Use captured OR current state |
| INPUT/MOUSE.BM | 241-250 | MOUSE_input_handler | Same as above (normal mode) | Same workaround |
| INPUT/MOUSE.BM | 306-310 | MOUSE_input_handler | Same as above | Same workaround |
| INPUT/MOUSE.BM | 545-548 | MOUSE_input_handler | _KEYDOWN unreliable for Option key | Use MAC_ALT_HELD% from _KEYHIT tracking |
| INPUT/MOUSE.BM | 780-783, 802-805, 849-852 | MOUSE_input_handler | Same ALT key issue | Same workaround |
| INPUT/MOUSE.BM | 1199, 1228 | MOUSE_input_handler | Same ALT key issue | Same workaround |
| INPUT/KEYBOARD.BM | 465-468 | KEYBOARD_input_handler | Same ALT key issue | Same workaround |
| INPUT/KEYBOARD.BM | 1249, 1303, 1442, 1484 | Various | Same ALT key issue | Same workaround |
| INPUT/KEYBOARD.BM | 1561, 1610 | KEYBOARD_layers | Same ALT key issue | Same workaround |
| DRAW.BAS | 19-30 | Module level | macOS .app bundle file association | Check DRAW_OPEN_FILE env var first |
| DRAW.BAS | 106-113 | Main loop | _KEYDOWN unreliable for Option key | Track ALT via _KEYHIT press/release |
| DRAW.BAS | 122-127 | Main loop | Same ALT key issue | Use MAC_ALT_HELD% |
| TOOLS/MOVE.BM | 132-135, 267-270, 427-430 | MOVE_* | Same ALT key issue | Same workaround |
| TOOLS/DRW.BM | 511 | DRW_* | Same ALT key issue | Use MAC_ALT_HELD% |
| GUI/LAYERS.BM | 1303-1307 | LAYER_PANEL_handle_click | Same ALT key issue | Same workaround |
| GUI/MENUBAR.BM | 731-736 | MENUBAR_handle_key | Same ALT key issue | Same workaround |
| OUTPUT/SCREEN.BM | 1033-1036 | POINTER_update | Same ALT key issue | Same workaround |
| _COMMON.BI | 95-97 | Module level | MAC_ALT_HELD% declaration | DIM SHARED for tracking |

---

## 5. GUI WIDGET HANDLERS

### Toolbar (GUI/TOOLBAR.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 150-392 | TOOLBAR_handle_click | MOUSE.B1% | Left-click tool selection | GUI_NEEDS_REDRAW% |
| 520-560 | TOOLBAR_handle_right_click | MOUSE.B2% | Right-click alternate modes | GUI_NEEDS_REDRAW% |
| 575-590 | TOOLBAR_handle_middle_click | MOUSE.B3% | Middle-click custom font | GUI_NEEDS_REDRAW% |
| 420-450 | TOOLBAR_is_over_area% | MOUSE.RAW_X/Y | Hover detection | No |
| 460-480 | TOOLBAR_is_over_button% | MOUSE.RAW_X/Y | Button hit test | No |

### Status Bar (GUI/STATUS.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 350-440 | STATUS_handle_click | MOUSE.B1%, B2% | FG/BG color clicks | GUI_NEEDS_REDRAW% |

### Palette Strip (GUI/PALETTE-STRIP.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 380-420 | PALETTE_STRIP_handle_click | MOUSE.B1%, B2% | Color selection | GUI_NEEDS_REDRAW% |
| 430-500 | PALETTE_STRIP_handle_wheel | MOUSE.SW% | Scroll palette | GUI_NEEDS_REDRAW% |
| 500-700 | PALETTE_MENU_* | Various | Dropdown menu handling | GUI_NEEDS_REDRAW%, SCENE_DIRTY% |

### Layer Panel (GUI/LAYERS.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 1180-1500 | LAYER_PANEL_handle_click | MOUSE.B1%, B2% | Layer selection, visibility, etc | GUI_NEEDS_REDRAW% |
| 1500-1600 | LAYER_PANEL_handle_wheel | MOUSE.SW% | Scroll layer list or adjust opacity | GUI_NEEDS_REDRAW% |
| 1600-1700 | LAYER_PANEL_handle_drag | MOUSE.B1% | Drag reorder layers | GUI_NEEDS_REDRAW% |
| 800-900 | LAYER_PANEL_handle_vis_swipe | MOUSE.B1% | Visibility swipe | GUI_NEEDS_REDRAW% |

### Menu Bar (GUI/MENUBAR.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 550-700 | MENUBAR_handle_click | MOUSE.B1% | Menu item clicks | GUI_NEEDS_REDRAW%, SCENE_DIRTY% |
| 700-800 | MENUBAR_handle_mouse_move | MOUSE.RAW_X/Y | Menu switching on hover | GUI_NEEDS_REDRAW%, SCENE_DIRTY% |
| 730-800 | MENUBAR_handle_key | _KEYDOWN | Alt tap, arrow keys, Enter, ESC | GUI_NEEDS_REDRAW%, SCENE_DIRTY% |

### Command Palette (GUI/COMMAND.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 200-400 | CMD_handle_click | MOUSE.B1% | Click item selection | GUI_NEEDS_REDRAW% |
| 400-600 | CMD_handle_key | INKEY$, _KEYDOWN | Search input, navigation | GUI_NEEDS_REDRAW% |

### Pointer/Cursor (GUI/POINTER.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 80-350 | POINTER_update | _MOUSEX/Y, _KEYDOWN, _MOUSEBUTTON | Cursor appearance logic | No |
| 360-1050 | POINTER_render | MOUSE.* | Cursor rendering | No |

---

## 6. TOOL-SPECIFIC HANDLERS

### Brush/Dot Tool (TOOLS/BRUSH.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 130-160 | BRUSH_draw | MOUSE.X/Y, OLD_X/Y, B1%, CON_X/Y | Stroke interpolation | SCENE_DIRTY% |
| 380-400 | (custom brush dialog) | _MESSAGEBOX | Dialog workflow | Yes |

### Marquee Tool (TOOLS/MARQUEE.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 150-400 | MARQUEE_start/update/end | MOUSE.X/Y | Rectangle selection | SCENE_DIRTY% |
| 180, 340 | MARQUEE_get_handle_at | MOUSE.X/Y | Resize handle detection | No |

### Move Tool (TOOLS/MOVE.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 130-450 | MOVE_start/update/apply | MOUSE.X/Y, _KEYDOWN(ALT/SHIFT) | Transform handling | GUI_NEEDS_REDRAW%, SCENE_DIRTY% |

### Zoom Tool (TOOLS/ZOOM.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 50-200 | ZOOM_* | MOUSE.B1%, MOUSE.SW% | Zoom in/out/region | GUI_NEEDS_REDRAW% |

### Image Import (TOOLS/IMAGE-IMPORT.BM)

| Line | Function | Input Type | Description | GUIRefresh |
|------|----------|------------|-------------|------------|
| 400-600 | IMAGE_IMPORT_* | MOUSE.X/Y, B1%, _KEYDOWN | Placement/resize/pan | GUI_NEEDS_REDRAW%, SCENE_DIRTY% |

---

## 7. COORDINATE TRANSFORMATION

### Screen → Canvas Transformation

Location: `INPUT/MOUSE.BM` lines 136-143 and 290-303

```qb64
' Calculate zoomed canvas position
zw& = SCRN.w& * SCRN.zoom!
zh& = SCRN.h& * SCRN.zoom!
dx% = (SCRN.w& - zw&) \ 2 + SCRN.offsetX%
dy% = (SCRN.h& - zh&) \ 2 + SCRN.offsetY%

' Offset for layer panel
IF LAYER_PANEL.visible% THEN dx% = dx% + CFG.LAYER_PANEL_WIDTH%

' Offset for menu bar
IF SCRN.showMenubar% AND MENU_BAR.visible% THEN dy% = dy% + MENU_BAR_HEIGHT

' Transform
MOUSE.X% = INT((rawX% - dx%) / SCRN.zoom!)
MOUSE.Y% = INT((rawY% - dy%) / SCRN.zoom!)

' Clamp to canvas bounds
IF MOUSE.X% < 0 THEN MOUSE.X% = 0
IF MOUSE.Y% < 0 THEN MOUSE.Y% = 0
IF MOUSE.X% >= SCRN.w& THEN MOUSE.X% = SCRN.w& - 1
IF MOUSE.Y% >= SCRN.h& THEN MOUSE.Y% = SCRN.h& - 1
```

### Canvas → Screen Transformation (for rendering)

Location: `OUTPUT/SCREEN.BM` lines 462-477, used throughout tool preview rendering

```qb64
dx% = (SCRN.w& - zw&) \ 2 + SCRN.offsetX%
dy% = (SCRN.h& - zh&) \ 2 + SCRN.offsetY%
IF LAYER_PANEL.visible% THEN dx% = dx% + CFG.LAYER_PANEL_WIDTH%
IF SCRN.showMenubar% AND MENU_BAR.visible% THEN dy% = dy% + MENU_BAR_HEIGHT

' Example: Convert canvas coord to screen for drawing
screen_x% = dx% + INT(canvas_x% * SCRN.zoom!)
screen_y% = dy% + INT(canvas_y% * SCRN.zoom!)
```

---

## 8. GUI REFRESH PATTERNS

### GUI_NEEDS_REDRAW%

Set when: Tool switch, color change, palette scroll, layer panel change, menu interaction
Effect: Forces GUI overlay re-render but can use scene cache

### SCENE_DIRTY%

Set when: Button held, key pressed, mouse wheel, SHIFT held, active tools (move/text/import), menu open
Effect: Forces full scene re-render including layer compositing

### SCENE_CHANGED%

Set when: Any action that modifies the scene state in current frame
Relation: `IF SCENE_CHANGED% THEN SCENE_DIRTY% = TRUE` (DRAW.BAS line 190)

---

## 9. SCATTERED/FRAGMENTED INPUT HANDLING

These are input handling locations that seem architecturally out of place:

| File | Line | Issue | Recommendation |
|------|------|-------|----------------|
| OUTPUT/SCREEN.BM | 1031-1036 | _KEYDOWN for SHIFT/CTRL/ALT in render path | Could be in pre-render pointer update call |
| OUTPUT/SCREEN.BM | 302-303, 1043, 1116-1117 | Direct _MOUSEX/_MOUSEY in render | Uses raw coords appropriately, but couples render to input API |
| GUI/POINTER.BM | 140 | _KEYDOWN(32) AND _MOUSEBUTTON(3) in cursor selection | Duplicates pan detection logic from MOUSE.BM |
| GUI/POINTER.BM | 492 | _MOUSEBUTTON(1) for painting detection | Could use MOUSE.B1% for consistency |
| TOOLS/BRUSH.BM | 153 | `IF CURRENT_TOOL% = TOOL_DOT AND MOUSE.B1% THEN` | Tool state check in brush drawing - appropriate but complex |

---

## 10. CSV EXPORT (Copy-Paste Ready)

```csv
Device,File,Line,Function,Description,GUIRefresh,OSWorkaround,CallDepth,FunctionLines
Mouse,INPUT/MOUSE.BM,14,MOUSE_init,Initializes MOUSE state object,No,No,1,16
Mouse,INPUT/MOUSE.BM,37,MOUSE_reset_buttons,Syncs button states after dialogs,No,No,2,20
Mouse,INPUT/MOUSE.BM,63,MOUSE_force_buttons_up,Forces all buttons UP sets SUPPRESS_FRAMES,No,No,2,14
Mouse,INPUT/MOUSE.BM,85,MOUSE_input_handler,Main mouse processing drain-then-process pattern,Yes,Yes (macOS),1,1676
Mouse,INPUT/MOUSE.BM,1762,MOUSE_input_handler_loop,Post-render cleanup deferred action processing,Yes,No,1,22
Mouse,INPUT/MOUSE.BM,39,MOUSE_reset_buttons,_MOUSEINPUT drain after dialogs,No,No,2,1
Mouse,INPUT/MOUSE.BM,65,MOUSE_force_buttons_up,_MOUSEINPUT drain after dialogs,No,No,2,1
Mouse,INPUT/MOUSE.BM,98-106,MOUSE_input_handler,_MOUSEINPUT drain with wheel accumulation macOS button capture,No,Yes,1,8
Mouse,INPUT/MOUSE.BM,116-117,MOUSE_input_handler,_MOUSEX _MOUSEY raw position capture import mode,No,No,1,2
Mouse,INPUT/MOUSE.BM,270-271,MOUSE_input_handler,_MOUSEX _MOUSEY raw position capture normal mode,No,No,1,2
Mouse,INPUT/MOUSE.BM,45-47,MOUSE_reset_buttons,_MOUSEBUTTON(1-3) hardware state read,No,No,2,3
Mouse,INPUT/MOUSE.BM,99,MOUSE_input_handler,_MOUSEWHEEL accumulation during drain,No,No,1,1
Mouse,INPUT/MOUSE.BM,136-143,MOUSE_input_handler,Screen to canvas coordinate transformation,No,No,1,8
Mouse,INPUT/MOUSE.BM,290-303,MOUSE_input_handler,Screen to canvas coord + grid snap + clamp,No,No,1,14
Keyboard,INPUT/KEYBOARD.BM,15,KEYBOARD_colors,Color selection via number keys 0-9,GUI_NEEDS_REDRAW%,No,2,40
Keyboard,INPUT/KEYBOARD.BM,55,KEYBOARD_tools,Tool switching via letter keys,GUI_NEEDS_REDRAW%,No,2,298
Keyboard,INPUT/KEYBOARD.BM,353,KEYBOARD_brush_size,Brush size with bracket and F1-F4 keys,GUI_NEEDS_REDRAW%,No,2,21
Keyboard,INPUT/KEYBOARD.BM,374,KEYBOARD_assistants,Toggle assistants via F6-F8 tilde backslash,GUI_NEEDS_REDRAW%,No,2,23
Keyboard,INPUT/KEYBOARD.BM,397,KEYBOARD_input_handler,Main keyboard processing,Yes,Yes (macOS),1,471
Keyboard,INPUT/KEYBOARD.BM,1592,KEYBOARD_layers,Layer keyboard shortcuts,GUI_NEEDS_REDRAW%,Yes (macOS),2,196
Keyboard,INPUT/KEYBOARD.BM,1788,KEYBOARD_input_handler_loop,Post-render keyboard cleanup,No,No,1,1
Keyboard,DRAW.BAS,104,Main loop,k& = _KEYHIT primary key event capture,No,No,0,1
Keyboard,DRAW.BAS,109-111,Main loop,macOS ALT tracking via _KEYHIT,No,Yes,0,3
Keyboard,DRAW.BAS,120-121,Main loop,_KEYDOWN for CTRL SHIFT display scale,No,No,0,2
Keyboard,DRAW.BAS,182,Main loop,_KEYDOWN for SHIFT held idle detection,SCENE_CHANGED%,No,0,1
Mouse,TOOLS/BRUSH.BM,391,dialog,_MOUSEINPUT drain after custom brush dialog,No,No,2,1
Mouse,TOOLS/SAVE.BM,43,SAVE_image,_MOUSEINPUT drain after save dialog,No,No,2,1
Mouse,TOOLS/LOAD.BM,39,LOAD_image,_MOUSEINPUT drain after load dialog,No,No,2,1
Mouse,TOOLS/DRW.BM,451,DRW_save_dialog,_MOUSEINPUT drain after DRW dialog,No,No,2,1
Mouse,GUI/LAYERS.BM,354,LAYERS_rename,_MOUSEINPUT drain after rename dialog,No,No,3,1
Mouse,GUI/TOOLBAR.BM,356,TOOLBAR_handle_click,_MOUSEINPUT drain after toolbar action dialog,No,No,2,1
Mouse,GUI/PALETTE-PICKER.BM,162,PALETTE_PICKER_show,_MOUSEINPUT modal dialog loop,No,No,2,1
Mouse,OUTPUT/SCREEN.BM,127,SCREEN_set_display_scale,_MOUSEINPUT drain after resize,No,No,2,1
Mouse,OUTPUT/SCREEN.BM,302-303,SCREEN_set_display_scale,_MOUSEX _MOUSEY raw position,No,No,2,2
Mouse,OUTPUT/SCREEN.BM,1043,SCREEN_render,_MOUSEX _MOUSEY for crosshair,No,No,1,1
Mouse,GUI/POINTER.BM,83-84,POINTER_update,_MOUSEX _MOUSEY for cursor position,No,No,2,2
Mouse,GUI/POINTER.BM,140,POINTER_update,_KEYDOWN(32) _MOUSEBUTTON(3) pan detection,No,No,2,1
Mouse,GUI/POINTER.BM,492,POINTER_draw_preview,_MOUSEBUTTON(1) painting detection,No,No,2,1
Mouse,DRAW.BAS,175,Main loop,MOUSE.B1 B2 B3 idle detection,SCENE_CHANGED%,No,0,1
Mouse,DRAW.BAS,176,Main loop,MOUSE.RAW_X RAW_Y idle detection,GUI_NEEDS_REDRAW%,No,0,1
Mouse,DRAW.BAS,183,Main loop,MOUSE.SW% wheel idle detection,SCENE_CHANGED%,No,0,1
Mouse,GUI/STATUS.BM,185,STATUS_render,MOUSE.X Y coordinate display,No,No,2,1
Mouse,GUI/STATUS.BM,235-237,STATUS_render,MOUSE.B1 B2 B3 button indicators,No,No,2,3
Mouse,GUI/PALETTE-STRIP.BM,150-151,PALETTE_STRIP_render,MOUSE.RAW_X RAW_Y hover detection,No,No,2,2
Mouse,GUI/CROSSHAIR.BM,39-40,CROSSHAIR_render,MOUSE.X Y for crosshair position,No,No,2,2
Mouse,TOOLS/MARQUEE.BM,182,MARQUEE_update,MOUSE.X Y handle detection,No,No,3,1
Mouse,TOOLS/POLY-LINE.BM,16,POLY_LINE preview,MOUSE.X Y for line preview,No,No,2,1
```

---

## 11. KEY ARCHITECTURE NOTES

1. **Drain-Then-Process Pattern**: Mouse events are drained from the buffer first, accumulating wheel delta, then processed once with final state. This avoids per-event overhead.

2. **macOS Trackpad Workaround**: SDL2 on macOS loses button state after `_MOUSEINPUT` drain. The workaround captures button presses DURING the drain loop.

3. **macOS ALT Key Workaround**: `_KEYDOWN()` is unreliable for Option key on macOS. A global `MAC_ALT_HELD%` flag is maintained via `_KEYHIT` press/release detection in the main loop.

4. **Deferred Actions**: File dialogs are deferred to `MOUSE_input_handler_loop` (post-render) to avoid calling them from within the input processing loop.

5. **Button Suppression**: After native dialogs close, `SUPPRESS_FRAMES%` prevents phantom clicks from late SDL events.

6. **GUI Priority Chain**: Command Palette → Menu Bar → Layer Panel → Toolbar → Status Bar → Palette Strip → Canvas

7. **Two Coordinate Systems**: 
   - `MOUSE.RAW_X/Y`: Screen pixels (for GUI)
   - `MOUSE.X/Y`: Canvas pixels (for drawing)

8. **Idle Detection**: Frame rendering is skipped when nothing changed (saves CPU). Multiple flags track different state changes.
