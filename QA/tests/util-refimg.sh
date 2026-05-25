#!/bin/bash
# =============================================================================
# util-refimg.sh — QA test: Reference Image (Ctrl+R)
# Behavior of REFIMG_toggle (action 1501):
#   - If a ref image is loaded: toggle its visibility (no canvas change).
#   - If NO ref image is loaded: opens the file-load dialog (REFIMG_load).
# This test exercises the "nothing loaded" path: pressing Ctrl+R opens the
# dialog, we cancel with Escape, and verify DRAW returns to the prior state.
# =============================================================================

info "=== Reference Image Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap canvas BEFORE ref-image dialog --
park_mouse
snap_region "$(( CANVAS_CX - 80 ))" "$(( CANVAS_CY - 60 ))" 160 120 "refimg-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Ctrl+R with no image: opens the load dialog --
info "Ctrl+R (no image loaded → opens file dialog)"
key ctrl+r
wait_for 1.2 "Ref image load dialog opened"
assert_no_crash

# -- Cancel the dialog with Escape --
info "Cancel dialog (Escape)"
key Escape
wait_for 0.5 "Dialog closed"
# Some platforms show an unsaved-changes prompt — Escape that too defensively
key Escape
wait_for 0.3 "Any remaining dialog cancelled"
assert_no_crash

# -- Verify canvas is back to pre-dialog state --
park_mouse
snap_region "$(( CANVAS_CX - 80 ))" "$(( CANVAS_CY - 60 ))" 160 120 "refimg-after-cancel"
AFTER="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER" "Cancelling the ref-image load dialog should restore the canvas"

assert_no_crash
assert_window_exists
info "=== Reference Image Test PASSED ==="
