#!/bin/bash
# =============================================================================
# effect-bevel.sh — QA test / regression guard
#
# EFFECTS > Bevel... raises the shape into a lit 3D button (top-left highlight,
# bottom-right shadow via a distance-to-edge heightfield). (Added 2026-08-14.)
# Draws a THICK green blob on a transparent layer (needs interior), applies
# Bevel, and asserts the flat green gained shading.
#
# EFFECTS menu index 17 (0-based) -> dropdown item viewport y = 20 + 17*12 = 224.
# =============================================================================

info "=== Effect: Bevel Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
# Big brush so the stroke has interior for the bevel heightfield.
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 16 )); GW=80; GH=32
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "bevel-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 224 ; wait_for 0.7 "Bevel dialog open"
screenshot "bevel-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "bevel-after"
AFTER="$SNAP_RESULT"
screenshot "bevel-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Bevel must add highlight/shadow shading to the flat green blob"
assert_no_crash
assert_window_exists
info "=== Effect: Bevel Test PASSED ==="
