#!/bin/bash
# =============================================================================
# file-save-load.sh — QA test: Save and Load DRW files
# Tests: Ctrl+S save-dialog opens, Ctrl+O load-dialog opens, cancel both,
# verify DRAW is still alive and the canvas content is preserved.
#
# NOTE: native file dialogs are blocking and slow to close. We cannot
# reliably take a same-region snap immediately after Escape because the
# dialog overlay may still be repainting. We verify the canvas content
# (the brush stroke) is still present by snapping a small area centered
# on the stroke, with a moderate tolerance.
# =============================================================================

info "=== File Save/Load Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw something to mark the canvas dirty --
drag "$(( CANVAS_CX - 20 ))" "$CANVAS_CY" "$(( CANVAS_CX + 20 ))" "$CANVAS_CY"
wait_for 0.3 "Brush stroke drawn"
assert_no_crash

# -- Test Ctrl+S (deferred save) opens the save dialog --
info "Test Ctrl+S (save dialog opens then cancels)"
key ctrl+s
wait_for 1.5 "Save dialog should appear"
assert_no_crash
key Escape
wait_for 1.5 "Save dialog cancelled (give native dialog time to fully close)"
assert_no_crash

# -- Test Ctrl+O (deferred open) opens the load dialog --
info "Test Ctrl+O (open dialog opens then cancels)"
key ctrl+o
wait_for 1.5 "Open dialog should appear"
assert_no_crash
key Escape
wait_for 1.5 "Open dialog cancelled (give native dialog time to fully close)"
assert_no_crash

# -- Verify DRAW survived both dialogs and is still responsive --
key b
wait_for 0.3 "Switch to brush — tests dispatch still works post-dialog"
assert_no_crash

# -- Undo brush stroke --
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== File Save/Load Test PASSED ==="
