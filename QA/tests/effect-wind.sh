#!/bin/bash
# =============================================================================
# effect-wind.sh — QA test / regression guard
#
# EFFECTS > Wind... smears vertical edges horizontally to the right.
# (Added 2026-08-14.) Draws a vertical white line (strong vertical edge), applies
# Wind, and asserts the area to the RIGHT of the line changed (streaks).
#
# EFFECTS menu index 30 (0-based) -> dropdown item viewport y = 20 + 30*12 = 380.
# =============================================================================

info "=== Effect: Wind Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 31*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "White FG"
drag "$CANVAS_CX" $(( CANVAS_CY - 50 )) "$CANVAS_CX" $(( CANVAS_CY + 50 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Sample just to the RIGHT of the line — empty before, streaks after.
GX=$(( CANVAS_CX + 8 )); GY=$(( CANVAS_CY - 40 )); GW=40; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "wind-before"
BEFORE="$SNAP_RESULT"

open_effect 1 8 ; wait_for 0.5 "Wind dialog open"
screenshot "wind-dialog"
drag 400 317 560 317 ; wait_for 0.2 "Strength up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "wind-after"
AFTER="$SNAP_RESULT"
screenshot "wind-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Wind must streak the edge rightward"
assert_no_crash
assert_window_exists
info "=== Effect: Wind Test PASSED ==="
