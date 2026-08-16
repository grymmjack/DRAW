#!/bin/bash
# =============================================================================
# effect-addnoise.sh — QA test / regression guard
#
# EFFECTS > Add Noise... adds per-pixel random noise. (Added 2026-08-14.)
# Flat grey stroke, apply, assert the region changed (grain).
#
# EFFECTS menu index 35 (0-based) -> dropdown item viewport y = 20 + 35*12 = 440.
# =============================================================================

info "=== Effect: Add Noise Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 16*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Grey FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "addnoise-before"
BEFORE="$SNAP_RESULT"

open_effect 5 0 ; wait_for 0.5 "Add Noise dialog open"
screenshot "addnoise-dialog"
drag 400 317 560 317 ; wait_for 0.2 "Amount up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "addnoise-after"
AFTER="$SNAP_RESULT"
screenshot "addnoise-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Add Noise must add grain to the flat stroke"
assert_no_crash
assert_window_exists
info "=== Effect: Add Noise Test PASSED ==="
