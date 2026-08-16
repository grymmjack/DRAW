#!/bin/bash
# =============================================================================
# effect-sky.sh — QA test / regression guard
#
# EFFECTS > Render Sky... fills the layer with a procedural sky (day/night/space).
# (Added 2026-08-14.) On a blank canvas, drive MODE to space, apply, assert the
# centre filled.
#
# EFFECTS menu index 39 (0-based) -> dropdown item viewport y = 20 + 39*12 = 488.
# =============================================================================

info "=== Effect: Render Sky Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key grave
wait_for 0.2 "Pointer hidden"

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "sky-before"
BEFORE="$SNAP_RESULT"

open_effect 6 5 ; wait_for 0.5 "Render Sky dialog open"
screenshot "sky-dialog"
drag 400 317 590 317 ; wait_for 0.2 "Mode -> space"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "sky-after"
AFTER="$SNAP_RESULT"
screenshot "sky-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Render Sky must fill the layer with a sky"
assert_no_crash
assert_window_exists
info "=== Effect: Render Sky Test PASSED ==="
