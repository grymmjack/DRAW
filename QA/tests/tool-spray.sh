#!/bin/bash
# QA/tests/tool-spray.sh
# Test: Spray Tool
# Tests spray paint application via drag, visibility, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
key b
wait_for 0.3 "Switch to brush tool first"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Switch to spray tool ---
key k
wait_for 0.3 "Switch to spray tool"

# --- Snap canvas center BEFORE spray ---
BEFORE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "spray-before")
assert_no_crash

# --- Drag spray over a small area at canvas center ---
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 10 ))
wait_for 0.5 "Spray applied"
assert_no_crash

# --- Snap canvas center AFTER spray ---
AFTER=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "spray-after")
assert_regions_differ "$BEFORE" "$AFTER" "Spray should be visible on canvas"

# --- Undo spray ---
key ctrl+z
wait_for 0.5 "Undo spray"
assert_no_crash

# --- Snap canvas center AFTER undo ---
UNDO=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "spray-undo")
assert_regions_same "$BEFORE" "$UNDO" "Undo should restore canvas to original state"

assert_window_exists
