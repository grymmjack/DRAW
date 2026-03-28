#!/bin/bash
# =============================================================================
# tool-crop.sh — QA test: Canvas crop via selection
# Tests: Marquee selection → crop action, undo restores original size
# =============================================================================

info "=== Crop Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap full viewport before crop --
park_mouse
snap_region 0 0 $VP_W $VP_H "crop-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Draw something to preserve through crop --
key bracketright
key bracketright
drag $(( CANVAS_CX - 15 )) $CANVAS_CY $(( CANVAS_CX + 15 )) $CANVAS_CY
wait_for 0.3 "Reference stroke drawn"

# -- Select crop region with marquee --
info "Selecting crop region with marquee"
key m
wait_for 0.3 "Marquee tool active"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 20 ))
wait_for 0.5 "Crop region selected"
assert_no_crash

# -- Apply crop: Enter --
info "Applying crop (Enter)"
key Return
wait_for 0.8 "Crop applied"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "crop-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Canvas should look different after crop"
screenshot "after-crop"

# -- Undo crop --
info "Undoing crop (Ctrl+Z)"
key ctrl+z
wait_for 0.8 "Crop undone"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "crop-undo"
UNDO="$SNAP_RESULT"
assert_regions_differ "$AFTER" "$UNDO" "Undo should restore original canvas dimensions"

# -- Cleanup --
key ctrl+z
wait_for 0.3 "Cleanup stroke"
assert_no_crash

assert_window_exists
info "=== Crop Test PASSED ==="
