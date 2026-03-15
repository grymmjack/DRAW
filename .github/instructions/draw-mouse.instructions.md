---
applyTo: "**/MOUSE.BM, **/MOUSE.BI"
---

# DRAW — Mouse Input System

**Files**: `INPUT/MOUSE.BI` (MOUSE_OBJ type), `INPUT/MOUSE.BM` (~2590 lines)

---

## MOUSE_OBJ Type

| Field                    | Type    | Purpose |
| ------------------------ | ------- | ------- |
| X, Y                     | INTEGER | Canvas coords (zoom/pan-adjusted, grid-snapped) |
| OLD_X, OLD_Y             | INTEGER | Previous frame canvas coords |
| RAW_X, RAW_Y             | INTEGER | Raw screen pixels (for GUI hit-testing) |
| UNSNAPPED_X, UNSNAPPED_Y | INTEGER | Canvas coords before grid snap (fill, picker) |
| B1, B2, B3               | INTEGER | Current button states |
| OLD_B1, OLD_B2, OLD_B3   | INTEGER | Previous frame states (transition detection) |
| UI_CHROME_CLICKED%         | INTEGER | GUI click flag — prevents canvas tool actions |
| DEFERRED_ACTION%         | INTEGER | Post-frame file dialog (0=none, 1=save, 2=import image, 3=open DRW, 4=export selection, 5=drawer slot import) |
| SUPPRESS_FRAMES%         | INTEGER | Frames to suppress input after dialog cleanup |

---

## Single-Frame Processing Flow

```
MOUSE_input_handler()
├── Special modes: REFIMG reposition / IMAGE_IMPORT direct polling
├── MOUSE_process_frame%()
│   ├── MOUSE_drain_update_state()            ← drain ALL _MOUSEINPUT, accumulate wheel,
│   │                                            convert screen→canvas, grid snap, clamp
│   ├── MOUSE_handle_suppress_frames%()       ← force buttons FALSE for N frames post-dialog
│   ├── MOUSE_handle_gui_early%()
│   │   ├── MOUSE_autocommit_move_if_click_on_gui()
│   │   ├── MOUSE_handle_command_palette_click%()
│   │   ├── MOUSE_handle_menubar_mouse_move()
│   │   ├── MOUSE_handle_menubar_click%()     ← sets UI_CHROME_CLICKED% on menu clicks
│   │   └── MOUSE_handle_palette_menu_close%()
│   ├── MOUSE_handle_symmetry_ctrl_click()
│   ├── MOUSE_update_draw_color()
│   ├── MOUSE_handle_gui_panels()
│   │   ├── MOUSE_handle_layer_panel()
│   │   ├── MOUSE_handle_toolbar_status_palette()  ← sets UI_CHROME_CLICKED% on GUI clicks
│   │   └── Ctrl+Shift+Click on panels → toggle dock side (left ↔ right)
│   ├── MOUSE_handle_alt_picker()
│   ├── MOUSE_handle_space_pan()
│   ├── MOUSE_handle_b3_dblclick_reset_zoom()
│   ├── MOUSE_handle_ui_autohide_restore()
│   ├── MOUSE_handle_panning()
│   ├── MOUSE_should_skip_tool_actions%()     ← checks UI_CHROME_CLICKED%, consumes OLD_B*,
│   │                                            resets flag when buttons released
│   └── MOUSE_handle_tool_phase()
│       ├── MOUSE_dispatch_tool_hold()
│       ├── MOUSE_dispatch_tool_release()     ← commits shapes, creates undo states
│       └── MOUSE_handle_right_click()
├── MOUSE_post_process()                      ← wheel events, marquee updates
│
MOUSE_input_handler_loop()                    ← post-render, end of main loop
├── Update OLD_X/Y, OLD_B1/B2/B3
└── Process DEFERRED_ACTION% (file dialogs)
```

---

## Key Mechanisms

### Drain-then-process pattern
`MOUSE_drain_update_state` consumes ALL queued `_MOUSEINPUT` events in a tight loop, then one processing pass runs against the final state snapshot. **Critical for performance** — processing every event individually would cause multiple draw operations per frame.

### SUPPRESS_FRAMES%
Set to 2 by `MOUSE_force_buttons_up` / `MOUSE_cleanup_after_dialog`. SDL2 produces spurious button events 1-2 frames after a GTK/native dialog closes when the window regains focus. This suppression catches them.

### DEFERRED_ACTION%
File dialogs (`_OPENFILEDIALOG$`, `_SAVEFILEDIALOG$`) block the main loop. Toolbar clicks set `MOUSE.DEFERRED_ACTION%`; the actual dialog opens in `MOUSE_input_handler_loop` after all mouse processing is complete, avoiding mid-processing state corruption.

Values: `1`=save, `2`=import image, `3`=open DRW project, `4`=export selection, `5`=drawer slot import

Drawer slot imports use the same deferred-dialog path: `Shift+Right Click` on a drawer slot queues action `5`, then `MOUSE_input_handler_loop` runs `DRAWER_run_deferred_action` after normal mouse processing finishes.

### Menubar Width Calculation
`MENUBAR_update_bar_geometry` subtracts toolbar width from screen width. Toolbar width:

```qb64
toolbarW% = (TB_BTN_W * scale% * TB_COLS) + (TB_BTN_PADDING * scale% * (TB_COLS - 1)) + 2
```

Always use `TB_COLS` — never hardcode the column count.
