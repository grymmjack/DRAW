#!/bin/bash
# QA/tests/tool-line.sh
# Test: Line Tool
# Tests line drawing via drag, visibility, and undo restoration.

# --- Setup: focus canvas and switch to line tool ---
canvas_focus l
wait_for 0.3 "Line tool ready"

# --- Increase brush size for visibility ---
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"

# --- Hide pointer arrow ---
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap canvas center BEFORE line ---
park_mouse
BEFORE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "line-before")
assert_no_crash

# --- Draw line via drag ---
drag $(( CANVAS_CX - 25 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 25 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Line drawn"
assert_no_crash

# --- Snap canvas center AFTER line ---
park_mouse
AFTER=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "line-after")
assert_regions_differ "$BEFORE" "$AFTER" "Line should be visible on canvas"

# --- Undo line ---
key ctrl+z
wait_for 0.5 "Undo line"
assert_no_crash

# --- Snap canvas center AFTER undo ---
park_mouse
UNDO=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "line-undo")
assert_regions_differ "$AFTER" "$UNDO" "Undo should change canvas from line state"

assert_window_exists
