#!/bin/bash
# =============================================================================
# dock-layers-row-clicks.sh — QA test: layer rows take clicks when the layers
# are stacked BELOW another panel (the panel's top is no longer y=0).
# The row hit-test once started at a fixed y=16, so with a panel above the
# layers every click landed past the last row: right-click opened no context
# menu and left-click selected nothing.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: layer row clicks below another panel Test ==="
dk_begin
dk_move layers below organizer && dk_expect_stacked organizer layers
dk_check "layers below organizer"

# a second layer, so there are two rows: row 1 = the new one (current), row 2 = Layer 1
key ctrl+shift+n
wait_for 0.5 "new layer"
dk_settle

dk_p layers
(( P_Y > 0 )) || fail "the layers are not below another panel (top y = $P_Y)"
HDR=16; ROW=20
RX=$(( P_X + P_W / 2 ))
ROW1_Y=$(( P_Y + HDR + ROW / 2 ))
ROW2_Y=$(( P_Y + HDR + ROW + ROW / 2 ))
info "layers at $P_X,$P_Y ${P_W}x$P_H — row 1 y=$ROW1_Y, row 2 y=$ROW2_Y"

# left-click row 2: the highlight moves to it
snap_region "$P_X" $(( P_Y + HDR )) "$P_W" $(( ROW * 2 )) "rows-before"
ROWS_BEFORE=$SNAP_RESULT
click "$RX" "$ROW2_Y"; wait_for 0.4 "select row 2"
dk_park; wait_for 0.3 "park"
snap_region "$P_X" $(( P_Y + HDR )) "$P_W" $(( ROW * 2 )) "rows-after"
assert_regions_differ "$ROWS_BEFORE" "$SNAP_RESULT" \
    "left-clicking the second layer row selects it (the highlight moves)"

# right-click row 1: the layer context menu opens next to the pointer
BOX=120
BX=$(( RX - BOX / 2 )); BY=$(( ROW1_Y - BOX / 2 ))
(( BX < 0 )) && BX=0; (( BY < 0 )) && BY=0
hover "$RX" "$ROW1_Y"; wait_for 0.3 "hover row 1"
snap_region "$BX" "$BY" "$BOX" "$BOX" "ctx-before"
CTX_BEFORE=$SNAP_RESULT
right_click "$RX" "$ROW1_Y"; wait_for 0.5 "right-click row 1"
screenshot "dock-layers-row-ctx-menu"
snap_region "$BX" "$BY" "$BOX" "$BOX" "ctx-after"
assert_regions_differ "$CTX_BEFORE" "$SNAP_RESULT" \
    "right-clicking a layer row opens the layer context menu"
key Escape; wait_for 0.3 "close menu"

assert_window_exists
info "=== Dock: layer row clicks below another panel Test PASSED ==="
