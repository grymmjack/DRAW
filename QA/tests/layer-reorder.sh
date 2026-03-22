#!/bin/bash
# =============================================================================
# layer-reorder.sh — QA test: Move layers up and down
# Tests: Ctrl+PageUp (move up), Ctrl+PageDown (move down), Ctrl+Z (undo)
# Verifies layer z-order changes are reflected in the layer panel
# =============================================================================

# -- Layer panel region (LAYERS_DOCK=LEFT) --
LP_X=0
LP_Y=12
LP_W=100
LP_H=68

# -- Establish known state --
info "=== Layer Reorder Test ==="
canvas_focus v
wait_for 0.3 "Move tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Add a new layer so we have 2+ to reorder --
info "Adding new layer to enable reorder testing"
key ctrl+shift+n
wait_for 0.8 "Wait for new layer"
assert_no_crash

click $CANVAS_CX $CANVAS_CY
BEFORE_MOVE=$(snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-before-move")

# -- Move layer up: Ctrl+PageUp --
info "Moving layer up with Ctrl+Page_Up"
key ctrl+Page_Up
wait_for 0.5 "Wait for layer move up"
assert_no_crash

click $CANVAS_CX $CANVAS_CY
AFTER_UP=$(snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-move-up")
assert_regions_differ "$BEFORE_MOVE" "$AFTER_UP" "Layer order should change after move up"
screenshot "after-layer-move-up"

# -- Move layer back down: Ctrl+PageDown --
info "Moving layer down with Ctrl+Page_Down"
key ctrl+Page_Down
wait_for 0.5 "Wait for layer move down"
assert_no_crash

click $CANVAS_CX $CANVAS_CY
AFTER_DOWN=$(snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-move-down")
assert_regions_differ "$AFTER_UP" "$AFTER_DOWN" "Layer order should change after move down"
screenshot "after-layer-move-down"

# -- Undo all 3 operations: move down, move up, new layer --
info "Undoing all operations with Ctrl+Z (x3)"
key ctrl+z
wait_for 0.3 "Undo move down"
key ctrl+z
wait_for 0.3 "Undo move up"
key ctrl+z
wait_for 0.5 "Undo new layer"
assert_no_crash

click $CANVAS_CX $CANVAS_CY
AFTER_UNDO=$(snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-undo")
assert_regions_same "$BEFORE_MOVE" "$AFTER_UNDO" "Undo should restore original layer order"
screenshot "after-undo-reorder"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Layer Reorder Test PASSED ==="
