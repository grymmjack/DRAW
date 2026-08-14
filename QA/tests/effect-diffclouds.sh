#!/bin/bash
# =============================================================================
# effect-diffclouds.sh — QA test / regression guard
#
# EFFECTS > Difference Clouds... differences grayscale plasma with the existing
# pixels (one-shot, no dialog). (Added 2026-08-14.) Draws a green stroke, applies
# it, asserts the region changed.
#
# EFFECTS menu index 32 (0-based) -> dropdown item viewport y = 20 + 32*12 = 404.
# =============================================================================

info "=== Effect: Difference Clouds Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "diffclouds-before"
BEFORE="$SNAP_RESULT"

# One-shot: clicking the item applies immediately (no dialog).
click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 404 ; wait_for 0.8 "Difference Clouds applied"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "diffclouds-after"
AFTER="$SNAP_RESULT"
screenshot "diffclouds-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Difference Clouds must marble the layer"
assert_no_crash
assert_window_exists
info "=== Effect: Difference Clouds Test PASSED ==="
