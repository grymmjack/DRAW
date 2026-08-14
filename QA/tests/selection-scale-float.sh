#!/bin/bash
# =============================================================================
# selection-scale-float.sh — QA test / regression guard
#
# Scaling a marquee selection (PageDown / PageUp) must FLOAT it into the MOVE
# system: only the selected pixels scale, non-destructively, and the rest of the
# layer is untouched. (Previously PageUp/PageDown scaled the whole layer
# destructively, leaving transparency and losing data.) Added 2026-08-14.
#
# Draws a magenta block, selects a centred sub-rect, presses PageDown, and
# asserts: (a) content OUTSIDE the selection is unchanged (proves float, not a
# whole-layer scale), and (b) the selection region itself changed.
# =============================================================================

info "=== Selection Scale Float Test ==="

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

# Regions: an EDGE strip well left of the centre (outside the selection), and the
# selection CENTRE.
EDGE_X=$(( CANVAS_CX - 95 )); EDGE_Y=$(( CANVAS_CY - 10 )); EDGE_W=30; EDGE_H=20
CEN_X=$(( CANVAS_CX - 18 ));  CEN_Y=$(( CANVAS_CY - 10 )); CEN_W=36; CEN_H=20

snap_region "$EDGE_X" "$EDGE_Y" "$EDGE_W" "$EDGE_H" "ssf-edge-before"
EDGE_BEFORE="$SNAP_RESULT"

# Select a centred sub-rectangle, then scale it DOWN (PageDown = action 317).
key m
wait_for 0.6 "Marquee tool"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 24 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 24 ))
wait_for 0.6 "Selection made"
park_mouse
snap_region "$CEN_X" "$CEN_Y" "$CEN_W" "$CEN_H" "ssf-center-before"
CENTER_BEFORE="$SNAP_RESULT"

key Next
wait_for 0.6 "Scaled selection down"
assert_no_crash
screenshot "ssf-scaled"

park_mouse
snap_region "$EDGE_X" "$EDGE_Y" "$EDGE_W" "$EDGE_H" "ssf-edge-after"
EDGE_AFTER="$SNAP_RESULT"
snap_region "$CEN_X" "$CEN_Y" "$CEN_W" "$CEN_H" "ssf-center-after"
CENTER_AFTER="$SNAP_RESULT"

# (a) Outside the selection must be untouched — this is what distinguishes a
#     float from the old destructive whole-layer scale.
assert_regions_same "$EDGE_BEFORE" "$EDGE_AFTER" "Content outside the selection must be unchanged (float, not whole-layer scale)"
# (b) The selection itself must have changed (scaled / lifted).
assert_regions_differ "$CENTER_BEFORE" "$CENTER_AFTER" "The selected region should change when scaled"

assert_no_crash
assert_window_exists
info "=== Selection Scale Float Test PASSED ==="
