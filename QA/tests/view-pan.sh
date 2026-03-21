#!/bin/bash
# =============================================================================
# view-pan.sh — QA test: Pan canvas with middle-click drag
# Tests: Middle-click drag to pan, Ctrl+0 to reset view
# Verifies panning shifts the canvas and reset restores it
# =============================================================================

# -- Establish known state --
info "=== View Pan Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Snap work area before pan --
BEFORE_PAN=$(snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "pan-before")
assert_no_crash

# -- Pan canvas: middle-click drag (button 2) --
info "Panning canvas with middle-click drag"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 30 )) 2
wait_for 0.3 "Pan applied"
assert_no_crash

# -- Snap after pan --
AFTER_PAN=$(snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "pan-after")
assert_regions_differ "$BEFORE_PAN" "$AFTER_PAN" "Panning should shift the canvas view"
screenshot "pan-after"

# -- Reset view: Ctrl+0 --
info "Reset view (Ctrl+0)"
key ctrl+0
wait_for 0.3 "View reset"
assert_no_crash

# -- Snap after reset --
AFTER_RESET=$(snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "pan-reset")
assert_regions_same "$BEFORE_PAN" "$AFTER_RESET" "View reset should restore original pan position"
screenshot "pan-reset"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== View Pan Test PASSED ==="
