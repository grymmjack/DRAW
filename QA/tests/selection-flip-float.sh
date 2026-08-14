#!/bin/bash
# =============================================================================
# selection-flip-float.sh — QA test / regression guard
#
# Flipping a marquee selection (H / V) floats it into the MOVE system: only the
# selected pixels flip, non-destructively and mask-aware, and — crucially — the
# flip PERSISTS on commit (MOVE.CONTENT_FLIPPED bypasses the no-op guard that
# skips commits when X/Y/W/H are unchanged). Added 2026-08-14.
#
# Draws a magenta block with a black mark on the LEFT of the selection, presses H
# (flip horizontal), commits (Enter) and deselects (Escape), then asserts the
# mark moved to the RIGHT (proving the flip applied AND persisted) while content
# outside the selection stayed unchanged.
# =============================================================================

info "=== Selection Flip Float Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6 7 8; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 25*17 + 8 )) "$CHIP_Y" ; wait_for 0.3 "Magenta"
for dy in -40 -24 -8 8 24 40; do
  drag $(( CANVAS_CX - 90 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 90 )) $(( CANVAS_CY + dy ))
  wait_for 0.1 "stroke"
done
click $(( 16 + 0*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Black"
for n in 1 2 3 4; do key bracketleft; done
drag $(( CANVAS_CX - 45 )) "$CANVAS_CY" $(( CANVAS_CX - 30 )) "$CANVAS_CY"
park_mouse
wait_for 0.4 "Content drawn"
assert_no_crash

LEFT_X=$(( CANVAS_CX - 48 ));  LEFT_Y=$(( CANVAS_CY - 8 )); LEFT_W=24; LEFT_H=16
RIGHT_X=$(( CANVAS_CX + 24 )); RIGHT_Y=$(( CANVAS_CY - 8 )); RIGHT_W=24; RIGHT_H=16
EDGE_X=$(( CANVAS_CX - 88 ));  EDGE_Y=$(( CANVAS_CY - 30 )); EDGE_W=20; EDGE_H=14

snap_region "$LEFT_X" "$LEFT_Y" "$LEFT_W" "$LEFT_H" "sff-left-before"
LEFT_BEFORE="$SNAP_RESULT"
snap_region "$RIGHT_X" "$RIGHT_Y" "$RIGHT_W" "$RIGHT_H" "sff-right-before"
RIGHT_BEFORE="$SNAP_RESULT"
snap_region "$EDGE_X" "$EDGE_Y" "$EDGE_W" "$EDGE_H" "sff-edge-before"
EDGE_BEFORE="$SNAP_RESULT"

key m
wait_for 0.6 "Marquee tool"
drag $(( CANVAS_CX - 55 )) $(( CANVAS_CY - 30 )) $(( CANVAS_CX + 55 )) $(( CANVAS_CY + 30 ))
wait_for 0.6 "Selection made"
park_mouse

key h
wait_for 0.6 "Flip horizontal (float)"
park_mouse
wait_for 0.4 "Float settled"
# Commit by switching tools — MOVE_reset applies the float (reliable, no cancel).
key b
wait_for 0.8 "Commit via tool switch"
assert_no_crash
screenshot "sff-committed"

park_mouse
snap_region "$LEFT_X" "$LEFT_Y" "$LEFT_W" "$LEFT_H" "sff-left-after"
LEFT_AFTER="$SNAP_RESULT"
snap_region "$RIGHT_X" "$RIGHT_Y" "$RIGHT_W" "$RIGHT_H" "sff-right-after"
RIGHT_AFTER="$SNAP_RESULT"
snap_region "$EDGE_X" "$EDGE_Y" "$EDGE_W" "$EDGE_H" "sff-edge-after"
EDGE_AFTER="$SNAP_RESULT"

# Mark left the LEFT and arrived at the RIGHT => flip applied AND persisted past commit.
assert_regions_differ "$LEFT_BEFORE" "$LEFT_AFTER" "Flip should remove the mark from the left of the selection"
assert_regions_differ "$RIGHT_BEFORE" "$RIGHT_AFTER" "Flip should move the mark to the right (and persist through commit)"
# Outside the selection stays put => float, not a destructive whole-layer flip.
assert_regions_same "$EDGE_BEFORE" "$EDGE_AFTER" "Content outside the selection must be unchanged (float, not whole-layer flip)"

assert_no_crash
assert_window_exists
info "=== Selection Flip Float Test PASSED ==="
