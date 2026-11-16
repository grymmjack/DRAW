#!/bin/bash
# =============================================================================
# swatches-dock-resize.sh — QA test: a docked Swatches panel resizes like any
# docked panel (Rick, 2026-11-10: "when i dock swatches i can't resize the pane"):
#   - stacked above the layers, the divider between them moves both ways
#   - in a column of its own, the column's inner edge widens it
# (dk_divider_extremes only checks the invariants afterwards, not that the
# divider moved - so this measures the slot and column sizes.)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-ramps.gpl
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
slot_h() { dk_p "$1"; dk_slot "$P_SLOT"; echo "$S_H"; }

info "=== Swatches: resize when docked ==="
dk_begin

# stacked above the layers: drag the divider between them (the layers' top)
dk_move_expect swatches above layers; dk_check "swatches above the layers"
H1=$(slot_h swatches)
dk_p layers; dk_slot "$P_SLOT"; X=$(( S_X + S_W / 2 )); Y=$(( S_Y - 2 ))
info "divider at $X,$Y; swatches slot ${H1}px"
dk_drag "$X" "$Y" "$X" $(( Y + 70 )) 6; dk_park; dk_settle
H2=$(slot_h swatches)
if (( H2 > H1 + 30 )); then pass "divider down: swatches grew ($H1 -> $H2)"; else fail "divider down: swatches did not grow ($H1 -> $H2)"; fi
dk_p layers; dk_slot "$P_SLOT"; Y=$(( S_Y - 2 ))
dk_drag "$X" "$Y" "$X" $(( Y - 100 )) 6; dk_park; dk_settle
H3=$(slot_h swatches)
if (( H3 < H2 - 30 )); then pass "divider up: swatches shrank ($H2 -> $H3)"; else fail "divider up: swatches did not shrink ($H2 -> $H3)"; fi
dk_check "after the divider drags"

# stacked BELOW the layers: the divider is right above the swatches' title bar
dk_move_expect swatches below layers; dk_check "swatches below the layers"
H1=$(slot_h swatches)
dk_p swatches; dk_slot "$P_SLOT"; X=$(( S_X + S_W / 2 )); Y=$(( S_Y - 2 ))
info "divider at $X,$Y; swatches slot ${H1}px"
dk_drag "$X" "$Y" "$X" $(( Y - 70 )) 6; dk_park; dk_settle
H2=$(slot_h swatches)
if (( H2 > H1 + 30 )); then pass "below: divider up, swatches grew ($H1 -> $H2)"; else fail "below: divider up, swatches did not grow ($H1 -> $H2)"; fi
dk_p swatches; dk_slot "$P_SLOT"; Y=$(( S_Y - 2 ))
dk_drag "$X" "$Y" "$X" $(( Y + 100 )) 6; dk_park; dk_settle
H3=$(slot_h swatches)
if (( H3 < H2 - 30 )); then pass "below: divider down, swatches shrank ($H2 -> $H3)"; else fail "below: divider down, swatches did not shrink ($H2 -> $H3)"; fi

# below the drawer in the right column
dk_move_expect swatches below drawer; dk_check "swatches below the drawer"
H1=$(slot_h swatches)
dk_p swatches; dk_slot "$P_SLOT"; X=$(( S_X + S_W / 2 )); Y=$(( S_Y - 2 ))
info "divider at $X,$Y; swatches slot ${H1}px"
dk_drag "$X" "$Y" "$X" $(( Y - 70 )) 6; dk_park; dk_settle
H2=$(slot_h swatches)
if (( H2 > H1 + 30 )); then pass "under the drawer: swatches grew ($H1 -> $H2)"; else fail "under the drawer: swatches did not grow ($H1 -> $H2)"; fi

# a column of its own: drag its inner edge (the side facing the canvas)
dk_move_expect swatches edge-left; dk_check "swatches in its own column"
dk_p swatches; dk_slot "$P_SLOT"; dk_col "$S_COL"
W1=$C_W; EX=$(( C_X + C_W )); EY=$(( C_Y + C_H / 2 ))
info "column edge at $EX,$EY; width ${W1}px"
dk_drag "$EX" "$EY" $(( EX + 60 )) "$EY" 6; dk_park; dk_settle
dk_p swatches; dk_slot "$P_SLOT"; dk_col "$S_COL"; W2=$C_W
if (( W2 > W1 + 30 )); then pass "edge: the column widened ($W1 -> $W2)"; else fail "edge: the column did not widen ($W1 -> $W2)"; fi
dk_check "after the edge drag"
screenshot "swatches-dock-resize-end"
assert_window_exists
info "=== Swatches: resize when docked PASSED ==="
