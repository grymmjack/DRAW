#!/bin/bash
# QA/tests/tool-rect.sh
# Test: Rectangle Tool (outline and filled)
# Tests rectangle drawing, filled variant, and undo restoration.

# --- Setup: ensure rectangle tool and canvas focus ---
canvas_focus r
wait_for 0.3 "Rectangle tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap canvas center BEFORE outline rectangle ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "rect-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# --- Draw outline rectangle ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Outline rectangle drawn"
assert_no_crash

# --- Snap canvas center AFTER outline rectangle ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "rect-outline-after"
AFTER_OUTLINE="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER_OUTLINE" "Outline rectangle should be visible on canvas"

# --- Undo outline rectangle ---
key ctrl+z
wait_for 0.5 "Undo outline rectangle"
assert_no_crash

# --- Verify undo restored canvas ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "rect-outline-undo"
UNDO_OUTLINE="$SNAP_RESULT"
assert_regions_differ "$AFTER_OUTLINE" "$UNDO_OUTLINE" "Undo should change canvas from outline rect"

# --- Switch to filled rectangle (Shift+R) ---
key shift+r
wait_for 0.3 "Switch to filled rectangle"

# --- Snap canvas center BEFORE filled rectangle ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "rect-filled-before"
BEFORE_FILLED="$SNAP_RESULT"
assert_no_crash

# --- Draw filled rectangle ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Filled rectangle drawn"
assert_no_crash

# --- Snap canvas center AFTER filled rectangle ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "rect-filled-after"
AFTER_FILLED="$SNAP_RESULT"
assert_regions_differ "$BEFORE_FILLED" "$AFTER_FILLED" "Filled rectangle should be visible on canvas"

# --- Undo filled rectangle ---
key ctrl+z
wait_for 0.5 "Undo filled rectangle"
assert_no_crash

# --- Verify undo restored canvas ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "rect-filled-undo"
UNDO_FILLED="$SNAP_RESULT"
assert_regions_differ "$AFTER_FILLED" "$UNDO_FILLED" "Undo should change canvas from filled rect"

assert_window_exists
