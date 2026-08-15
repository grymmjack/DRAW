#!/bin/bash
# =============================================================================
# effect-dropshadow.sh — QA test / regression guard
#
# EFFECTS > Drop Shadow... composites an offset, softened silhouette (in the BG
# colour) behind the shape. (Added 2026-08-14.) On a TRANSPARENT layer: draws a
# green stroke, sets BG to red (so the shadow is visible on the dark canvas),
# applies Drop Shadow, and asserts new shadow pixels appear below/right.
#
# EFFECTS menu index 15 (0-based) -> dropdown item viewport y = 20 + 15*12 = 200.
# =============================================================================

info "=== Effect: Drop Shadow Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Green stroke, then make BG red (shadow colour) via FG=red + swap (X).
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG red"
key x ; wait_for 0.2 "Swap -> BG red (shadow colour)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Band spanning the stroke and the area just below-right where the shadow falls.
GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=130; GH=30
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "dropshadow-before"
BEFORE="$SNAP_RESULT"

open_effect 2 0 ; wait_for 0.5 "Drop Shadow dialog open"
screenshot "dropshadow-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "dropshadow-after"
AFTER="$SNAP_RESULT"
screenshot "dropshadow-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Drop Shadow must add an offset shadow behind the stroke"
assert_no_crash
assert_window_exists
info "=== Effect: Drop Shadow Test PASSED ==="
