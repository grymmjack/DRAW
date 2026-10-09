#!/bin/bash
# =============================================================================
# dock-layers-shrink-preview.sh — QA test: a column holding the docked Preview
# above the layers resizes both ways by the layers' inner edge. Rick
# (2026-10-09): widened to the maximum, the layers could not be dragged
# narrower again - the docked Preview stretches to its column and reported
# that live width as the width it wants, holding the column at its widest.
# DOCK_panel_w% now takes the Preview's floating width (CFG.PREVIEW_W).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1 LAYER_PANEL_WIDTH=120 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer DOCK_LEFT_2=AUTO;advbar DOCK_RIGHT_1=AUTO;preview|layers DOCK_RIGHT_2=AUTO;editbar
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

# the layers' column -> C_X C_Y C_W C_H
layers_col() { dk_p layers; dk_slot "$P_SLOT"; dk_col "$S_COL"; }

info "=== Dock: the layers column shrinks back with the Preview docked in it ==="
dk_begin
dk_check "start"
dk_expect_stacked preview layers
layers_col
W0=$C_W
info "column: x $C_X w $C_W (y $C_Y h $C_H)"

# grab the inner (left) edge low in the column, on the layers
GY=$(( C_Y + C_H * 3 / 4 ))

# widen to the maximum
dk_drag $(( C_X )) "$GY" $(( C_X - 380 )) "$GY" 10
dk_park; dk_settle
layers_col
W1=$C_W
if (( W1 > W0 + 150 )); then pass "widened: $W0 -> $W1"; else fail "did not widen: $W0 -> $W1"; fi
dk_check "widened"

# and back down
dk_drag $(( C_X )) "$GY" $(( C_X + 260 )) "$GY" 10
dk_park; dk_settle
layers_col
W2=$C_W
if (( W2 < W1 - 150 )); then pass "narrowed again: $W1 -> $W2"; else fail "did not narrow: $W1 -> $W2 (the docked Preview holds the column?)"; fi
dk_check "narrowed"
dk_expect_stacked preview layers

screenshot "dock-layers-shrink-preview"
assert_no_crash
