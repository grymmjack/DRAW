#!/bin/bash
# QA/tests/tool-brush.sh
# Test: Brush Tool
# Tests brush stroke drawing, visibility, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap canvas center BEFORE stroke ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "brush-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# --- Draw horizontal brush stroke across canvas center ---
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.5 "Brush stroke drawn"
assert_no_crash

# --- Snap canvas center AFTER stroke ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "brush-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Brush stroke should be visible on canvas"

# --- Undo stroke ---
key ctrl+z
wait_for 0.5 "Undo brush stroke"
assert_no_crash

# --- Snap canvas center AFTER undo ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "brush-undo"
UNDO="$SNAP_RESULT"
assert_regions_differ "$AFTER" "$UNDO" "Undo should change canvas from brush stroke state"

assert_window_exists
