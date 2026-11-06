#!/bin/bash
# =============================================================================
# dock-float-snap-hold.sh — QA test: View > Snap Panel Edges, and the hold
# release. Floating panels snap to each other's edges and are kept from
# overlapping - but:
#   - held still-snapped past the snap for ~1.5 s, the snap lets go and the
#     panel can be dropped ON TOP of the other one
#   - View > Snap Panel Edges off: no snapping or pushing at all
# Rick, 2026-11-06: "it makes it very cumbersome to align them/drag them
# around - we need an option in view ... [x] SNAP PANEL EDGES".
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LAYER_PANEL_WIDTH=200
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: snap panel edges (hold / off) Test ==="
dk_begin
dk_scr
dk_move toolbox float $(( CAN_LX + 40 )) $(( DOCK_TOP + 120 ))
dk_expect_floating toolbox
dk_move layers float $(( (CAN_LX + CAN_RX) / 2 + 60 )) $(( DOCK_TOP + 60 ))
dk_expect_floating layers

overlap() { # layers vs toolbox floating rects intersect?
    dk_p toolbox; local ax=$P_FX ay=$P_FY aw=$P_FW ah=$P_FH
    dk_p layers
    (( P_FX < ax + aw && ax < P_FX + P_FW && P_FY < ay + ah && ay < P_FY + P_FH ))
}
# grab the layers' grip and aim its left edge at toolbox x + $1, y + 20
aim() {
    dk_p toolbox; TBX=$P_FX; TBY=$P_FY; TBR=$(( P_FX + P_FW ))
    dk_p layers
    GX=$(( P_FX + P_FW / 2 )); GY=$(( P_FY + 2 ))
    TX=$(( TBX + $1 + GX - P_FX )); TY=$(( TBY + 20 + GY - P_FY ))
}

# 1) a quick drop onto the toolbox: pushed off it (snap on)
aim 10
dk_drag "$GX" "$GY" "$TX" "$TY"
dk_park; dk_settle
if overlap; then fail "a quick drop lands on top of the toolbox (snap should keep them apart)"; else pass "a quick drop is kept off the toolbox"; fi

# 2) the same drop, held there ~2.5 s while still moving a little: free
aim 10
mouse_down "$GX" "$GY"
for i in 1 2 3 4 5 6; do hover $(( GX + (TX - GX) * i / 6 )) $(( GY + (TY - GY) * i / 6 )); sleep 0.08; done
for i in 1 2 3 4 5 6 7 8 9 10; do hover $(( TX + i % 2 )) "$TY"; sleep 0.25; done
mouse_up
dk_park; dk_settle
if overlap; then pass "held past the snap, the layers drop on top of the toolbox"; else fail "held 2.5 s past the snap, the layers still can't overlap the toolbox"; fi
screenshot "dock-snap-hold-overlap"

# 3) a new drag snaps again (the release lasts one drag)
dk_drag "$TX" "$TY" $(( TX + 300 )) $(( TY + 40 ))
dk_park; dk_settle
aim 10
dk_drag "$GX" "$GY" "$TX" "$TY"
dk_park; dk_settle
if overlap; then fail "the next quick drag overlaps again (the hold release stuck)"; else pass "the next quick drag snaps again"; fi

# 4) View > Snap Panel Edges off (command palette): a quick drop may overlap
key question; wait_for 0.5 "command palette"
type_text "snap panel edges"; wait_for 0.3 "filter"
key Return; wait_for 0.6 "snap toggled off"
grep -qE '^SNAP_PANEL_EDGES=(0|FALSE)' "$DRAW_ROOT/QA/DRAW.qa.cfg" && pass "the toggle saves SNAP_PANEL_EDGES off" || fail "SNAP_PANEL_EDGES not saved off [$(grep '^SNAP_PANEL_EDGES' "$DRAW_ROOT/QA/DRAW.qa.cfg")]"
aim 10
dk_drag "$GX" "$GY" "$TX" "$TY"
dk_park; dk_settle
if overlap; then pass "snap off: the drop lands where it was let go (over the toolbox)"; else fail "snap off: the layers were still pushed off the toolbox"; fi
# and 4 px from an edge stays 4 px (no pull). A drag can lose a px or two to
# the drag threshold, so first measure a drag in open space
dk_drag "$TX" "$TY" $(( TX + 300 )) $(( TY + 40 ))
dk_park; dk_settle
dk_p layers; FX0=$P_FX; GX=$(( P_FX + P_FW / 2 )); GY=$(( P_FY + 2 ))
dk_drag "$GX" "$GY" $(( GX - 40 )) "$GY"
dk_park; dk_settle
dk_p layers; LOSS=$(( P_FX - (FX0 - 40) ))
info "a free 40 px drag moved the layers $(( FX0 - P_FX )) px (loss $LOSS)"
aim $(( TBR - TBX + 4 ))
dk_drag "$GX" "$GY" "$TX" "$TY"
dk_park; dk_settle
dk_p layers
WANT=$(( TBR + 4 + LOSS ))
if (( P_FX == WANT )); then pass "snap off: 4 px from the toolbox stays 4 px (x=$P_FX)"; else fail "snap off: the layers moved to x=$P_FX (dropped at $WANT, toolbox edge $TBR)"; fi
assert_window_exists
info "=== Dock: snap panel edges (hold / off) Test PASSED ==="
