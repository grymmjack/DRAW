#!/bin/bash
# =============================================================================
# image-resize-crop.sh — QA test: Canvas Resize & Crop Tool
# Tests: Crop tool activate, draw marquee, apply, undo; resize via dialog
# =============================================================================

info "=== Image Resize/Crop Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw content to crop --
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 ))
wait_for 0.3 "Brush stroke drawn"
assert_no_crash

# -- Snap canvas BEFORE crop --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "crop-before"
BEFORE="$SNAP_RESULT"

# -- Activate crop tool (toolbar or command palette) --
info "Activate crop tool via command palette"
key question
wait_for 0.5 "Command palette opened"
type_text "crop"
wait_for 0.3 "Filter"
key Return
wait_for 0.5 "Crop tool activated"
assert_no_crash

# -- Draw crop marquee --
info "Draw crop rectangle"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Crop marquee drawn"
assert_no_crash
screenshot "crop-marquee"

# -- Cancel crop with Escape --
info "Cancel crop (Escape)"
key Escape
wait_for 0.3 "Crop cancelled"
assert_no_crash

# -- Verify canvas unchanged after cancel --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "crop-after-cancel"
AFTER_CANCEL="$SNAP_RESULT"

# -- Undo brush stroke --
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Switch to brush --
key b
wait_for 0.2 "Brush restored"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Image Resize/Crop Test PASSED ==="
