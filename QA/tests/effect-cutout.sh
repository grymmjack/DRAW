#!/bin/bash
# =============================================================================
# effect-cutout.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Cutout... inset (inner) shadow on the top-left edge so the
# shape looks punched through. (Added 2026-08-14, Eye Candy.) Thick green blob on
# a transparent layer, apply, assert the region changed (darkened inner edge).
#
# SHAPE is EFFECTS category index 7; Cutout is child 2 -> open_effect 7 2.
# =============================================================================

info "=== Effect: Cutout Test ==="

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

GX=$(( CANVAS_CX - 44 )); GY=$(( CANVAS_CY - 16 )); GW=88; GH=32
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "cutout-before"
BEFORE="$SNAP_RESULT"

open_effect 7 2 ; wait_for 0.5 "Cutout dialog open"
screenshot "cutout-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "cutout-after"
AFTER="$SNAP_RESULT"
screenshot "cutout-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Cutout must darken the shape's inner top-left edge"
assert_no_crash
assert_window_exists
info "=== Effect: Cutout Test PASSED ==="
