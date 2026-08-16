#!/bin/bash
# =============================================================================
# effect-pinch.sh — QA test / regression guard
#
# EFFECTS > Pinch / Bulge... radial displacement (bulge magnifies the centre,
# pinch sucks inward). (Added 2026-08-14.) Draws a horizontal green line through
# the centre, applies the default bulge, asserts the region changed.
#
# EFFECTS menu index 23 (0-based) -> dropdown item viewport y = 20 + 23*12 = 296.
# =============================================================================

info "=== Effect: Pinch / Bulge Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 100 )) $(( CANVAS_CY )) $(( CANVAS_CX + 100 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 50 )); GY=$(( CANVAS_CY - 40 )); GW=100; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "pinch-before"
BEFORE="$SNAP_RESULT"

open_effect 3 2 ; wait_for 0.5 "Pinch dialog open"
screenshot "pinch-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "pinch-after"
AFTER="$SNAP_RESULT"
screenshot "pinch-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Pinch / Bulge must radially displace the line"
assert_no_crash
assert_window_exists
info "=== Effect: Pinch / Bulge Test PASSED ==="
