#!/bin/bash
# =============================================================================
# view-zoom.sh — QA test: Zoom in/out and reset
# Tests: Ctrl+= (zoom in), Ctrl+0 (reset zoom)
# Verifies zoom changes canvas appearance and reset restores it
# =============================================================================

# -- Establish known state --
info "=== View Zoom Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Snap full work area before zoom --
BEFORE_ZOOM=$(snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "zoom-before")
assert_no_crash

# -- Zoom in once: Ctrl+= --
info "Zoom in (Ctrl+=)"
key ctrl+equal
wait_for 0.3 "Zoom in applied"
assert_no_crash

# -- Snap after first zoom --
ZOOM_1=$(snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "zoom-in-1")
assert_regions_differ "$BEFORE_ZOOM" "$ZOOM_1" "Zoom in should change canvas appearance"
screenshot "zoom-in-1"

# -- Zoom in again: Ctrl+= --
info "Zoom in again (Ctrl+=)"
key ctrl+equal
wait_for 0.3 "Second zoom in applied"
assert_no_crash
screenshot "zoom-in-2"

# -- Reset zoom: Ctrl+0 --
info "Reset zoom (Ctrl+0)"
key ctrl+0
wait_for 0.3 "Zoom reset"
assert_no_crash

# -- Snap after reset --
AFTER_RESET=$(snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "zoom-reset")
assert_regions_same "$BEFORE_ZOOM" "$AFTER_RESET" "Zoom reset should restore original view"
screenshot "zoom-reset"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== View Zoom Test PASSED ==="
