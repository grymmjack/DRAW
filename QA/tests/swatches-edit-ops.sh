#!/bin/bash
# =============================================================================
# swatches-edit-ops.sh — QA test: every Swatches edit, its keys, and undoing
# them all back to the file as it was:
#   Ins = add the FG after the selection (nothing selected: at the end) ·
#   L = lock / unlock (over the canvas L stays the Line tool) · a locked
#   swatch survives Del · DUPLICATE · REMOVE DUPLICATES (a second time: no
#   change, no undo step) · INSERT EMPTY CELL · INSERT ROW BREAK · Ctrl+D ·
#   Ctrl+Z back to the start.
# Fixture swatches-edit.gpl: 1-8 reds 3C..EB, 9-12 greens (12 locked), 13
# break, 14-19 blues, 20 empty, 21 Gold FFC800.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-edit.gpl SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"

info "=== Swatches: every edit ==="
sw_isolate
dk_begin
sw_read; sw_expect "entries" "$SW_N" 21
H0=$(sw_hexes)

# A. Ins after the selection: Gold (21) is the FG and the selection
sw_click 21; sw_hover_panel; key Insert; dk_settle; sw_read; sw_sel
sw_expect "Ins: entries" "$SW_N" 22
sw_cell 22; sw_expect "Ins: the FG (Gold) after 21" "$C_HEX" "FFC800"
sw_expect "Ins: the new swatch is selected" "$SS_LIST" "22"

# B. Ins with nothing selected: at the end
sw_click 1; key Escape; dk_settle
sw_hover_panel; key Insert; dk_settle; sw_read
sw_expect "Ins (nothing selected): entries" "$SW_N" 23
sw_cell 23; sw_expect "Ins (nothing selected): Red 1 at the end" "$C_HEX" "3C0000"

# C. L locks / unlocks; over the canvas L is not the panel's
sw_click 2; sw_hover_panel; key l; dk_settle; sw_cell 2
sw_expect "L locks 2" "$C_FLAGS" 1
key l; dk_settle; sw_cell 2
sw_expect "L again unlocks it" "$C_FLAGS" 0
dk_park; key l; dk_settle; sw_cell 2
sw_expect "L over the canvas leaves the swatch" "$C_FLAGS" 0
wake_draw; key b; dk_settle

# D. lock 2, then Del 1-3: 2 stays
sw_click 2; sw_hover_panel; key l; dk_settle
sw_click 1; sw_click 3 shift
sw_hover_panel; key Delete; dk_settle; sw_read
sw_expect "Del 1-3 with 2 locked: entries" "$SW_N" 21
sw_cell 1; sw_expect "the locked Red 2 stays (now 1)" "$C_HEX" "550000"
sw_expect "... still locked" "$C_FLAGS" 1
sw_cell 2; sw_expect "then Red 4" "$C_HEX" "870000"
# now: 1 R2(L) 2 R4 3 R5 4 R6 5 R7 6 R8 7-10 greens (10 L) 11 break 12-17 blues 18 empty 19 Gold 20 Gold 21 Red 1

# E. DUPLICATE blue 1 + blue 3: the copies right after, selected
sw_click 12; sw_click 14 ctrl
sw_menu_edit; sw_menu_click 206; sw_read; sw_sel
sw_expect "DUPLICATE: entries" "$SW_N" 23
sw_expect "DUPLICATE: the copies are selected" "$SS_LIST" "15 16"
sw_cell 15; sw_expect "copy of blue 1" "$C_HEX" "00003C"
sw_cell 16; sw_expect "copy of blue 3" "$C_HEX" "000082"
sw_cell 17; sw_expect "blue 4 after the copies" "$C_HEX" "0000A5"

# F. REMOVE DUPLICATES: the two copies and the second Gold
sw_edit_state; U0=$SE_UNDO
sw_menu_edit; sw_menu_click 207; sw_read
sw_expect "REMOVE DUPLICATES: entries" "$SW_N" 20
sw_edit_state; sw_expect "... one undo step" "$SE_UNDO" $(( U0 + 1 ))
# G. again: nothing to remove, no undo step
sw_menu_edit; sw_menu_click 207; sw_read; sw_edit_state
sw_expect "REMOVE DUPLICATES again: entries" "$SW_N" 20
sw_expect "... no undo step" "$SE_UNDO" $(( U0 + 1 ))

# H. INSERT EMPTY CELL before Red 5 (3)
sw_click 3; sw_menu_edit; sw_menu_click 204; sw_read
sw_expect "INSERT EMPTY CELL: entries" "$SW_N" 21
sw_cell 3; sw_expect "entry 3 is an empty cell" "$C_KIND" 1
sw_cell 4; sw_expect "Red 5 moved to 4" "$C_HEX" "A00000"

# I. INSERT ROW BREAK before Red 6 (5): it starts a new row
sw_cell 4; Y4=$C_Y
sw_click 5; sw_menu_edit; sw_menu_click 205; sw_read
sw_expect "INSERT ROW BREAK: entries" "$SW_N" 22
sw_cell 6; sw_expect "Red 6 is entry 6" "$C_HEX" "B90000"
if (( C_Y > Y4 )); then pass "Red 6 starts the next row (y $Y4 -> $C_Y)"; else fail "Red 6 on the same row (y $C_Y, row above $Y4)"; fi
screenshot "swatches-edit-ops"

# J. Ctrl+D over the panel
sw_click 2; sw_hover_panel; key ctrl+d; dk_settle; sw_sel
sw_expect "Ctrl+D over the panel: none selected" "$SS_N" 0

# K. undo everything: back to the file
sw_edit_state; N=$SE_UNDO; info "$N undo steps"
sw_hover_panel
for (( k = 0; k < N; k++ )); do key ctrl+z; dk_settle; done
sw_read; sw_edit_state
sw_expect "undo all: no steps left" "$SE_UNDO" 0
sw_expect "undo all: entries" "$SW_N" 21
sw_expect "undo all: every swatch as in the file" "$(sw_hexes)" "$H0"
assert_window_exists
info "=== Swatches: every edit PASSED ==="
