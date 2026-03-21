#!/bin/bash
# QA/tests/tool-dot.sh
# Test: Dot Tool
# Tests single dot placement, visibility, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
key b
wait_for 0.3 "Switch to brush tool first"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Switch to dot tool ---
key d
wait_for 0.3 "Switch to dot tool"

# --- Snap canvas center BEFORE dot ---
BEFORE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "dot-before")
assert_no_crash

# --- Place single dot at canvas center ---
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Dot placed"
assert_no_crash

# --- Snap canvas center AFTER dot ---
AFTER=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "dot-after")
assert_regions_differ "$BEFORE" "$AFTER" "Dot should be visible on canvas"

# --- Undo dot ---
key ctrl+z
wait_for 0.5 "Undo dot"
assert_no_crash

# --- Snap canvas center AFTER undo ---
UNDO=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "dot-undo")
assert_regions_same "$BEFORE" "$UNDO" "Undo should restore canvas to original state"

assert_window_exists
