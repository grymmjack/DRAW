#!/bin/bash
# QA/tests/tool-line.sh
# Test: Line Tool
# Tests line drawing via two clicks, visibility, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
key b
wait_for 0.3 "Switch to brush tool first"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Switch to line tool ---
key l
wait_for 0.3 "Switch to line tool"

# --- Snap canvas center BEFORE line ---
BEFORE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "line-before")
assert_no_crash

# --- Draw line: click start point, then click end point ---
click $(( CANVAS_CX - 25 )) $(( CANVAS_CY - 15 ))
wait_for 0.3 "Line start point placed"
click $(( CANVAS_CX + 25 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Line end point placed"
assert_no_crash

# --- Snap canvas center AFTER line ---
AFTER=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "line-after")
assert_regions_differ "$BEFORE" "$AFTER" "Line should be visible on canvas"

# --- Undo line ---
key ctrl+z
wait_for 0.5 "Undo line"
assert_no_crash

# --- Snap canvas center AFTER undo ---
UNDO=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "line-undo")
assert_regions_same "$BEFORE" "$UNDO" "Undo should restore canvas to original state"

assert_window_exists
