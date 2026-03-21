#!/bin/bash
# QA/tests/paint-opacity.sh
# Test: Paint Opacity
# Tests number keys 1-0 for opacity presets, draws strokes at different opacities.

# --- Setup: brush tool, canvas focus ---
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Snap canvas BEFORE any strokes ---
BEFORE=$(snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 30 )) 100 60 "opacity-before")
assert_no_crash

# --- Set opacity to 50% (key 5) and draw a stroke ---
key 5
wait_for 0.2 "Set 50% opacity"
drag $((CANVAS_CX - 30)) $CANVAS_CY $((CANVAS_CX - 10)) $CANVAS_CY
wait_for 0.3 "Draw 50% stroke"

AFTER_50=$(snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 30 )) 100 60 "opacity-50pct")
assert_regions_differ "$BEFORE" "$AFTER_50" "canvas changed after 50% opacity stroke"

# --- Set opacity to 100% (key 0) and draw another stroke ---
key 0
wait_for 0.2 "Set 100% opacity"
drag $((CANVAS_CX + 10)) $CANVAS_CY $((CANVAS_CX + 30)) $CANVAS_CY
wait_for 0.3 "Draw 100% stroke"

AFTER_100=$(snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 30 )) 100 60 "opacity-100pct")
assert_regions_differ "$AFTER_50" "$AFTER_100" "canvas changed after 100% opacity stroke"
assert_no_crash

# --- Undo both strokes ---
key ctrl+z
wait_for 0.3 "Undo stroke 2"
key ctrl+z
wait_for 0.3 "Undo stroke 1"

AFTER_UNDO=$(snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 30 )) 100 60 "opacity-undone")
assert_regions_same "$BEFORE" "$AFTER_UNDO" "canvas restored after undoing both strokes"

# --- Restore 100% opacity ---
key 0
wait_for 0.2 "Restore 100% opacity"

assert_window_exists
