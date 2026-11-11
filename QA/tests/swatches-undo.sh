#!/bin/bash
# =============================================================================
# swatches-undo.sh — QA test: deleting swatches, undo / redo, and the copy in
# My Swatches (Swatches phase 2):
#   - the first edit of a set that is not yours (here a fixture) saves a copy
#     in My Swatches and edits that; the original file never changes
#   - Del with the pointer on the panel deletes the selected swatches;
#     locked ones stay; nothing selected = nothing happens
#   - Ctrl+Z / Ctrl+Y over the panel undo / redo; over the canvas they are
#     the canvas's (the swatches stay)
#   - every edit is saved: a restart shows the edited copy
# Runs on a scratch XDG_DATA_HOME (sw_isolate): never Rick's real data.
# The set is put in the QA cfg (sw_cfg_set), so DRAW saves the switch to the copy.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
FIX="$DRAW_ROOT/QA/fixtures/swatches-edit.gpl"
SUM0=$(md5sum < "$FIX")

info "=== Swatches: delete, undo / redo, the My Swatches copy ==="
sw_isolate SWATCHES_SET=QA/fixtures/swatches-edit.gpl # in the cfg, not --option: DRAW saves it
dk_begin
sw_read; sw_expect "entries" "$SW_N" 21
sw_edit_state
sw_expect "start: undo steps" "$SE_UNDO" 0
sw_expect "start: the fixture is not in My Swatches" "$SE_MINE" 0

# nothing selected: Del does nothing
sw_hover_panel; key Delete; dk_settle; sw_read; sw_edit_state
sw_expect "Del with nothing selected: entries" "$SW_N" 21
sw_expect "Del with nothing selected: no undo step" "$SE_UNDO" 0

# delete 2 and 4
sw_click 2; sw_click 4 ctrl
sw_hover_panel; key Delete; dk_settle; sw_read; sw_edit_state
sw_expect "Del: entries" "$SW_N" 19
sw_expect "Del: one undo step" "$SE_UNDO" 1
sw_expect "Del: now editing a copy in My Swatches" "$SE_MINE" 1
COPY="$SW_MINE/QA Edit.gpl"
if [[ -f "$COPY" ]]; then pass "the copy is $COPY"; else fail "no copy at $COPY ($(command ls "$SW_MINE" 2>&1))"; fi
if [[ "$SW_KEY" == *"/SWATCHES/QA Edit.gpl" ]]; then pass "the panel shows the copy"; else fail "the panel shows $SW_KEY"; fi
if ! grep -q "Red 2" "$COPY" && ! grep -q "Red 4" "$COPY" && grep -q "Red 3" "$COPY"; then pass "the copy was saved without Red 2 and Red 4"; else fail "the saved copy still has Red 2 / Red 4 (or lost Red 3)"; fi
if [[ "$(md5sum < "$FIX")" == "$SUM0" ]]; then pass "the fixture file is unchanged"; else fail "the fixture file changed"; fi
sw_sel; sw_expect "Del: nothing selected after" "$SS_N" 0

# undo / redo over the panel
sw_hover_panel; key ctrl+z; dk_settle; sw_read; sw_edit_state
sw_expect "Ctrl+Z: entries back" "$SW_N" 21
sw_expect "Ctrl+Z: a redo step" "$SE_REDO" 1
sw_expect "Ctrl+Z: no undo step left" "$SE_UNDO" 0
if grep -q "Red 2" "$COPY"; then pass "undo was saved (Red 2 is back in the copy)"; else fail "the copy still lacks Red 2 after undo"; fi
sw_cell 2; sw_expect "Ctrl+Z: entry 2 is Red 2 again" "$C_HEX" "550000"
key ctrl+y; dk_settle; sw_read; sw_edit_state
sw_expect "Ctrl+Y: entries" "$SW_N" 19
sw_expect "Ctrl+Y: undo step back" "$SE_UNDO" 1
sw_hover_panel; key ctrl+z; dk_settle; sw_read; key ctrl+y; dk_settle; sw_read
sw_expect "undo + redo again" "$SW_N" 19
key ctrl+y; dk_settle; sw_read
sw_expect "Ctrl+Y with nothing to redo changes nothing" "$SW_N" 19

# over the canvas, Ctrl+Z is the canvas's
dk_park; key ctrl+z; dk_settle; sw_read
sw_expect "Ctrl+Z over the canvas leaves the swatches" "$SW_N" 19

# a locked swatch stays: after the delete, Green 3 is 9, locked Green 4 is 10
sw_cell 10; sw_expect "entry 10 is the locked Green 4" "$C_HEX" "00D200"
sw_click 9; sw_click 10 ctrl
sw_hover_panel; key Delete; dk_settle; sw_read
sw_expect "Del of 9 + locked 10: only 9 goes" "$SW_N" 18
sw_cell 9; sw_expect "the locked Green 4 is still there (now 9)" "$C_HEX" "00D200"

# Del over the canvas with swatches selected: not the swatches
sw_click 1
dk_park; key Delete; dk_settle; sw_read
sw_expect "Del over the canvas leaves the swatches" "$SW_N" 18

# a restart shows the saved copy
sw_relaunch_saved
dk_begin
sw_read
sw_expect "after a restart: entries" "$SW_N" 18
if [[ "$SW_KEY" == *"/SWATCHES/QA Edit.gpl" ]]; then pass "after a restart: the copy is the set"; else fail "after a restart the set is $SW_KEY"; fi
sw_edit_state; sw_expect "after a restart: no undo steps" "$SE_UNDO" 0
sw_hover_panel; key ctrl+z; dk_settle; sw_read
sw_expect "Ctrl+Z after a restart changes nothing" "$SW_N" 18
if [[ "$(md5sum < "$FIX")" == "$SUM0" ]]; then pass "the fixture file is still unchanged"; else fail "the fixture file changed"; fi
assert_window_exists
info "=== Swatches: delete, undo / redo PASSED ==="
