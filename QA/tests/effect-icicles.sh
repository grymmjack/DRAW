#!/bin/bash
# =============================================================================
# effect-icicles.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Icicles... pale ice spikes hang off the shape's bottom edges;
# each bottom-edge column grows a downward spike whose length is a smooth per-
# column noise (neighbouring columns form pointed icicles), pale cyan-white
# fading/brightening toward a glassy tip. (Added 2026-08-14, Eye Candy SHAPE.)
#
# SHAPE is EFFECTS category index 7; Icicles is child 15 -> open_effect 7 15.
# =============================================================================

info "=== Effect: Icicles Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 40 )) "$CANVAS_CY" $(( CANVAS_CX + 40 )) "$CANVAS_CY"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Band BELOW the blob's bottom edge, where icicles hang.
GX=$(( CANVAS_CX - 44 )); GY=$(( CANVAS_CY + 8 )); GW=88; GH=30
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "icicles-before"
BEFORE="$SNAP_RESULT"

open_effect 7 15 ; wait_for 0.5 "Icicles dialog open"
screenshot "icicles-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "icicles-after"
AFTER="$SNAP_RESULT"
screenshot "icicles-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Icicles must hang ice spikes below the shape's bottom edge"
assert_no_crash
assert_window_exists
info "=== Effect: Icicles Test PASSED ==="
