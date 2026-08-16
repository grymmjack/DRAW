#!/bin/bash
# =============================================================================
# effect-longshadow.sh — QA test / regression guard
#
# EFFECTS > Long Shadow... casts a solid diagonal shadow trail down-right of the
# shape (flat "long shadow" look). (Added 2026-08-14.) Transparent layer: green
# stroke, BG set to red, apply Long Shadow, assert a diagonal red trail appears.
#
# EFFECTS menu index 16 (0-based) -> dropdown item viewport y = 20 + 16*12 = 212.
# =============================================================================

info "=== Effect: Long Shadow Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 60 )) $(( CANVAS_CY - 20 ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG red"
key x ; wait_for 0.2 "Swap -> BG red (shadow colour)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Diagonal trail falls down-right of the stroke -> sample below/right of it.
GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 10 )); GW=130; GH=40
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "longshadow-before"
BEFORE="$SNAP_RESULT"

open_effect 2 1 ; wait_for 0.5 "Long Shadow dialog open"
screenshot "longshadow-dialog"
drag 400 317 590 317 ; wait_for 0.2 "Length up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "longshadow-after"
AFTER="$SNAP_RESULT"
screenshot "longshadow-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Long Shadow must cast a diagonal trail from the stroke"
assert_no_crash
assert_window_exists
info "=== Effect: Long Shadow Test PASSED ==="
