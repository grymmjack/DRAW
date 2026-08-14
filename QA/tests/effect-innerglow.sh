#!/bin/bash
# =============================================================================
# effect-innerglow.sh — QA test / regression guard
#
# EFFECTS > Inner Glow... blends a coloured glow (FG) inward from the shape's
# alpha edges. (Added 2026-08-14.) Thick green blob on a transparent layer, FG
# set to magenta, apply Inner Glow, assert the blob's edges gained colour.
#
# EFFECTS menu index 19 (0-based) -> dropdown item viewport y = 20 + 19*12 = 248.
# =============================================================================

info "=== Effect: Inner Glow Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY ))
click $(( 16 + 28*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG magenta (glow colour)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 44 )); GY=$(( CANVAS_CY - 16 )); GW=88; GH=32
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "innerglow-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 248 ; wait_for 0.7 "Inner Glow dialog open"
screenshot "innerglow-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "innerglow-after"
AFTER="$SNAP_RESULT"
screenshot "innerglow-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Inner Glow must tint the blob's inner edges"
assert_no_crash
assert_window_exists
info "=== Effect: Inner Glow Test PASSED ==="
