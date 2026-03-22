#!/bin/bash
# QA/tests/tool-fill.sh
# Test: Fill (Flood Fill) Tool
# Tests flood fill on canvas after drawing a brush stroke, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Draw a small brush stroke to create a region to fill ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 10 ))
wait_for 0.5 "Brush stroke drawn as fill boundary"
assert_no_crash

# --- Switch to fill tool ---
key f
wait_for 0.3 "Switch to fill tool"

# --- Snap canvas center BEFORE fill ---
park_mouse
BEFORE_FILL=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "fill-before")
assert_no_crash

# --- Flood fill below the stroke ---
click $CANVAS_CX $(( CANVAS_CY + 10 ))
wait_for 0.5 "Flood fill applied"
assert_no_crash

# --- Snap canvas center AFTER fill ---
park_mouse
AFTER_FILL=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "fill-after")
assert_regions_differ "$BEFORE_FILL" "$AFTER_FILL" "Flood fill should change canvas pixels"

# --- Undo fill ---
key ctrl+z
wait_for 0.5 "Undo flood fill"
assert_no_crash

# --- Verify fill undo restored canvas ---
park_mouse
UNDO_FILL=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "fill-undo")
assert_regions_differ "$AFTER_FILL" "$UNDO_FILL" "Undo should change canvas back from fill"

# --- Undo brush stroke to fully clean up ---
key ctrl+z
wait_for 0.5 "Undo brush stroke"
assert_no_crash

assert_window_exists
