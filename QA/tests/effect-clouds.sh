#!/bin/bash
# =============================================================================
# effect-clouds.sh — QA test / regression guard
#
# EFFECTS > Clouds... fills the layer with fractal plasma (BG..FG ramp).
# (Added 2026-08-14.) On a blank canvas, apply Clouds, assert the centre filled
# with noise (was black).
#
# EFFECTS menu index 31 (0-based) -> dropdown item viewport y = 20 + 31*12 = 392.
# =============================================================================

info "=== Effect: Clouds Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key grave
wait_for 0.2 "Pointer hidden"

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "clouds-before"
BEFORE="$SNAP_RESULT"

open_effect 6 0 ; wait_for 0.5 "Clouds dialog open"
screenshot "clouds-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "clouds-after"
AFTER="$SNAP_RESULT"
screenshot "clouds-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Clouds must fill the layer with plasma noise"
assert_no_crash
assert_window_exists
info "=== Effect: Clouds Test PASSED ==="
