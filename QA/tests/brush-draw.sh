#!/bin/bash
# QA/tests/brush-draw.sh — Draw a stroke with the brush tool and verify no crash
#
# Uses $CANVAS_CX / $CANVAS_CY from the harness (computed from DRAW.cfg).
# Coordinates are in internal viewport pixels; harness multiplies by DISPLAY_SCALE.

# Select brush tool via hotkey
info "Selecting brush tool (b)"
key b
assert_no_crash
wait_for 0.2 "tool switch"

# Draw a horizontal stroke across the canvas centre
info "Drawing brush stroke"
drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.2 "stroke settle"
assert_no_crash

screenshot "brush-stroke"

# Undo the stroke
info "Undoing stroke (Ctrl+Z)"
key ctrl+z
wait_for 0.2 "undo settle"
assert_no_crash

screenshot "brush-stroke-undone"

assert_window_exists
