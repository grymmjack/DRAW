#!/bin/bash
# =============================================================================
# dock-layers-drag-below.sh — QA test: with the layers stacked ABOVE another
# panel, dragging a layer row down past the button bar into that panel must
# not drop it on Delete / New / Group. The button-bar test once had no bottom
# bound, so a release anywhere below the panel, under the Delete column,
# deleted the layer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: layer drag below the layers panel Test ==="
dk_begin
dk_move layers above drawer && dk_expect_stacked layers drawer
dk_check "layers above drawer"
key ctrl+shift+n; wait_for 0.5 "new layer"
dk_settle

dk_p layers
HDR=16; ROW=20
ROW1_Y=$(( P_Y + HDR + ROW / 2 ))
RX=$(( P_X + P_W / 2 ))
BTN_W=$(( (P_W - 8 - 10) / 6 ))
DEL_X=$(( P_X + 4 + 3 * (BTN_W + 2) + BTN_W / 2 ))
BAR_Y=$(( P_Y + P_H - 6 ))              # inside the button bar
BELOW_Y=$(( P_Y + P_H + 25 ))           # inside the panel below
dk_p drawer
(( BELOW_Y < P_Y + P_H )) || fail "no room below the layers (drawer ends at $(( P_Y + P_H )))"
dk_p layers
info "layers ${P_W}x$P_H at $P_X,$P_Y — Delete column x=$DEL_X, release below at y=$BELOW_Y"

drag_row_to() {
    mouse_down "$RX" "$ROW1_Y"
    hover "$RX" $(( ROW1_Y + 15 )); sleep 0.15
    hover "$1" "$2"; sleep 0.2
    hover "$1" $(( $2 + 1 )); sleep 0.2
    mouse_up; wait_for 0.4 "drop"
    dk_park; wait_for 0.3 "park"
}
COUNT_X=$(( P_X + P_W - 24 )); COUNT_Y=$(( P_Y + 1 ))

snap_region "$COUNT_X" "$COUNT_Y" 22 13 "count-before"
COUNT_BEFORE=$SNAP_RESULT
drag_row_to "$DEL_X" "$BELOW_Y"
snap_region "$COUNT_X" "$COUNT_Y" 22 13 "count-after-below"
assert_regions_same "$COUNT_BEFORE" "$SNAP_RESULT" \
    "releasing a dragged layer in the panel below (under Delete) does not delete it" 2

# control: the same drag onto the real Delete button still deletes
drag_row_to "$DEL_X" "$BAR_Y"
snap_region "$COUNT_X" "$COUNT_Y" 22 13 "count-after-delete"
assert_regions_differ "$COUNT_BEFORE" "$SNAP_RESULT" \
    "dropping a dragged layer on the Delete button still deletes it"

assert_window_exists
info "=== Dock: layer drag below the layers panel Test PASSED ==="
