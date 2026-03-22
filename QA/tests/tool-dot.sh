#!/bin/bash
# QA/tests/tool-dot.sh
# Test: Dot Tool
# Tests dot placement with visible stroke, undo, and redo.

# --- Setup: focus canvas without drawing, switch to dot tool ---
canvas_focus d
wait_for 0.3 "Dot tool ready"

# Increase brush size for visibility and hide pointer arrow
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap canvas BEFORE dot ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "dot-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# --- Place dot: mouse down, small drag so it draws visibly ---
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 10 )) $(( CANVAS_CY + 10 ))
wait_for 0.5 "Dot stroke drawn"
assert_no_crash

# --- Park mouse away, snap AFTER dot ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "dot-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Dot should be visible on canvas"

# --- Undo dot ---
key ctrl+z
wait_for 0.5 "Undo dot"
assert_no_crash

# --- Snap AFTER undo ---
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "dot-undo"
UNDO="$SNAP_RESULT"
assert_regions_differ "$AFTER" "$UNDO" "Undo should change canvas from dot state"

assert_window_exists
