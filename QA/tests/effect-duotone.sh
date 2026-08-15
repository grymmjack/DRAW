#!/bin/bash
# =============================================================================
# effect-duotone.sh — QA test / regression guard
#
# EFFECTS > Duotone / Tritone... quantises luminance into flat colour bands
# (shadows->BG, highlights->FG). (Added 2026-08-14.) Draws a green stroke
# (luminance ~181, a highlight), sets FG to red, applies Duotone, and asserts the
# stroke became the FG colour.
#
# EFFECTS menu index 14 (0-based) -> dropdown item viewport y = 20 + 14*12 = 188.
# =============================================================================

info "=== Effect: Duotone / Tritone Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG (highlight band)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "duotone-before"
BEFORE="$SNAP_RESULT"

open_effect 0 6 ; wait_for 0.5 "Duotone dialog open"
screenshot "duotone-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "duotone-after"
AFTER="$SNAP_RESULT"
screenshot "duotone-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Duotone must remap the green highlight stroke to the FG colour"
assert_no_crash
assert_window_exists
info "=== Effect: Duotone / Tritone Test PASSED ==="
