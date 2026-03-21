#!/bin/bash
# QA/tests/tool-eraser.sh
# Test: Eraser Tool
# Tests eraser removing drawn pixels, visibility change, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Draw a brush stroke to have something to erase ---
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.5 "Brush stroke drawn"
assert_no_crash

# --- Snap canvas center with the stroke visible (before erasing) ---
BEFORE_ERASE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "eraser-before")

# --- Switch to eraser tool ---
key e
wait_for 0.3 "Switch to eraser tool"

# --- Drag eraser over the brush stroke ---
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.5 "Eraser applied over brush stroke"
assert_no_crash

# --- Snap canvas center AFTER erasing ---
AFTER_ERASE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "eraser-after")
assert_regions_differ "$BEFORE_ERASE" "$AFTER_ERASE" "Eraser should change canvas pixels"

# --- Undo eraser stroke ---
key ctrl+z
wait_for 0.5 "Undo eraser stroke"
assert_no_crash

# --- Verify eraser undo restored to drawn state ---
UNDO_ERASE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "eraser-undo")
assert_regions_same "$BEFORE_ERASE" "$UNDO_ERASE" "Undo should restore canvas to state with brush stroke"

# --- Undo brush stroke to fully clean up ---
key ctrl+z
wait_for 0.5 "Undo brush stroke"
assert_no_crash

assert_window_exists
