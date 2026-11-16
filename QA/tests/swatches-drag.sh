#!/bin/bash
# =============================================================================
# swatches-drag.sh — QA test: drag the selected swatches to move them, Ctrl+drag
# to copy them:
#   - a click (no drag) on a selected swatch selects it alone; Ctrl+click on a
#     selected one unselects it - both happen on the release
#   - while dragging, a marker shows where they land (SWATD drop index)
#   - a drop where they already are, or off the panel, changes nothing (no undo
#     step, no My Swatches copy)
#   - one swatch moves; scattered ones land together; a locked swatch keeps
#     its place; one Ctrl+Z puts them back
#   - Ctrl+drag copies; the copies become the selection
# Fixture swatches-edit.gpl: 1-8 reds 3C..EB (Red 1-8), 9-12 greens (12 locked),
# 13 break, 14-19 blues, 20 empty, 21 Gold FFC800.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"

info "=== Swatches: drag to move / copy ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-edit.gpl
dk_begin
sw_read; sw_expect "entries" "$SW_N" 21
H0=$(sw_hexes)

# A. clicks on selected swatches happen on the release
sw_click 1; sw_click 3 shift
sw_click 2; sw_sel; sw_expect "click a selected swatch (no drag): it alone" "$SS_LIST" "2"
sw_click 1 ctrl; sw_sel; sw_expect "Ctrl+click adds 1" "$SS_LIST" "1 2"
sw_click 2 ctrl; sw_sel; sw_expect "Ctrl+click a selected one (no drag) unselects it" "$SS_LIST" "1"

# B. a drop where it already is: nothing
sw_click 3; sw_left_of 4; sw_drag_entry 3
sw_expect "drag 3 to before 4: dragging" "$SD_ON" 1
sw_expect "... the drop is before 4" "$SD_DROP" 4
sw_read; sw_edit_state
sw_expect "a drop in place: every swatch as it was" "$(sw_hexes)" "$H0"
sw_expect "... no undo step" "$SE_UNDO" 0
sw_expect "... no My Swatches copy" "$SE_MINE" 0
sw_dragstate; sw_expect "the drag is over" "$SD_ON" 0

# C. off the panel: nothing
dk_scr; sw_cell 3; sw_drag_hold $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )) $(( (CAN_LX + CAN_RX) / 2 )) $(( DOCK_BOT - 40 ))
sw_expect "over the canvas: no drop" "$SD_DROP" 0
sw_read; sw_edit_state
sw_expect "dropped on the canvas: every swatch as it was" "$(sw_hexes)" "$H0"
sw_expect "... no undo step" "$SE_UNDO" 0

# D. one swatch: Red 1 after Red 4
sw_click 1; sw_right_of 4; sw_drag_entry 1 "swatches-drag-marker"
sw_expect "drag 1 to after 4: the drop is before 5" "$SD_DROP" 5
sw_read; sw_edit_state; sw_sel
sw_cell 4; sw_expect "Red 1 is now 4" "$C_HEX" "3C0000"
sw_cell 1; sw_expect "Red 2 is now 1" "$C_HEX" "550000"
sw_expect "the moved swatch stays selected" "$SS_LIST" "4"
sw_expect "one undo step" "$SE_UNDO" 1
sw_expect "editing the My Swatches copy" "$SE_MINE" 1
sw_hover_panel; key ctrl+z; dk_settle; sw_read
sw_expect "Ctrl+Z: back as it was" "$(sw_hexes)" "$H0"

# E. scattered (Red 2, Red 6, Blue 2) land together before Green 1; the
# locked Green 4 keeps its place (12)
sw_click 2; sw_click 6 ctrl; sw_click 15 ctrl
sw_left_of 9; sw_drag_entry 6
sw_expect "scattered: the drop is before 9" "$SD_DROP" 9
sw_read; sw_sel
sw_expect "scattered: the order" "$(sw_hexes)" "3C0000 6E0000 870000 A00000 D20000 EB0000 550000 B90000 00005F 003C00 006E00 00D200 00A000 | 00003C 000082 0000A5 0000C8 0000EB - FFC800"
sw_expect "scattered: they stay selected, together" "$SS_LIST" "7 8 9"
sw_cell 12; sw_expect "the locked Green 4 is still 12" "$C_HEX" "00D200"
sw_expect "... still locked" "$C_FLAGS" 1
sw_hover_panel; key ctrl+z; dk_settle; sw_read
sw_expect "Ctrl+Z: back as it was" "$(sw_hexes)" "$H0"

# F. a selected locked swatch does not move with the others
sw_click 11; sw_click 12 ctrl
sw_right_of 21; sw_drag_entry 11
sw_read
sw_cell 12; sw_expect "dragging with a locked swatch selected: it stays 12" "$C_HEX" "00D200"
sw_cell 21; sw_expect "... Green 3 went to the end" "$C_HEX" "00A000"
sw_hover_panel; key ctrl+z; dk_settle; sw_read
sw_expect "Ctrl+Z: back as it was" "$(sw_hexes)" "$H0"

# G. Ctrl+drag copies Gold to the start
sw_click 21; sw_left_of 1
with_mods ctrl sw_drag_entry 21
sw_expect "Ctrl+drag: the drop is before 1" "$SD_DROP" 1
sw_read; sw_sel; sw_edit_state
sw_expect "Ctrl+drag: entries" "$SW_N" 22
sw_cell 1; sw_expect "the copy is 1" "$C_HEX" "FFC800"
sw_cell 22; sw_expect "the original is still there (22)" "$C_HEX" "FFC800"
sw_expect "the copy is the selection" "$SS_LIST" "1"
sw_hover_panel; key ctrl+z; dk_settle; sw_read
sw_expect "Ctrl+Z: back as it was" "$(sw_hexes)" "$H0"
assert_window_exists
info "=== Swatches: drag to move / copy PASSED ==="
