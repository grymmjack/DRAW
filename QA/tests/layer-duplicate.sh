#!/bin/bash
# =============================================================================
# layer-duplicate.sh — QA test: Duplicate current layer
# Tests: Ctrl+Shift+D (duplicate layer), Ctrl+Z (undo)
# Verifies duplicate creates a new layer row and undo removes it
# =============================================================================

# -- Establish known state --
info "=== Layer Duplicate Test ==="
canvas_focus v
wait_for 0.3 "Move tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap layer panel before --
click $CANVAS_CX $CANVAS_CY
snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-before-dup"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Duplicate current layer: Ctrl+Shift+D --
info "Duplicating layer with Ctrl+Shift+D"
key ctrl+shift+d
wait_for 0.8 "Wait for layer duplication"
assert_no_crash

click $CANVAS_CX $CANVAS_CY
snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-dup"
AFTER_DUP="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER_DUP" "Duplicated layer should appear in panel"
screenshot "after-duplicate-layer"

# -- Undo the duplication: Ctrl+Z --
info "Undoing duplication with Ctrl+Z"
key ctrl+z
wait_for 0.5 "Wait for undo"
assert_no_crash

click $CANVAS_CX $CANVAS_CY
snap_region $LP_X $LP_Y $LP_W $LP_H "layer-panel-after-undo-dup"
AFTER_UNDO="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER_UNDO" "Undo should restore original layer state"
screenshot "after-undo-duplicate"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Layer Duplicate Test PASSED ==="
