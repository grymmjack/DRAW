#!/bin/bash
# =============================================================================
# effect-waterdrops.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Water Drops... a waterdropsy sheen: translucent lightening + two diagonal specular streaks.
# alpha; 
# (Added 2026-08-14, Eye Candy SHAPE.) RGB-only, apply_to_layer.
#
# SHAPE is EFFECTS category index 7; Water Drops is child 19 -> open_effect 7 19.
# Thick green blob on a transparent layer; apply; assert the blob interior
# changed (green -> waterdropsy blotches).
# =============================================================================

info "=== Effect: Water Drops Test ==="

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

# Blob interior — waterdrops blotches recolour it.
GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 12 )); GW=80; GH=24
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "waterdrops-before"
BEFORE="$SNAP_RESULT"

open_effect 7 19 ; wait_for 0.5 "Water Drops dialog open"
screenshot "waterdrops-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "waterdrops-after"
AFTER="$SNAP_RESULT"
screenshot "waterdrops-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Water Drops must add refractive droplet lenses to the shape"
assert_no_crash
assert_window_exists
info "=== Effect: Water Drops Test PASSED ==="
