#!/bin/bash
# =============================================================================
# effect-selshape.sh — QA test / regression guard
#
# SELECTION-AS-SHAPE for edge effects (added 2026-08-15).
#
# Alpha-edge effects (Drop Shadow, Outline, Grow, Bevel, Glows, …) read the
# layer's ALPHA edge to find the silhouette. On a SOLID layer there is no edge,
# so historically they did nothing — and clip-to-selection wiped them because
# they draw OUTSIDE the shape. The fix: when a selection is active, the effect
# uses the SELECTION silhouette as its shape and radiates from the selection
# edge, compositing the new pixels over the untouched layer.
#
# This test PROVES that path with a discriminating setup:
#   * Paint a LARGE solid green block (no internal alpha edge).
#   * Make a PARTIAL rectangular marquee selection inside the block.
#   * Set BG = red (the drop-shadow colour, so it is obvious on green).
#   * Apply Drop Shadow (default 315° = down-right).
#   * Sample a strip INSIDE the block, just DOWN-RIGHT of the selection.
#
# Without sel-as-shape the block's own shadow would fall OUTSIDE the block, far
# from the sample — so a change in that interior strip can ONLY come from the
# SELECTION casting a shadow. Drop Shadow = open_effect 2 0.
# =============================================================================

info "=== Effect: Selection-as-Shape (Drop Shadow radiates from selection) Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Solid green block covering the selection + sample area (several overlapping passes).
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
for dy in -40 -30 -20 -10 0 10 20 30 40; do
    drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY + dy ))
done
# BG = red (shadow colour) via FG=red + swap.
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG red"
key x ; wait_for 0.2 "Swap -> BG red (shadow colour)"
key grave
wait_for 0.3 "Block drawn"
assert_no_crash

# Partial rectangular marquee selection in the upper-left of the block.
key m ; wait_for 0.2 "Rect marquee tool"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 30 )) $(( CANVAS_CX + 8 )) $(( CANVAS_CY + 8 ))
wait_for 0.3 "Selection made"

# Sample strip INSIDE the block, just down-right of the selection's corner where a
# 315° shadow of the SELECTION lands. Clear of the selection's marching ants.
GX=$(( CANVAS_CX + 11 )); GY=$(( CANVAS_CY + 11 )); GW=20; GH=20
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "selshape-before"
BEFORE="$SNAP_RESULT"

open_effect 2 0 ; wait_for 0.5 "Drop Shadow dialog open"
screenshot "selshape-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "selshape-after"
AFTER="$SNAP_RESULT"
screenshot "selshape-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Sel-as-shape: Drop Shadow must cast the SELECTION's shadow onto the solid layer OUTSIDE the selection"
assert_no_crash
assert_window_exists
info "=== Effect: Selection-as-Shape Test PASSED ==="
