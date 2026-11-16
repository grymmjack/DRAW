#!/bin/bash
# =============================================================================
# swatches-select.sh — QA test: selecting swatches (Swatches phase 2).
#   click = select it alone (+ FG) · Shift+click = range from the anchor
#   (breaks skipped) · Ctrl+click = toggle · a box dragged from an empty
#   place selects what it touches (Ctrl+box adds) · a click on an empty place
#   clears · Ctrl+A over the panel = all (over the canvas the canvas keeps it)
#   · Esc over the panel = none · right-click = BG, selection untouched.
# Fixture QA/fixtures/swatches-edit.gpl (8 columns): row 0 = 1-8, row 1 = 9-12
# then a row break (13), row 2 = 14-21 (20 an empty cell).
# SWATS: <selected> <anchor> <i> ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-edit.gpl SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"

info "=== Swatches: selection ==="
dk_begin
sw_read
sw_expect "entries" "$SW_N" 21
sw_sel; sw_expect "nothing selected at the start" "$SS_N" 0

sw_click 3; sw_sel
sw_expect "click 3: selected" "$SS_N" 1
sw_expect "click 3: the selection" "$SS_LIST" "3"
sw_read; sw_expect "click 3: FG" "$SW_FG" 3

sw_click 10 shift; sw_sel
sw_expect "Shift+click 10: range 3..10" "$SS_LIST" "3 4 5 6 7 8 9 10"
sw_read; sw_expect "Shift+click leaves the FG" "$SW_FG" 3

sw_click 5 ctrl; sw_sel
sw_expect "Ctrl+click 5 toggles it off" "$SS_LIST" "3 4 6 7 8 9 10"
sw_click 16 ctrl; sw_sel
sw_expect "Ctrl+click 16 adds it" "$SS_LIST" "3 4 6 7 8 9 10 16"
sw_expect "Ctrl+click sets the anchor" "$SS_ANCHOR" 16

# Shift+click across the row break: the break is not selected
sw_click 11; sw_click 15 shift; sw_sel
sw_expect "Shift+click 11..15 skips the break (13)" "$SS_LIST" "11 12 14 15"

# right-click: BG, the selection stays
sw_click 2 right; sw_sel; sw_read
sw_expect "right-click 2: BG" "$SW_BG" 2
sw_expect "right-click keeps the selection" "$SS_LIST" "11 12 14 15"

# a click on an empty place clears
sw_empty_xy; click "$EX" "$EY"; dk_settle; sw_sel
sw_expect "a click on an empty place clears" "$SS_N" 0

# a box from the empty place (row 1, col 6) up-left to entry 3 (row 0, col 2)
sw_empty_xy; sw_cell 3
dk_drag "$EX" "$EY" $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )) 6; dk_settle; sw_sel
sw_expect "box: rows 0-1, columns 2-6" "$SS_LIST" "3 4 5 6 7 11 12"
screenshot "swatches-select-box"

# Ctrl+box adds: from the empty place down to entry 15 (row 2, col 1)
sw_empty_xy; sw_cell 15
with_mods ctrl dk_drag "$EX" "$EY" $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )) 6; dk_settle; sw_sel
sw_expect "Ctrl+box adds rows 1-2, columns 1-6" "$SS_LIST" "3 4 5 6 7 10 11 12 15 16 17 18 19 20"

# Ctrl+A over the panel: every entry but the break
sw_cell 1; hover $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); sleep 0.2
key ctrl+a; dk_settle; sw_sel
sw_expect "Ctrl+A over the panel selects all but the break" "$SS_N" 20
sw_read; sw_expect "Ctrl+A keeps the FG (11, the last plain click)" "$SW_FG" 11

# Esc over the panel: none
key Escape; dk_settle; sw_sel
sw_expect "Esc over the panel clears" "$SS_N" 0

# over the canvas, Ctrl+A is the canvas's
dk_park; key ctrl+a; dk_settle; sw_sel
sw_expect "Ctrl+A over the canvas leaves the swatches alone" "$SS_N" 0
key Escape; dk_settle
assert_window_exists
info "=== Swatches: selection PASSED ==="
