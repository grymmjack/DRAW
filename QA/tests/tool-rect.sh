#!/bin/bash
# QA/tests/tool-rect.sh
# Test: Rectangle Tool (outline and filled)
# Tests rectangle drawing, filled variant, and undo restoration.

# --- Setup: ensure brush tool and canvas focus ---
key b
wait_for 0.3 "Switch to brush tool first"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Switch to rectangle tool ---
key r
wait_for 0.3 "Switch to rectangle tool"

# --- Snap canvas center BEFORE outline rectangle ---
BEFORE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "rect-before")
assert_no_crash

# --- Draw outline rectangle ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Outline rectangle drawn"
assert_no_crash

# --- Snap canvas center AFTER outline rectangle ---
AFTER_OUTLINE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "rect-outline-after")
assert_regions_differ "$BEFORE" "$AFTER_OUTLINE" "Outline rectangle should be visible on canvas"

# --- Undo outline rectangle ---
key ctrl+z
wait_for 0.5 "Undo outline rectangle"
assert_no_crash

# --- Verify undo restored canvas ---
UNDO_OUTLINE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "rect-outline-undo")
assert_regions_same "$BEFORE" "$UNDO_OUTLINE" "Undo should restore canvas after outline rect"

# --- Switch to filled rectangle (Shift+R) ---
key shift+r
wait_for 0.3 "Switch to filled rectangle"

# --- Snap canvas center BEFORE filled rectangle ---
BEFORE_FILLED=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "rect-filled-before")
assert_no_crash

# --- Draw filled rectangle ---
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.5 "Filled rectangle drawn"
assert_no_crash

# --- Snap canvas center AFTER filled rectangle ---
AFTER_FILLED=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "rect-filled-after")
assert_regions_differ "$BEFORE_FILLED" "$AFTER_FILLED" "Filled rectangle should be visible on canvas"

# --- Undo filled rectangle ---
key ctrl+z
wait_for 0.5 "Undo filled rectangle"
assert_no_crash

# --- Verify undo restored canvas ---
UNDO_FILLED=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "rect-filled-undo")
assert_regions_same "$BEFORE_FILLED" "$UNDO_FILLED" "Undo should restore canvas after filled rect"

assert_window_exists
