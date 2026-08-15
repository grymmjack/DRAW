#!/bin/bash
# =============================================================================
# effect-extrude.sh — QA test / regression guard
#
# EFFECTS > Extrude... raises tile blocks by brightness over a darkened base.
# (Added 2026-08-14.) Crossing green + red strokes, apply, assert the region
# changed (3D blocks).
#
# EFFECTS menu index 28 (0-based) -> dropdown item viewport y = 20 + 28*12 = 356.
# =============================================================================

info "=== Effect: Extrude Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG"
drag "$CANVAS_CX" $(( CANVAS_CY - 50 )) "$CANVAS_CX" $(( CANVAS_CY + 50 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "extrude-before"
BEFORE="$SNAP_RESULT"

open_effect 4 3 ; wait_for 0.5 "Extrude dialog open"
screenshot "extrude-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "extrude-after"
AFTER="$SNAP_RESULT"
screenshot "extrude-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Extrude must raise the strokes into 3D blocks"
assert_no_crash
assert_window_exists
info "=== Effect: Extrude Test PASSED ==="
