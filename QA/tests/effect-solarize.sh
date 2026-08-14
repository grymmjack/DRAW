#!/bin/bash
# =============================================================================
# effect-solarize.sh — QA test / regression guard
#
# EFFECTS > Solarize... inverts channels above a threshold (Sabattier).
# (Added 2026-08-14.) Draws a green stroke (G=255 inverts at the default
# threshold 128 -> 0), applies Solarize, asserts the stroke changed colour.
#
# EFFECTS menu index 13 (0-based) -> dropdown item viewport y = 20 + 13*12 = 176.
# =============================================================================

info "=== Effect: Solarize Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "solarize-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 176 ; wait_for 0.7 "Solarize dialog open"
screenshot "solarize-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "solarize-after"
AFTER="$SNAP_RESULT"
screenshot "solarize-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Solarize must invert the green stroke's bright channel"
assert_no_crash
assert_window_exists
info "=== Effect: Solarize Test PASSED ==="
