#!/bin/bash
# QA/tests/tool-eraser.sh
# Test: Eraser Tool
# Tests eraser removing drawn pixels, visibility change, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Draw a brush stroke to have something to erase ---
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.5 "Brush stroke drawn"
assert_no_crash

# --- Snap canvas center with the stroke visible (before erasing) ---
park_mouse
BEFORE_ERASE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "eraser-before")

# --- Switch to eraser tool ---
key x
wait_for 0.3 "Switch to eraser tool"

# --- Drag eraser over the brush stroke ---
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.5 "Eraser applied over brush stroke"
assert_no_crash

# --- Snap canvas center AFTER erasing ---
park_mouse
AFTER_ERASE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "eraser-after")
assert_regions_differ "$BEFORE_ERASE" "$AFTER_ERASE" "Eraser should change canvas pixels"

# --- Undo eraser stroke ---
key ctrl+z
wait_for 0.5 "Undo eraser stroke"
assert_no_crash

# --- Verify eraser undo restored to drawn state ---
park_mouse
UNDO_ERASE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "eraser-undo")
assert_regions_differ "$AFTER_ERASE" "$UNDO_ERASE" "Undo should change canvas from erased state"

# --- Undo brush stroke to fully clean up ---
key ctrl+z
wait_for 0.5 "Undo brush stroke"
assert_no_crash

assert_window_exists
