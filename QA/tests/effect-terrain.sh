#!/bin/bash
# =============================================================================
# effect-terrain.sh — QA test / regression guard
#
# EFFECTS > Terrain... fills the layer with a fractal terrain map (water/sand/
# grass/rock/snow). (Added 2026-08-14.) On a blank canvas, apply, assert the
# centre filled.
#
# EFFECTS menu index 34 (0-based) -> dropdown item viewport y = 20 + 34*12 = 428.
# =============================================================================

info "=== Effect: Terrain Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key grave
wait_for 0.2 "Pointer hidden"

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "terrain-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 428 ; wait_for 0.7 "Terrain dialog open"
screenshot "terrain-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "terrain-after"
AFTER="$SNAP_RESULT"
screenshot "terrain-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Terrain must fill the layer with a terrain map"
assert_no_crash
assert_window_exists
info "=== Effect: Terrain Test PASSED ==="
