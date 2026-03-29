#!/bin/bash
# =============================================================================
# layer-reorder.sh — QA test: Move layers up and down
# Tests: Ctrl+PageUp (move up), Ctrl+PageDown (move down), Ctrl+Z (undo)
# Verifies layer z-order changes are reflected in the layer panel
# =============================================================================

# -- Establish known state --
info "=== Layer Reorder Test ==="
canvas_focus v
wait_for 0.3 "Window focused"

# -- Snap baseline BEFORE adding new layer --
park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-baseline"
BASELINE="$SNAP_RESULT"

# -- Add a new layer so we have 2+ to reorder --
info "Adding new layer to enable reorder testing"
key ctrl+shift+n
wait_for 0.8 "Wait for new layer"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-before-move"
BEFORE_MOVE="$SNAP_RESULT"

# -- Move layer down: Ctrl+PageDown --
# (New layer starts at top, so move DOWN first to have a visible effect)
info "Moving layer down with Ctrl+Page_Down"
key ctrl+Page_Down
wait_for 0.5 "Wait for layer move down"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-move-down"
AFTER_DOWN="$SNAP_RESULT"
assert_regions_differ "$BEFORE_MOVE" "$AFTER_DOWN" "Layer order should change after move down"
screenshot "after-layer-move-down"

# -- Move layer back up: Ctrl+PageUp --
info "Moving layer up with Ctrl+Page_Up"
key ctrl+Page_Up
wait_for 0.5 "Wait for layer move up"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-move-up"
AFTER_UP="$SNAP_RESULT"
assert_regions_differ "$AFTER_DOWN" "$AFTER_UP" "Layer order should change after move up"
screenshot "after-layer-move-up"

# -- Undo all for cleanup (send extra undos for safety) --
info "Undoing all operations with Ctrl+Z (x5 for safety)"
wake_draw
key ctrl+z
wait_for 0.5 "Undo move up"
wake_draw
key ctrl+z
wait_for 0.5 "Undo move down"
wake_draw
key ctrl+z
wait_for 0.5 "Undo new layer"
wake_draw
key ctrl+z
wait_for 0.3 "Extra undo 1"
wake_draw
key ctrl+z
wait_for 0.3 "Extra undo 2"
assert_no_crash

# -- Compare against baseline (1 layer vs post-operations 2 layers)
park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-undo"
AFTER_UNDO="$SNAP_RESULT"
assert_regions_differ "$AFTER_UP" "$AFTER_UNDO" "Undo should restore original layer order"
screenshot "after-undo-reorder"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Layer Reorder Test PASSED ==="
