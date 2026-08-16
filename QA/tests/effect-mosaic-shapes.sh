#!/bin/bash
# =============================================================================
# effect-mosaic-shapes.sh — QA test / regression guard
#
# CELL-SHAPE picker for Mosaic (added 2026-08-15). Mosaic gained a SHAPE dropdown
# (square/rectangle/triangle/hexagon/voronoi/random) and a SEED slider. The engine
# was rewritten to a cell-ID map: direct formulas for square/rect/triangle, and
# nearest-seed assignment for hex/voronoi/random (grout is now shape-agnostic —
# a pixel is grout when a neighbour's cell ID differs).
#
# This test selects VORONOI via the dropdown (exercising the seed-lattice +
# nearest-seed + cell-ID codepath) and asserts the region changed with no crash.
# effect-mosaic.sh covers the default square path.
#
# Mosaic = open_effect 4 2. Dialog 256x368 centred in 958x514 → top≈73, left≈351.
# Shape dropdown box at dialog-local (8,264) => viewport ≈ (359,337); click (380,344).
# OK button at local (8, 338) => viewport ≈ (359,411); click (395,411).
# =============================================================================

info "=== Effect: Mosaic Cell-Shape (Voronoi) Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
# Two-colour content so averaged cells differ visibly.
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
for dy in -30 -10 10 30; do
    drag $(( CANVAS_CX - 90 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 90 )) $(( CANVAS_CY + dy ))
done
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG"
for dx in -60 -20 20 60; do
    drag $(( CANVAS_CX + dx )) $(( CANVAS_CY - 40 )) $(( CANVAS_CX + dx )) $(( CANVAS_CY + 40 ))
done
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 45 )); GW=120; GH=90
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "mosaic-shape-before"
BEFORE="$SNAP_RESULT"

open_effect 4 2 ; wait_for 0.5 "Mosaic dialog open"
screenshot "mosaic-shape-dialog"
# Open the SHAPE dropdown and arrow down to VORONOI (index 4: square,rect,tri,hex,voronoi).
click 380 344 ; wait_for 0.3 "Shape dropdown open"
for i in 1 2 3 4; do key Down; done
wait_for 0.2 "Highlight Voronoi"
key Return ; wait_for 0.3 "Shape = Voronoi"
screenshot "mosaic-shape-voronoi"
click 395 411 ; wait_for 0.7 "Applied (OK)"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "mosaic-shape-after"
AFTER="$SNAP_RESULT"
screenshot "mosaic-shape-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Mosaic with a Voronoi cell shape must tessellate the content"
assert_no_crash
assert_window_exists
info "=== Effect: Mosaic Cell-Shape Test PASSED ==="
