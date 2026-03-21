#!/bin/bash
# QA/tests/tool-ellipse.sh
# Test: Ellipse Tool (outline and filled)
# Tests ellipse drawing, filled variant, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
key b
wait_for 0.3 "Switch to brush tool first"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Switch to ellipse tool ---
key c
wait_for 0.3 "Switch to ellipse tool"

# --- Snap canvas center BEFORE outline ellipse ---
BEFORE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "ellipse-before")
assert_no_crash

# --- Draw outline ellipse ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Outline ellipse drawn"
assert_no_crash

# --- Snap canvas center AFTER outline ellipse ---
AFTER_OUTLINE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "ellipse-outline-after")
assert_regions_differ "$BEFORE" "$AFTER_OUTLINE" "Outline ellipse should be visible on canvas"

# --- Undo outline ellipse ---
key ctrl+z
wait_for 0.5 "Undo outline ellipse"
assert_no_crash

# --- Verify undo restored canvas ---
UNDO_OUTLINE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "ellipse-outline-undo")
assert_regions_same "$BEFORE" "$UNDO_OUTLINE" "Undo should restore canvas after outline ellipse"

# --- Switch to filled ellipse (Shift+C) ---
key shift+c
wait_for 0.3 "Switch to filled ellipse"

# --- Snap canvas center BEFORE filled ellipse ---
BEFORE_FILLED=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "ellipse-filled-before")
assert_no_crash

# --- Draw filled ellipse ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Filled ellipse drawn"
assert_no_crash

# --- Snap canvas center AFTER filled ellipse ---
AFTER_FILLED=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "ellipse-filled-after")
assert_regions_differ "$BEFORE_FILLED" "$AFTER_FILLED" "Filled ellipse should be visible on canvas"

# --- Undo filled ellipse ---
key ctrl+z
wait_for 0.5 "Undo filled ellipse"
assert_no_crash

# --- Verify undo restored canvas ---
UNDO_FILLED=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "ellipse-filled-undo")
assert_regions_same "$BEFORE_FILLED" "$UNDO_FILLED" "Undo should restore canvas after filled ellipse"

assert_window_exists
