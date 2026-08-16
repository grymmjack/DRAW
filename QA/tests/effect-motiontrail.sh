#!/bin/bash
# =============================================================================
# effect-motiontrail.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Motion Trail... a speed-blur smear: each opaque pixel is
# scattered along a direction as a fading run of copies in its OWN colour, then
# the crisp original is composited on top. (Added 2026-08-14, Eye Candy SHAPE.)
# Default direction 180deg = trail extends LEFT (as if moving right).
#
# SHAPE is EFFECTS category index 7; Motion Trail is child 10 -> open_effect 7 10.
# Thick green blob on a transparent layer; apply; assert the LEFT band (where the
# fading trail lands) changed.
# =============================================================================

info "=== Effect: Motion Trail Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 30 )) "$CANVAS_CY" $(( CANVAS_CX + 30 )) "$CANVAS_CY"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Band just LEFT of the blob, where the fading trail falls.
GX=$(( CANVAS_CX - 66 )); GY=$(( CANVAS_CY - 12 )); GW=44; GH=24
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "motiontrail-before"
BEFORE="$SNAP_RESULT"

open_effect 7 10 ; wait_for 0.5 "Motion Trail dialog open"
screenshot "motiontrail-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "motiontrail-after"
AFTER="$SNAP_RESULT"
screenshot "motiontrail-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Motion Trail must smear a fading trail to the left of the shape"
assert_no_crash
assert_window_exists
info "=== Effect: Motion Trail Test PASSED ==="
