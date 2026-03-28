#!/bin/bash
# =============================================================================
# util-crosshair.sh — QA test: Crosshair assistant visibility
# Tests: Shift hold shows crosshair lines on canvas
# =============================================================================

info "=== Crosshair Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Move mouse to canvas center without Shift --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "cross-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Hold Shift and move to canvas center to show crosshair --
info "Holding Shift to show crosshair"
xdotool keydown shift
sleep 0.1
xdotool mousemove --window "$WID" $CANVAS_CX $CANVAS_CY
sleep 0.5

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "cross-shift-held"
WITH_SHIFT="$SNAP_RESULT"
xdotool keyup shift
wait_for 0.3 "Shift released"
assert_no_crash

# -- Crosshair lines should have changed the canvas area --
assert_regions_differ "$BEFORE" "$WITH_SHIFT" "Crosshair should appear while Shift is held"

assert_window_exists
info "=== Crosshair Test PASSED ==="
