#!/bin/bash
# =============================================================================
# effect-edgedetect.sh — QA test / regression guard
#
# EFFECTS > Edge Detect... turns the layer into Sobel line art (flat areas ->
# black, edges -> white). (Added 2026-08-14.) Draws a green stroke on the opaque
# background, applies Edge Detect, asserts the stroke region changed (flat green
# collapses to black with white edges).
#
# EFFECTS menu index 8 (0-based) -> dropdown item viewport y = 20 + 8*12 = 116.
# =============================================================================

info "=== Effect: Edge Detect Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Green stroke on the opaque background — its edges are what Sobel picks up.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 10 )); GW=120; GH=20
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "edgedetect-before"
BEFORE="$SNAP_RESULT"

# Open Edge Detect via EFFECTS menu (default strength 100 already applies), commit.
open_effect 1 4 ; wait_for 0.5 "Edge Detect dialog open"
screenshot "edgedetect-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "edgedetect-after"
AFTER="$SNAP_RESULT"
screenshot "edgedetect-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Edge Detect must convert the flat green stroke to edges"
assert_no_crash
assert_window_exists
info "=== Effect: Edge Detect Test PASSED ==="
