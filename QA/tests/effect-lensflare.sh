#!/bin/bash
# =============================================================================
# effect-lensflare.sh — QA test / regression guard
#
# EFFECTS > Lens Flare... additively composites a bright core + halo orbs.
# (Added 2026-08-14.) On a dark canvas, apply, and assert the upper-left flare
# region brightened.
#
# EFFECTS menu index 33 (0-based) -> dropdown item viewport y = 20 + 33*12 = 416.
# =============================================================================

info "=== Effect: Lens Flare Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key grave
wait_for 0.2 "Pointer hidden"

# Flare point is at ~image(0.32w, 0.3h) -> upper-left of the canvas.
GX=$(( CANVAS_CX - 90 )); GY=$(( CANVAS_CY - 70 )); GW=90; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "lensflare-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 416 ; wait_for 0.7 "Lens Flare dialog open"
screenshot "lensflare-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "lensflare-after"
AFTER="$SNAP_RESULT"
screenshot "lensflare-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Lens Flare must add a bright flare"
assert_no_crash
assert_window_exists
info "=== Effect: Lens Flare Test PASSED ==="
