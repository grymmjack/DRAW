#!/bin/bash
# =============================================================================
# effect-mosaic.sh — QA test / regression guard
#
# EFFECTS > Mosaic / Tessellate... averages each tile block (+ optional grout).
# (Added 2026-08-14.) Crossing green + red strokes, apply, assert the region
# changed (averaged blocky tiles).
#
# EFFECTS menu index 27 (0-based) -> dropdown item viewport y = 20 + 27*12 = 344.
# =============================================================================

info "=== Effect: Mosaic / Tessellate Test ==="

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
snap_region "$GX" "$GY" "$GW" "$GH" "mosaic-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 344 ; wait_for 0.7 "Mosaic dialog open"
screenshot "mosaic-dialog"
drag 400 317 560 317 ; wait_for 0.2 "Tile size up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "mosaic-after"
AFTER="$SNAP_RESULT"
screenshot "mosaic-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Mosaic must average the strokes into tiles"
assert_no_crash
assert_window_exists
info "=== Effect: Mosaic / Tessellate Test PASSED ==="
