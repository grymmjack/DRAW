#!/bin/bash
# =============================================================================
# effect-median.sh — QA test / regression guard
#
# EFFECTS > Median / Despeckle... 3x3 per-channel median (one-shot).
# (Added 2026-08-14.) Crossing thin green + red strokes give edges/corners the
# median reshapes; assert the intersection region changed.
#
# EFFECTS menu index 36 (0-based) -> dropdown item viewport y = 20 + 36*12 = 452.
# =============================================================================

info "=== Effect: Median / Despeckle Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY + 20 ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG"
drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY + 20 )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY - 20 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 30 )); GW=80; GH=60
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "median-before"
BEFORE="$SNAP_RESULT"

# One-shot: clicking applies immediately.
click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 452 ; wait_for 0.8 "Median applied"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "median-after"
AFTER="$SNAP_RESULT"
screenshot "median-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Median must reshape the crossing strokes"
assert_no_crash
assert_window_exists
info "=== Effect: Median / Despeckle Test PASSED ==="
