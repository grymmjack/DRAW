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
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap canvas center BEFORE spray ---
park_mouse
BEFORE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "spray-before")
assert_no_crash

# --- Drag spray over a small area at canvas center ---
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 10 ))
wait_for 0.5 "Spray applied"
assert_no_crash

# --- Snap canvas center AFTER spray ---
park_mouse
AFTER=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "spray-after")
assert_regions_differ "$BEFORE" "$AFTER" "Spray should be visible on canvas"

# --- Undo spray ---
key ctrl+z
wait_for 0.5 "Undo spray"
assert_no_crash

# --- Snap canvas center AFTER undo ---
park_mouse
UNDO=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "spray-undo")
assert_regions_differ "$AFTER" "$UNDO" "Undo should change canvas from spray state"

assert_window_exists
