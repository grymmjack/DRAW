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

# -- Set baseline: park mouse away from canvas, snap canvas area --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "cross-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Hold Shift and move mouse onto canvas center to trigger crosshair --
# The crosshair renders on the full work area, so snap the entire work area.
# Use harness _abs for proper coordinate mapping.
info "Holding Shift and moving to canvas center"
draw_focus
local ax ay 2>/dev/null
read -r ax ay <<< "$(_abs $CANVAS_CX $CANVAS_CY)"
xdotool keydown shift
sleep 0.1
xdotool mousemove "$ax" "$ay"
sleep 0.6  # Give DRAW time to render crosshair

# -- Snap while shift held and mouse on canvas --
# DON'T park_mouse — cursor must stay on canvas for crosshair to render
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "cross-shift-held"
WITH_SHIFT="$SNAP_RESULT"
xdotool keyup shift
wait_for 0.3 "Shift released"
assert_no_crash

# -- Crosshair lines should have changed the work area --
assert_regions_differ "$BEFORE" "$WITH_SHIFT" "Crosshair should appear while Shift is held"

assert_window_exists
info "=== Crosshair Test PASSED ==="
