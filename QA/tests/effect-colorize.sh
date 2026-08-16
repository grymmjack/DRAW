#!/bin/bash
# =============================================================================
# effect-colorize.sh — QA test / regression guard
#
# EFFECTS > Colorize... recolors the layer to a single hue while keeping each
# pixel's brightness. (Added 2026-08-14.) Draws a grey stroke (brightness kept,
# hue added), opens Colorize, nudges the HUE slider, commits with Return, and
# asserts the grey region gained color.
# =============================================================================

info "=== Effect: Colorize Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Mid-grey stroke (chip 16 = 112,112,112). Colorize tints it toward the hue.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 16*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Grey FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "colorize-before"
BEFORE="$SNAP_RESULT"

# Open Colorize; nudge HUE (row 0) and SATURATION (row 1) to guarantee a change,
# then commit with Return.
open_effect 0 3 ; wait_for 0.5 "Colorize dialog open"
screenshot "colorize-dialog"
drag 400 317 560 317 ; wait_for 0.2 "Hue moved"
drag 400 355 580 355 ; wait_for 0.2 "Saturation up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "colorize-after"
AFTER="$SNAP_RESULT"
screenshot "colorize-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Colorize must tint the grey stroke with the chosen hue"
assert_no_crash
assert_window_exists
info "=== Effect: Colorize Test PASSED ==="
