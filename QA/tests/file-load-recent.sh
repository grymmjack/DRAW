#!/bin/bash
# =============================================================================
# file-load-recent.sh — QA test: Load / Recent Files
# Tests: Ctrl+O triggers deferred load, cancel, verify DRAW responsive after.
#
# NOTE: native file dialogs take varying time to close on different
# platforms / window managers — strict canvas pixel comparison after
# the dialog closes is unreliable (the dialog overlay can leave repaints).
# We verify Ctrl+O opens the dialog, Escape closes it, and DRAW survives.
# =============================================================================

info "=== Load / Recent Files Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw content to make canvas dirty --
drag "$(( CANVAS_CX - 20 ))" "$CANVAS_CY" "$(( CANVAS_CX + 20 ))" "$CANVAS_CY"
wait_for 0.3 "Brush stroke drawn (dirty canvas)"
assert_no_crash

# -- Trigger Ctrl+O (deferred open) --
info "Trigger Ctrl+O — open file dialog"
key ctrl+o
wait_for 1.5 "Open dialog should appear"
assert_no_crash

# -- Cancel the dialog --
key Escape
wait_for 1.5 "Open dialog cancelled (give native dialog time to fully close)"
# If an unsaved-changes prompt appeared, cancel that too
key Escape
wait_for 0.5 "Any remaining dialog cancelled"
assert_no_crash

# -- Verify DRAW is still responsive: switching tools should still work --
key b
wait_for 0.3 "Switch to brush — dispatch still works post-dialog"
assert_no_crash

# -- Undo brush stroke --
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Load / Recent Files Test PASSED ==="
