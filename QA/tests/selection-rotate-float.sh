#!/bin/bash
# =============================================================================
# selection-rotate-float.sh — QA test / regression guard
#
# Rotating a marquee selection (> / <) must FLOAT it into the MOVE system: only
# the selected pixels rotate, non-destructively, mask-aware, and the rest of the
# layer is untouched. Previously > / < rotated destructively and deselected.
# Added 2026-08-14.
#
# Draws a magenta block, selects a centred sub-rect, presses > (rotate 90 CW),
# and asserts content OUTSIDE the selection is unchanged (float, not whole-layer)
# while the selection region changes.
# =============================================================================

info "=== Selection Rotate Float Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6 7 8; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 25*17 + 8 )) "$CHIP_Y" ; wait_for 0.3 "Magenta"
for dy in -50 -34 -18 -2 14 30 46; do
  drag $(( CANVAS_CX - 100 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 100 )) $(( CANVAS_CY + dy ))
  wait_for 0.1 "stroke"
done
park_mouse
wait_for 0.4 "Block drawn"
assert_no_crash

EDGE_X=$(( CANVAS_CX - 95 )); EDGE_Y=$(( CANVAS_CY - 10 )); EDGE_W=30; EDGE_H=20
CEN_X=$(( CANVAS_CX - 18 ));  CEN_Y=$(( CANVAS_CY - 10 )); CEN_W=36; CEN_H=20

snap_region "$EDGE_X" "$EDGE_Y" "$EDGE_W" "$EDGE_H" "srf-edge-before"
EDGE_BEFORE="$SNAP_RESULT"

key m
wait_for 0.6 "Marquee tool"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 24 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 24 ))
wait_for 0.6 "Selection made"
park_mouse
snap_region "$CEN_X" "$CEN_Y" "$CEN_W" "$CEN_H" "srf-center-before"
CENTER_BEFORE="$SNAP_RESULT"

key greater
wait_for 0.6 "Rotated selection 90 CW"
assert_no_crash
screenshot "srf-rotated"

park_mouse
snap_region "$EDGE_X" "$EDGE_Y" "$EDGE_W" "$EDGE_H" "srf-edge-after"
EDGE_AFTER="$SNAP_RESULT"
snap_region "$CEN_X" "$CEN_Y" "$CEN_W" "$CEN_H" "srf-center-after"
CENTER_AFTER="$SNAP_RESULT"

assert_regions_same "$EDGE_BEFORE" "$EDGE_AFTER" "Content outside the selection must be unchanged (float, not whole-layer rotate)"
assert_regions_differ "$CENTER_BEFORE" "$CENTER_AFTER" "The selected region should change when rotated"

assert_no_crash
assert_window_exists
info "=== Selection Rotate Float Test PASSED ==="
