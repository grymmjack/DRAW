#!/bin/bash
# QA/tests/tool-spray.sh
# Test: Spray Tool
# Tests spray paint application via drag, visibility, and undo restoration.

# --- Setup: ensure spray tool and canvas focus ---
canvas_focus a
wait_for 0.3 "Spray tool ready"
key bracketright
key bracketright
key bracketright
key bracketright
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap work area BEFORE spray ---
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "spray-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# --- Hold spray at canvas center for longer duration (spray accumulates over time) ---
local ax ay
read -r ax ay <<< "$(_abs "$CANVAS_CX" "$CANVAS_CY")"
draw_focus
xdotool mousemove "$ax" "$ay"
sleep 0.1
xdotool mousedown 1
sleep 0.8
xdotool mousemove $(( ax + 30 )) $(( ay + 20 ))
sleep 0.5
xdotool mousemove $(( ax - 30 )) $(( ay - 20 ))
sleep 0.5
xdotool mouseup 1
wait_for 0.3 "Spray applied with extended hold"
assert_no_crash

# --- Snap work area AFTER spray ---
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "spray-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Spray should be visible on canvas"

# --- Undo spray (may need multiple undos if spray created multiple history states) ---
key ctrl+z
wait_for 0.3 "Undo spray 1"
key ctrl+z
wait_for 0.3 "Undo spray 2"
key ctrl+z
wait_for 0.5 "Undo spray 3"
assert_no_crash

# --- Snap work area AFTER undo ---
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "spray-undo"
UNDO="$SNAP_RESULT"
assert_regions_differ "$AFTER" "$UNDO" "Undo should change canvas from spray state"

assert_window_exists
