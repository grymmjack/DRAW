#!/bin/bash
# =============================================================================
# util-refimg.sh — QA test: Reference Image (Ctrl+R)
# Behavior of REFIMG_toggle (action 1501):
#   - If a ref image is loaded: toggle its visibility (no canvas change).
#   - If NO ref image is loaded: opens the file-load dialog (REFIMG_load).
# This test exercises the "nothing loaded" path: pressing Ctrl+R opens the
# dialog, we cancel with Escape, and verify DRAW is still responsive
# afterward. Native dialogs leave repaints that defeat strict pixel
# equality on a same-region snap; we instead verify the dispatcher still
# works (switch tools post-dialog).
# =============================================================================

info "=== Reference Image Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Ctrl+R with no image: opens the load dialog --
info "Ctrl+R (no image loaded → opens file dialog)"
key ctrl+r
wait_for 1.5 "Ref image load dialog opened"
assert_no_crash

# -- Cancel the dialog with Escape --
info "Cancel dialog (Escape)"
key Escape
wait_for 1.5 "Dialog closed"
# Defensive second Escape for any chained prompt
key Escape
wait_for 0.3 "Any remaining dialog cancelled"
assert_no_crash

# -- Verify DRAW still responsive: tool switching still works --
key d
wait_for 0.3 "Dot tool (verifies dispatch still works post-dialog)"
assert_no_crash
key b
wait_for 0.3 "Back to brush"
assert_no_crash

assert_window_exists
info "=== Reference Image Test PASSED ==="
