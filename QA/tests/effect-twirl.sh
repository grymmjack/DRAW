#!/bin/bash
# =============================================================================
# effect-twirl.sh — QA test / regression guard
#
# EFFECTS > Twirl... swirls the image around its centre. (Added 2026-08-14.)
# Draws a horizontal green line through the centre, applies Twirl, asserts the
# region changed (line swirls into an S-curve).
#
# EFFECTS menu index 22 (0-based) -> dropdown item viewport y = 20 + 22*12 = 284.
# =============================================================================

info "=== Effect: Twirl Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 90 )) $(( CANVAS_CY )) $(( CANVAS_CX + 90 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "twirl-before"
BEFORE="$SNAP_RESULT"

open_effect 3 1 ; wait_for 0.5 "Twirl dialog open"
screenshot "twirl-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "twirl-after"
AFTER="$SNAP_RESULT"
screenshot "twirl-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Twirl must swirl the straight line around centre"
assert_no_crash
assert_window_exists
info "=== Effect: Twirl Test PASSED ==="
