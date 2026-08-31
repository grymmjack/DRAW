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
# Fill the sample with MANY overlapping colour bands so Crystallize's Voronoi cells
# visibly reshape the colour boundaries (flat single-colour strokes barely change,
# since a cell of one colour crystallizes to the same colour). Green + red + blue
# stripes packed across the sample give plenty of boundaries.
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
for dy in -30 -12 6 24; do drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY + dy )); done
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG"
for dy in -24 -6 12 30; do drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY + dy )); done
click $(( 16 + 1*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Blue FG"
for dx in -40 0 40; do drag $(( CANVAS_CX + dx )) $(( CANVAS_CY - 40 )) $(( CANVAS_CX + dx )) $(( CANVAS_CY + 40 )); done
key grave
wait_for 0.3 "Multi-colour content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "crystallize-before"
BEFORE="$SNAP_RESULT"

open_effect 4 0 ; wait_for 0.5 "Crystallize dialog open"
screenshot "crystallize-dialog"
# Drag CELL SIZE to the far right (large cells) so the striped sample collapses into
# a couple of solid Voronoi cells — a dramatic, supra-threshold change. Slider spans
# vp x≈359..599 at y≈310; drag from left to the right edge.
drag 365 310 598 310 ; wait_for 0.2 "Cell size -> large"
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
