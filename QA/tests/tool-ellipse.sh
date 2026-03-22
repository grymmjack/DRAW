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
wait_for 0.2 "Brush size increased"

# --- Hide pointer arrow ---
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap canvas center BEFORE outline ellipse ---
park_mouse
BEFORE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "ellipse-before")
assert_no_crash

# --- Draw outline ellipse ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Outline ellipse drawn"
assert_no_crash

# --- Snap canvas center AFTER outline ellipse ---
park_mouse
AFTER_OUTLINE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "ellipse-outline-after")
assert_regions_differ "$BEFORE" "$AFTER_OUTLINE" "Outline ellipse should be visible on canvas"

# --- Undo outline ellipse ---
key ctrl+z
wait_for 0.5 "Undo outline ellipse"
assert_no_crash

# --- Verify undo restored canvas ---
park_mouse
UNDO_OUTLINE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "ellipse-outline-undo")
assert_regions_differ "$AFTER_OUTLINE" "$UNDO_OUTLINE" "Undo should change canvas from outline ellipse"

# --- Switch to filled ellipse (Shift+E) ---
key shift+e
wait_for 0.3 "Switch to filled ellipse"

# --- Snap canvas center BEFORE filled ellipse ---
park_mouse
BEFORE_FILLED=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "ellipse-filled-before")
assert_no_crash

# --- Draw filled ellipse ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Filled ellipse drawn"
assert_no_crash

# --- Snap canvas center AFTER filled ellipse ---
park_mouse
AFTER_FILLED=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "ellipse-filled-after")
assert_regions_differ "$BEFORE_FILLED" "$AFTER_FILLED" "Filled ellipse should be visible on canvas"

# --- Undo filled ellipse ---
key ctrl+z
wait_for 0.5 "Undo filled ellipse"
assert_no_crash

# --- Verify undo restored canvas ---
park_mouse
UNDO_FILLED=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "ellipse-filled-undo")
assert_regions_differ "$AFTER_FILLED" "$UNDO_FILLED" "Undo should change canvas from filled ellipse"

assert_window_exists
