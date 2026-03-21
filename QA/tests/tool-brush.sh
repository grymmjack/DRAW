#!/bin/bash
# QA/tests/tool-brush.sh
# Test: Brush Tool
# Tests brush stroke drawing, visibility, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Snap canvas center BEFORE stroke ---
BEFORE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "brush-before")
assert_no_crash

# --- Draw horizontal brush stroke across canvas center ---
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.5 "Brush stroke drawn"
assert_no_crash

# --- Snap canvas center AFTER stroke ---
AFTER=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "brush-after")
assert_regions_differ "$BEFORE" "$AFTER" "Brush stroke should be visible on canvas"

# --- Undo stroke ---
key ctrl+z
wait_for 0.5 "Undo brush stroke"
assert_no_crash

# --- Snap canvas center AFTER undo ---
UNDO=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "brush-undo")
assert_regions_same "$BEFORE" "$UNDO" "Undo should restore canvas to original state"

assert_window_exists
