#!/bin/bash
# =============================================================================
# dock-persist.sh — QA test: an arrangement survives a restart and a workspace
# switch. Arrange (a tab, a stack, a floating panel, a collapsed slot, a new edge
# column), quit and relaunch DRAW (the --config file keeps DOCK_*), then switch
# to the Annotate workspace and back to Default: the same tree, the floating
# panel at the same place, the slot still collapsed.
# No arranging happens inside a workspace (that would write the user's
# workspaces folder). The test relaunches DRAW itself and leaves one running.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: arrangement persists Test ==="
dk_begin
dk_move_expect drawer tab layers;     dk_check "drawer tab of layers"
dk_move_expect editbar below toolbox; dk_check "editbar under the toolbox"
dk_move_expect advbar edge-left;      dk_check "advbar on the left edge"
dk_move_expect organizer float;       dk_check "organizer floating"
dk_p drawer; dk_slot "$P_SLOT"; click $(( S_X + 3 )) $(( S_Y + 5 )); dk_park; dk_settle
dk_p drawer; dk_slot "$P_SLOT"
if (( S_COLL != 0 )); then pass "tab slot collapsed"; else fail "chevron did not collapse"; fi
dk_check "collapsed"
T1=$(dk_tree); dk_p organizer; FX1=$P_FX; FY1=$P_FY
screenshot "dock-persist-before"

# --- restart -------------------------------------------------------------------
info "Relaunching DRAW"
draw_quit
rm -f "$DK_DUMP"
draw_launch 15
dk_begin
T2=$(dk_tree)
if [[ "$T2" == "$T1" ]]; then pass "same tree after a restart [$T2]"; else fail "tree changed by a restart: [$T1] -> [$T2]"; fi
dk_p organizer
DX=$(( P_FX - FX1 )); DX=${DX#-}; DY=$(( P_FY - FY1 )); DY=${DY#-}
if (( P_FL != 0 && DX <= 2 && DY <= 2 )); then pass "organizer floats at the same place ($P_FX,$P_FY)"; else fail "organizer after restart: floating=$P_FL at ($P_FX,$P_FY), was ($FX1,$FY1)"; fi
dk_p drawer; dk_slot "$P_SLOT"
if (( S_COLL != 0 )); then pass "collapsed slot still collapsed"; else fail "collapse lost on restart"; fi
dk_check "after restart"
screenshot "dock-persist-restarted"

# --- workspace there and back ----------------------------------------------------------
canvas_focus
key ctrl+shift+w; wait_for 0.5 "switcher"
type_text "annotate"; wait_for 0.4 "filtered"; key Return; wait_for 1.2 "annotate"
key Escape; dk_park; dk_settle
TA=$(dk_tree)
info "in Annotate: [$TA]"
canvas_focus
key ctrl+shift+w; wait_for 0.5 "switcher"
type_text "default"; wait_for 0.4 "filtered"; key Return; wait_for 1.2 "default"
key Escape; dk_park; dk_settle
T3=$(dk_tree)
if [[ "$T3" == "$T1" ]]; then pass "Default's own arrangement back after Annotate [$T3]"; else fail "arrangement after a workspace round trip: [$T1] -> [$T3]"; fi
dk_p organizer
if (( P_FL != 0 )); then pass "organizer floating again after the round trip"; else fail "organizer not floating after the round trip"; fi
dk_check "after the workspace round trip"

assert_window_exists
info "=== Dock: arrangement persists Test PASSED ==="
