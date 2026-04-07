#!/bin/bash
# =============================================================================
# file-save-load.sh — QA test: Save and Load DRW files
# Tests: Ctrl+S save, Ctrl+O load, verify round-trip state, cancel dialog
# NOTE: Native file dialogs are blocking and hard to automate with xdotool.
#       This test exercises the deferred action pipeline and verifies no crash.
# =============================================================================

info "=== File Save/Load Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw something to mark the canvas dirty --
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.3 "Brush stroke drawn"
assert_no_crash

# -- Snap canvas state --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "save-before"
BEFORE_SAVE="$SNAP_RESULT"

# -- Test Ctrl+S (deferred save) --
# The native dialog will block; we wait briefly then send Escape to cancel
info "Test Ctrl+S (save dialog trigger)"
key ctrl+s
wait_for 1.0 "Save dialog should appear"
# Cancel the native dialog
key Escape
wait_for 0.5 "Save dialog cancelled"
assert_no_crash

# -- Verify canvas unchanged after cancel --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "save-after-cancel"
AFTER_CANCEL="$SNAP_RESULT"
assert_regions_same "$BEFORE_SAVE" "$AFTER_CANCEL" "Cancel save should not change canvas"

# -- Test Ctrl+O (deferred open) --
info "Test Ctrl+O (open dialog trigger)"
key ctrl+o
wait_for 1.0 "Open dialog should appear"
# Cancel the native dialog
key Escape
wait_for 0.5 "Open dialog cancelled"
assert_no_crash

# -- Verify no state change after cancelled open --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "load-after-cancel"
AFTER_LOAD_CANCEL="$SNAP_RESULT"
assert_regions_same "$BEFORE_SAVE" "$AFTER_LOAD_CANCEL" "Cancel load should not change canvas"

# -- Undo brush stroke --
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== File Save/Load Test PASSED ==="
