#!/bin/bash
# =============================================================================
# effect-emboss.sh — QA test / regression guard
#
# EFFECTS > Emboss... turns the layer into grey directional relief (flat -> 128,
# edges -> light/dark ridges). (Added 2026-08-14.) Draws a green stroke, applies
# Emboss, and asserts the region changed (flat green -> grey relief).
#
# EFFECTS menu index 12 (0-based) -> dropdown item viewport y = 20 + 12*12 = 164.
# =============================================================================

info "=== Effect: Emboss Test ==="

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

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 10 )); GW=120; GH=20
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "emboss-before"
BEFORE="$SNAP_RESULT"

open_effect 1 7 ; wait_for 0.5 "Emboss dialog open"
screenshot "emboss-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "emboss-after"
AFTER="$SNAP_RESULT"
screenshot "emboss-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Emboss must convert the flat green stroke to grey relief"
assert_no_crash
assert_window_exists
info "=== Effect: Emboss Test PASSED ==="
