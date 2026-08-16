#!/bin/bash
# =============================================================================
# effect-backlight.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Backlight... fills the transparent area with a radial sunburst
# of light rays (FG colour) behind the shape. (Added 2026-08-14, Eye Candy.)
# Transparent layer: green blob, FG=white, apply, assert rays appear off-centre.
#
# SHAPE is EFFECTS category index 7; Backlight is child 0 -> open_effect 7 0.
# =============================================================================

info "=== Effect: Backlight Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 20 )) "$CANVAS_CY" $(( CANVAS_CX + 20 )) "$CANVAS_CY"
click $(( 16 + 31*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG white (ray colour)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Sample off-centre (transparent before, rays after).
GX=$(( CANVAS_CX - 55 )); GY=$(( CANVAS_CY - 45 )); GW=40; GH=40
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "backlight-before"
BEFORE="$SNAP_RESULT"

open_effect 7 0 ; wait_for 0.5 "Backlight dialog open"
screenshot "backlight-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "backlight-after"
AFTER="$SNAP_RESULT"
screenshot "backlight-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Backlight must add light rays behind the shape"
assert_no_crash
assert_window_exists
info "=== Effect: Backlight Test PASSED ==="
