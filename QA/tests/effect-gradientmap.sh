#!/bin/bash
# =============================================================================
# effect-gradientmap.sh — QA test / regression guard
#
# EFFECTS > Gradient Map... recolours by luminance along a BG->FG ramp.
# (Added 2026-08-14.) Draws a mid-grey stroke, sets FG to red (highlight end),
# applies Gradient Map, and asserts the grey stroke was recoloured.
#
# EFFECTS menu index 9 (0-based) -> dropdown item viewport y = 20 + 9*12 = 128.
# =============================================================================

info "=== Effect: Gradient Map Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Mid-grey stroke (chip 16 = 112,112,112), then set FG to red (chip 23) — the
# ramp's highlight end. Grey luminance maps to a non-grey ramp colour.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 16*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Grey FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG (ramp highlight)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "gradientmap-before"
BEFORE="$SNAP_RESULT"

# Open Gradient Map via EFFECTS menu, commit with Return (default BG->FG ramp).
open_effect 0 4 ; wait_for 0.5 "Gradient Map dialog open"
screenshot "gradientmap-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "gradientmap-after"
AFTER="$SNAP_RESULT"
screenshot "gradientmap-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Gradient Map must recolour the grey stroke along the ramp"
assert_no_crash
assert_window_exists
info "=== Effect: Gradient Map Test PASSED ==="
