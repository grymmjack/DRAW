#!/bin/bash
# =============================================================================
# effect-chromatic.sh — QA test / regression guard
#
# EFFECTS > Chromatic Aberration... splits R/B channels horizontally for retro
# colour fringing. (Added 2026-08-14.) Draws a VERTICAL white stroke (long
# left/right edges), applies the effect, and asserts red/blue fringes appear
# (region changes from pure white).
#
# EFFECTS menu index 11 (0-based) -> dropdown item viewport y = 20 + 11*12 = 152.
# =============================================================================

info "=== Effect: Chromatic Aberration Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Vertical white stroke (chip 31 = 255,255,255) — horizontal channel split
# fringes its left/right edges red/cyan.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 31*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "White FG"
drag "$CANVAS_CX" $(( CANVAS_CY - 55 )) "$CANVAS_CX" $(( CANVAS_CY + 55 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 22 )); GY=$(( CANVAS_CY - 40 )); GW=44; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "chromatic-before"
BEFORE="$SNAP_RESULT"

# Open Chromatic Aberration via EFFECTS menu (default amount 4 applies), commit.
open_effect 1 6 ; wait_for 0.5 "Chromatic dialog open"
screenshot "chromatic-dialog"
drag 400 317 520 317 ; wait_for 0.2 "Amount up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "chromatic-after"
AFTER="$SNAP_RESULT"
screenshot "chromatic-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Chromatic Aberration must add colour fringes to the white stroke"
assert_no_crash
assert_window_exists
info "=== Effect: Chromatic Aberration Test PASSED ==="
