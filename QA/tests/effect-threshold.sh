#!/bin/bash
# =============================================================================
# effect-threshold.sh — QA test / regression guard
#
# EFFECTS > Threshold... binarizes the layer to black/white by a luminance
# cutoff. (Added 2026-08-14.) Draws a blue stroke, opens Threshold, drags the
# LEVEL slider low (so the blue's luminance lands ABOVE the cutoff -> white),
# commits with Return, and asserts the stroke changed.
# =============================================================================

info "=== Effect: Threshold Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Blue stroke (chip 3 = 75,76,255; luminance ~= 0.299*75+0.587*76+0.114*255 ~= 96).
# A LEVEL slider below ~96 turns it white; above, black. Either way it changes
# from the original blue, which is the guard.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 3*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Blue FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "threshold-before"
BEFORE="$SNAP_RESULT"

# Open Threshold, drag LEVEL slider to the far left (low cutoff), commit (Return).
key question ; wait_for 0.5 "Command palette"
type_text "Threshold" ; wait_for 0.5 "Filtered"
key Return ; wait_for 0.7 "Threshold dialog open"
screenshot "threshold-dialog"
drag 560 317 370 317 ; wait_for 0.3 "Level lowered"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "threshold-after"
AFTER="$SNAP_RESULT"
screenshot "threshold-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Threshold must binarize the blue stroke (blue -> black or white)"
assert_no_crash
assert_window_exists
info "=== Effect: Threshold Test PASSED ==="
