#!/bin/bash
# =============================================================================
# effect-drip.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Drip... pale liquid runs drip off the bottom edge in the shape's own colour.
# each bottom-edge column grows a downward spike whose length is a smooth per-
# column noise (neighbouring columns form pointed drip), pale cyan-white
# fading/brightening toward a glassy tip. (Added 2026-08-14, Eye Candy SHAPE.)
#
# SHAPE is EFFECTS category index 7; Drip is child 16 -> open_effect 7 16.
# =============================================================================

info "=== Effect: Drip Test ==="

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

# Band BELOW the blob's bottom edge, where drip hang.
GX=$(( CANVAS_CX - 44 )); GY=$(( CANVAS_CY + 8 )); GW=88; GH=30
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "drip-before"
BEFORE="$SNAP_RESULT"

open_effect 7 16 ; wait_for 0.5 "Drip dialog open"
screenshot "drip-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "drip-after"
AFTER="$SNAP_RESULT"
screenshot "drip-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Drip must drip liquid runs below the shape"
assert_no_crash
assert_window_exists
info "=== Effect: Drip Test PASSED ==="
