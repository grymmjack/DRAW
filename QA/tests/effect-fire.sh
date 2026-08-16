#!/bin/bash
# =============================================================================
# effect-fire.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Fire... flames rise off the shape's top edge: transparent
# pixels with an opaque pixel within HEIGHT below get a heat value (closeness x
# upward-flickering noise) mapped through a black->red->orange->yellow->white
# ramp. (Added 2026-08-14, Eye Candy SHAPE.) Alpha-adding apply_spatial.
#
# SHAPE is EFFECTS category index 7; Fire is child 13 -> open_effect 7 13.
# Thick green blob on a transparent layer; apply; assert the band ABOVE the blob
# (where flames appear) changed.
# =============================================================================

info "=== Effect: Fire Test ==="

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

# Band ABOVE the blob top edge, where flames rise.
GX=$(( CANVAS_CX - 44 )); GY=$(( CANVAS_CY - 26 )); GW=88; GH=24
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "fire-before"
BEFORE="$SNAP_RESULT"

open_effect 7 13 ; wait_for 0.5 "Fire dialog open"
screenshot "fire-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "fire-after"
AFTER="$SNAP_RESULT"
screenshot "fire-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Fire must raise flames above the shape's top edge"
assert_no_crash
assert_window_exists
info "=== Effect: Fire Test PASSED ==="
