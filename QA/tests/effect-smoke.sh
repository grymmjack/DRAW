#!/bin/bash
# =============================================================================
# effect-smoke.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Smoke... a wispy translucent grey plume rises off the shape's
# top edge (Fire's top-scan, but noise-dominated density -> gappy wisps, cool
# grey ramp at low alpha). (Added 2026-08-14, Eye Candy SHAPE.) apply_spatial.
#
# SHAPE is EFFECTS category index 7; Smoke is child 14 -> open_effect 7 14.
# =============================================================================

info "=== Effect: Smoke Test ==="

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

# Band above the blob, where the smoke plume rises.
GX=$(( CANVAS_CX - 44 )); GY=$(( CANVAS_CY - 30 )); GW=88; GH=28
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "smoke-before"
BEFORE="$SNAP_RESULT"

open_effect 7 14 ; wait_for 0.5 "Smoke dialog open"
screenshot "smoke-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "smoke-after"
AFTER="$SNAP_RESULT"
screenshot "smoke-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Smoke must raise a wispy plume above the shape"
assert_no_crash
assert_window_exists
info "=== Effect: Smoke Test PASSED ==="
