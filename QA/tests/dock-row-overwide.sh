#!/bin/bash
# =============================================================================
# dock-row-overwide.sh — QA test: dragging a row slot's edge when the row's set
# widths add up to more than the row (Rick 2026-11-16, screenshot: "I cannot
# drag the pane to the right more - i start dragging here and it resets to the
# left side, but jumps to the right"). His workspace had BOTTOM.1 =
# editbar@868 | advbar@1837 in a ~1280 px row (saved in a wider window; here 48 px high so both bars fit QA's narrower row): the
# row shrinks both in proportion, and the drag's first frame (the edit bar's
# set width = the width it shows) threw the edge far left.
#   - the same row: edit bar + advanced bar along the bottom, both over-wide
#   - press on the edit bar's right edge, move right 30 px (held): the slot is
#     30 px wider, not narrower (the edge stays under the pointer)
#   - on to +60, then back to -15 (its minimum is near): still under the pointer; the advanced bar
#     gives way / takes it back
#   - after the drop: the row's slots fit the row
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;layers DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_BOTTOM_1=HEIGHT:48;editbar@868|advbar@1837
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock rows: an edge drag in an over-wide row ==="
dk_begin

slot_of() { dk_p "$1"; dk_slot "$P_SLOT"; }
held_read() { sleep 0.7; slot_of "$1"; } # (no hover: the button is held)

slot_of editbar; dk_col "$S_COL"
info "row: side $C_SIDE x $C_X w $C_W; edit bar slot $S_X w $S_W"
E_X=$S_X; W0=$S_W
slot_of advbar; A0=$S_W; AX0=$S_X
info "advanced bar slot $AX0 w $A0"
(( C_SIDE == 4 && W0 > 0 && A0 > 0 )) && pass "edit bar + advanced bar in a bottom row ($W0 + $A0 of $C_W px)" || { fail "not the row [$(dk_tree)] $(grep -E "^(COL|SLOT) " "$DK_DUMP" | tr "\n" "|")"; assert_no_crash; exit 0; }

EX=$(( E_X + W0 - 1 )); EY=$(( C_Y + C_H / 2 ))
mouse_down "$EX" "$EY"; sleep 0.25
hover $(( EX + 10 )) "$EY"; sleep 0.15; hover $(( EX + 20 )) "$EY"; sleep 0.15; hover $(( EX + 30 )) "$EY"
held_read editbar; W1=$S_W
info "held at +30: edit bar $W1 (was $W0)"
(( W1 >= W0 + 27 && W1 <= W0 + 33 )) && pass "+30 px: the edge follows the pointer ($W0 -> $W1)" || fail "+30 px: edit bar $W0 -> $W1 (the edge jumped)"
hover $(( EX + 45 )) "$EY"; sleep 0.15; hover $(( EX + 60 )) "$EY"
held_read editbar; W2=$S_W
slot_of advbar; A2=$S_W
(( W2 >= W0 + 57 && W2 <= W0 + 63 )) && pass "+60 px: still under the pointer ($W2)" || fail "+60 px: edit bar $W2 (want ~$(( W0 + 60 )))"
(( A2 <= A0 )) && pass "the advanced bar gives way ($A0 -> $A2)" || fail "advanced bar $A0 -> $A2 while the edit bar grew"
hover $(( EX + 10 )) "$EY"; sleep 0.15; hover $(( EX - 15 )) "$EY"
held_read editbar; W3=$S_W
(( W3 >= W0 - 18 && W3 <= W0 - 12 )) && pass "back to -15 px: under the pointer ($W3)" || fail "-15 px: edit bar $W3 (want ~$(( W0 - 15 )))"
mouse_up; sleep 0.5
dk_park; dk_settle
slot_of editbar; WE=$S_W; XE=$S_X
slot_of advbar; AE=$S_W; AXE=$S_X
dk_col "$S_COL"
info "after the drop: edit bar $XE+$WE, advanced bar $AXE+$AE, row $C_X+$C_W"
(( AXE + AE <= C_X + C_W && WE >= W0 - 18 && WE <= W0 - 12 )) && pass "dropped: the slots fit the row, the edit bar where it was let go" || fail "after the drop: edit bar $WE, advanced bar ends $(( AXE + AE )) (row ends $(( C_X + C_W )))"
screenshot "dock-row-overwide"
dk_check "after the edge drag"
assert_window_exists
info "=== Over-wide row edge drag done ==="
