#!/bin/bash
# QA/tests/tool-fill.sh
# Test: Fill (Flood Fill) Tool
# Tests flood fill on canvas after drawing a brush stroke, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Draw a small brush stroke to create a region to fill ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 10 ))
wait_for 0.5 "Brush stroke drawn as fill boundary"
assert_no_crash

# --- Switch to fill tool ---
key f
wait_for 0.3 "Switch to fill tool"

# --- Snap canvas center BEFORE fill ---
BEFORE_FILL=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "fill-before")
assert_no_crash

# --- Flood fill below the stroke ---
click $CANVAS_CX $(( CANVAS_CY + 10 ))
wait_for 0.5 "Flood fill applied"
assert_no_crash

# --- Snap canvas center AFTER fill ---
AFTER_FILL=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "fill-after")
assert_regions_differ "$BEFORE_FILL" "$AFTER_FILL" "Flood fill should change canvas pixels"

# --- Undo fill ---
key ctrl+z
wait_for 0.5 "Undo flood fill"
assert_no_crash

# --- Verify fill undo restored canvas ---
UNDO_FILL=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "fill-undo")
assert_regions_same "$BEFORE_FILL" "$UNDO_FILL" "Undo should restore canvas after fill"

# --- Undo brush stroke to fully clean up ---
key ctrl+z
wait_for 0.5 "Undo brush stroke"
assert_no_crash

assert_window_exists
