#!/bin/bash
# =============================================================================
# effect-crystallize.sh — QA test / regression guard
#
# EFFECTS > Crystallize... breaks the image into flat Voronoi crystals.
# (Added 2026-08-14.) Draws crossing green + red strokes, applies Crystallize,
# and asserts the region changed (smooth strokes -> polygonal cells).
#
# EFFECTS menu index 25 (0-based) -> dropdown item viewport y = 20 + 25*12 = 320.
# =============================================================================

info "=== Effect: Crystallize Test ==="

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
snap_region "$GX" "$GY" "$GW" "$GH" "crystallize-before"
BEFORE="$SNAP_RESULT"

open_effect 4 0 ; wait_for 0.5 "Crystallize dialog open"
screenshot "crystallize-dialog"
drag 400 317 560 317 ; wait_for 0.2 "Cell size up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "crystallize-after"
AFTER="$SNAP_RESULT"
screenshot "crystallize-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Crystallize must break the strokes into cells"
assert_no_crash
assert_window_exists
info "=== Effect: Crystallize Test PASSED ==="
