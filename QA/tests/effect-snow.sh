#!/bin/bash
# =============================================================================
# effect-snow.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Snow... white snow caps settle on the shape's top-facing
# edges (transparent-within-depth above) plus optional falling flecks scattered
# over the layer. (Added 2026-08-14, Eye Candy SHAPE.) Alpha-adding apply_spatial.
#
# SHAPE is EFFECTS category index 7; Snow is child 12 -> open_effect 7 12.
# Thick green blob on a transparent layer; apply; assert the blob-top + area
# above changed (white cap + flecks).
# =============================================================================

info "=== Effect: Snow Test ==="

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

# Blob top edge (snow cap) + band above (flecks).
GX=$(( CANVAS_CX - 50 )); GY=$(( CANVAS_CY - 26 )); GW=100; GH=44
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "snow-before"
BEFORE="$SNAP_RESULT"

open_effect 7 12 ; wait_for 0.5 "Snow dialog open"
screenshot "snow-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "snow-after"
AFTER="$SNAP_RESULT"
screenshot "snow-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Snow must cap the shape's top edge and scatter flecks"
assert_no_crash
assert_window_exists
info "=== Effect: Snow Test PASSED ==="
