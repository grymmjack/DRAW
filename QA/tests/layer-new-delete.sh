#!/bin/bash
# =============================================================================
# layer-new-delete.sh — QA test: Add new layer and delete it
# Tests: Ctrl+Shift+N (new layer), Ctrl+Shift+Delete (delete layer)
# Verifies layer panel updates correctly for both operations
# =============================================================================

# -- Layer panel region (LAYERS_DOCK=LEFT) --
LP_X=0
LP_Y=12
LP_W=100
LP_H=68

# -- Establish known state --
info "=== Layer New/Delete Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Snap layer panel before --
BEFORE=$(snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-before-add")
assert_no_crash

# -- Add new layer: Ctrl+Shift+N --
info "Adding new layer with Ctrl+Shift+N"
key ctrl+shift+n
wait_for 0.8 "Wait for new layer"
assert_no_crash

AFTER_ADD=$(snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-add")
assert_regions_differ "$BEFORE" "$AFTER_ADD" "New layer should appear in panel"
screenshot "after-new-layer"

# -- Delete the new layer: Ctrl+Shift+Delete --
info "Deleting layer with Ctrl+Shift+Delete"
key ctrl+shift+Delete
wait_for 0.8 "Wait for layer deletion"
assert_no_crash

AFTER_DEL=$(snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-delete")
assert_regions_differ "$AFTER_ADD" "$AFTER_DEL" "Panel should change after delete"
assert_regions_same "$BEFORE" "$AFTER_DEL" "Panel should return to original state"
screenshot "after-delete-layer"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Layer New/Delete Test PASSED ==="
