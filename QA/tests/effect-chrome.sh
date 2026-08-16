#!/bin/bash
# =============================================================================
# effect-chrome.sh — QA test / regression guard
#
# EFFECTS > Chrome / Metallic... maps a distance-field metallic band ramp
# (BG->FG) onto the shape for a shiny-metal look. (Added 2026-08-14.) Thick green
# blob on a transparent layer, FG set to white (highlight, BG stays dark), apply
# Chrome, assert the flat green became metallic bands.
#
# EFFECTS menu index 20 (0-based) -> dropdown item viewport y = 20 + 20*12 = 260.
# =============================================================================

info "=== Effect: Chrome / Metallic Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY ))
click $(( 16 + 31*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG white (metal highlight)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 44 )); GY=$(( CANVAS_CY - 16 )); GW=88; GH=32
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "chrome-before"
BEFORE="$SNAP_RESULT"

open_effect 2 5 ; wait_for 0.5 "Chrome dialog open"
screenshot "chrome-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "chrome-after"
AFTER="$SNAP_RESULT"
screenshot "chrome-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Chrome must remap the flat green blob to metallic bands"
assert_no_crash
assert_window_exists
info "=== Effect: Chrome / Metallic Test PASSED ==="
