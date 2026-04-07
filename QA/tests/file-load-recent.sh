#!/bin/bash
# =============================================================================
# file-load-recent.sh — QA test: Load / Recent Files
# Tests: Ctrl+O triggers deferred load, cancel, verify state unchanged
# =============================================================================

info "=== Load / Recent Files Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw content to make canvas dirty --
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.3 "Brush stroke drawn (dirty canvas)"
assert_no_crash

# -- Snap canvas state --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "load-before"
BEFORE="$SNAP_RESULT"

# -- Trigger Ctrl+O (deferred open) --
info "Trigger Ctrl+O — open file dialog"
key ctrl+o
wait_for 1.0 "Open dialog should appear"

# -- Cancel the dialog --
key Escape
wait_for 0.5 "Open dialog cancelled"
assert_no_crash

# If an unsaved-changes dialog appeared, cancel that too
key Escape
wait_for 0.3 "Any remaining dialog cancelled"
assert_no_crash

# -- Verify canvas unchanged --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "load-after-cancel"
AFTER_CANCEL="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER_CANCEL" "Cancel load should not change canvas"

# -- Undo brush stroke --
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Load / Recent Files Test PASSED ==="
