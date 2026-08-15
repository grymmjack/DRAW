#!/bin/bash
# =============================================================================
# effect-fire-selection.sh — QA test / regression guard
#
# SELECTION-AS-SHAPE for the "Shape" effect family (added 2026-08-15).
#
# The Eye-Candy "Shape" effects (Fire, Smoke, Snow, Drip, Icicles, Electrify,
# Motion Trail) radiate off the layer silhouette. Historically they read the
# layer's own alpha edge and then apply_spatial CLIPPED the result to the
# selection — so with a selection active they either did nothing useful or got
# hard-cut at the selection border. The fix routes them through the SAME
# sel-as-shape choke point the alpha-edge effects use (IMGADJ_edge_shape_source
# + IMAGE_ADJ_apply_spatial_edge): when a selection is active the effect uses the
# SELECTION silhouette as its shape and radiates from the selection edge.
#
# This test PROVES that path for Fire (the user's named example):
#   * Paint a LARGE solid green block (no internal alpha edge).
#   * Make a rectangular marquee selection INSIDE the block.
#   * Apply Fire. Flames rise UP off the shape's top edge.
#   * Sample a strip just ABOVE the selection's TOP edge, still inside the block.
#
# Without sel-as-shape the block's own flames would rise off the block's TOP edge
# (far above the sample, outside the block) — so a change in that interior strip
# can ONLY come from the SELECTION acting as the shape. Fire = open_effect 7 13.
# =============================================================================

info "=== Effect: Fire Selection-as-Shape (flames radiate from selection edge) Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Solid green block covering the selection + sample area (overlapping passes).
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
for dy in -40 -30 -20 -10 0 10 20 30 40; do
    drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY + dy ))
done
key grave
wait_for 0.3 "Block drawn"
assert_no_crash

# Rectangular marquee selection whose TOP edge sits well inside the block, so the
# flames rising above it (~20px default) stay on green.
key m ; wait_for 0.2 "Rect marquee tool"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 8 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 ))
wait_for 0.3 "Selection made"

# Sample strip just ABOVE the selection's top edge, inside the block, clear of the
# selection's marching ants (which sit on the CY-8 edge line).
GX=$(( CANVAS_CX - 30 )); GY=$(( CANVAS_CY - 28 )); GW=60; GH=14
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "fire-sel-before"
BEFORE="$SNAP_RESULT"

open_effect 7 13 ; wait_for 0.5 "Fire dialog open"
screenshot "fire-sel-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "fire-sel-after"
AFTER="$SNAP_RESULT"
screenshot "fire-sel-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Sel-as-shape: Fire must radiate the SELECTION's flames onto the solid layer above the selection edge"
assert_no_crash
assert_window_exists
info "=== Effect: Fire Selection-as-Shape Test PASSED ==="
