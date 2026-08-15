#!/bin/bash
# =============================================================================
# effect-filmgrain.sh — QA test / regression guard
#
# EFFECTS > Film Grain... adds monochrome photographic noise. (Added 2026-08-14.)
# Draws a flat grey stroke (so added noise is obvious), applies Film Grain via
# the EFFECTS menu, commits, asserts the region changed.
#
# EFFECTS menu index 5 -> dropdown item viewport y = 20 + 5*12 = 80.
# =============================================================================

info "=== Effect: Film Grain Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Flat mid-grey stroke (chip 16 = 112,112,112) — grain scatters it.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 16*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Grey FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "filmgrain-before"
BEFORE="$SNAP_RESULT"

# Open Film Grain via EFFECTS menu, bump AMOUNT, commit with Return.
open_effect 1 1 ; wait_for 0.5 "Film Grain dialog open"
screenshot "filmgrain-dialog"
drag 400 317 580 317 ; wait_for 0.2 "Amount up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "filmgrain-after"
AFTER="$SNAP_RESULT"
screenshot "filmgrain-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Film Grain must add noise to the flat grey stroke"
assert_no_crash
assert_window_exists
info "=== Effect: Film Grain Test PASSED ==="
