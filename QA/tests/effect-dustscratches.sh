#!/bin/bash
# =============================================================================
# effect-dustscratches.sh — QA test / regression guard
#
# EFFECTS > Dust & Scratches... thresholded median (removes outlier speckle).
# (Added 2026-08-14.) Thin crossing strokes act as outliers vs the mostly-black
# neighbourhood; a high threshold pass thins/cleans them. Assert the region
# changed.
#
# EFFECTS menu index 37 (0-based) -> dropdown item viewport y = 20 + 37*12 = 464.
# =============================================================================

info "=== Effect: Dust & Scratches Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY + 20 ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG"
drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY + 20 )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY - 20 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 30 )); GW=80; GH=60
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "dustscratches-before"
BEFORE="$SNAP_RESULT"

open_effect 5 2 ; wait_for 0.5 "Dust & Scratches dialog open"
screenshot "dustscratches-dialog"
drag 400 317 480 317 ; wait_for 0.2 "Threshold set"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "dustscratches-after"
AFTER="$SNAP_RESULT"
screenshot "dustscratches-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Dust & Scratches must clean up the thin strokes"
assert_no_crash
assert_window_exists
info "=== Effect: Dust & Scratches Test PASSED ==="
