#!/bin/bash
# QA/tests/tool-ellipse.sh
# Test: Ellipse Tool (outline and filled)
# Tests ellipse drawing, filled variant, and undo restoration.

# --- Setup: focus canvas and switch to ellipse tool ---
canvas_focus e
wait_for 0.3 "Ellipse tool ready"

# --- Increase brush size for visibility ---
key bracketright
key bracketright
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"

# --- Hide pointer arrow ---
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap work area BEFORE outline ellipse ---
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "ellipse-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# --- Draw outline ellipse (large drag for visibility) ---
drag $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 35 )) $(( CANVAS_CX + 50 )) $(( CANVAS_CY + 35 ))
wait_for 0.5 "Outline ellipse drawn"
assert_no_crash

# --- Snap work area AFTER outline ellipse ---
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "ellipse-outline-after"
AFTER_OUTLINE="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER_OUTLINE" "Outline ellipse should be visible on canvas"

# --- Undo outline ellipse ---
key ctrl+z
wait_for 0.5 "Undo outline ellipse"
assert_no_crash

# --- Snap work area AFTER undo ---
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "ellipse-outline-undo"
UNDO_OUTLINE="$SNAP_RESULT"
assert_regions_differ "$AFTER_OUTLINE" "$UNDO_OUTLINE" "Undo should change canvas from outline ellipse"

# --- Switch to filled ellipse (Shift+E) ---
key shift+e
wait_for 0.3 "Switch to filled ellipse"

# --- Snap work area BEFORE filled ellipse ---
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "ellipse-filled-before"
BEFORE_FILLED="$SNAP_RESULT"
assert_no_crash

# --- Draw filled ellipse (large drag for visibility) ---
drag $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 35 )) $(( CANVAS_CX + 50 )) $(( CANVAS_CY + 35 ))
wait_for 0.5 "Filled ellipse drawn"
assert_no_crash

# --- Snap work area AFTER filled ellipse ---
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "ellipse-filled-after"
AFTER_FILLED="$SNAP_RESULT"
assert_regions_differ "$BEFORE_FILLED" "$AFTER_FILLED" "Filled ellipse should be visible on canvas"

# --- Undo filled ellipse ---
wake_draw
key ctrl+z
key ctrl+z
wait_for 0.5 "Undo filled ellipse"
assert_no_crash

# --- Snap work area AFTER undo ---
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "ellipse-filled-undo"
UNDO_FILLED="$SNAP_RESULT"
assert_regions_differ "$AFTER_FILLED" "$UNDO_FILLED" "Undo should change canvas from filled ellipse"

assert_window_exists
