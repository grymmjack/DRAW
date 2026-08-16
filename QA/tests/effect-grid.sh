#!/bin/bash
# =============================================================================
# effect-grid.sh — QA test / regression guard
#
# EFFECTS > Render Grid... draws a grid over the layer in the FG colour.
# (Added 2026-08-14.) FG=white on a blank canvas, apply, assert the centre gained
# grid lines.
#
# EFFECTS menu index 38 (0-based) -> dropdown item viewport y = 20 + 38*12 = 476.
# =============================================================================

info "=== Effect: Render Grid Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 31*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "White FG (line colour)"
key grave
wait_for 0.2 "Pointer hidden"

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "grid-before"
BEFORE="$SNAP_RESULT"

open_effect 6 4 ; wait_for 0.5 "Render Grid dialog open"
screenshot "grid-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "grid-after"
AFTER="$SNAP_RESULT"
screenshot "grid-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Render Grid must draw grid lines"
assert_no_crash
assert_window_exists
info "=== Effect: Render Grid Test PASSED ==="
