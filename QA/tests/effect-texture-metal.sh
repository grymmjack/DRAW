#!/bin/bash
# =============================================================================
# effect-texture-metal.sh — QA test / regression guard
#
# EFFECTS > TEXTURE > Diamond Plate(13), Lightning(14).
# (Added 2026-08-15.) Brushed Metal + Weave are new engines; Clouds re-parents
# the existing RENDER Clouds engine into TEXTURE. Verifies each navigates in the
# TEXTURE flyout and paints its surface onto the shape.
#   open_effect 8 13 / 8 14
# =============================================================================

info "=== Effect: TEXTURE more (DiamondPlate/Lightning) Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 40 )) "$CANVAS_CY" $(( CANVAS_CX + 40 )) "$CANVAS_CY"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 12 )); GW=80; GH=24

texture_case() {
    local child=$1 name=$2
    park_mouse
    snap_region "$GX" "$GY" "$GW" "$GH" "$name-before"
    local before="$SNAP_RESULT"
    open_effect 8 "$child" ; wait_for 0.5 "$name dialog open"
    screenshot "$name-dialog"
    key Return ; wait_for 0.7 "Applied (OK), dialog closed"
    assert_no_crash
    park_mouse
    snap_region "$GX" "$GY" "$GW" "$GH" "$name-after"
    assert_regions_differ "$before" "$SNAP_RESULT" \
        "TEXTURE>$name (open_effect 8 $child) must paint its surface onto the shape"
    key ctrl+z ; wait_for 0.4 "Undo texture"
}

texture_case 13 "diamondplate"
texture_case 14 "lightning"

assert_no_crash
assert_window_exists
info "=== Effect: TEXTURE more Test PASSED ==="
