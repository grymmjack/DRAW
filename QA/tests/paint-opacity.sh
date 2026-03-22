#!/bin/bash
# QA/tests/paint-opacity.sh
# Test: Paint Opacity
# Tests number keys 1-0 for opacity presets, draws strokes at different opacities.

# --- Setup: brush tool, canvas focus ---
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap canvas BEFORE any strokes ---
park_mouse
BEFORE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "opacity-before")
assert_no_crash

# --- Set opacity to 50% (key 5) and draw a stroke ---
key 5
wait_for 0.2 "Set 50% opacity"
drag $((CANVAS_CX - 30)) $CANVAS_CY $((CANVAS_CX - 10)) $CANVAS_CY
wait_for 0.3 "Draw 50% stroke"

park_mouse
AFTER_50=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "opacity-50pct")
assert_regions_differ "$BEFORE" "$AFTER_50" "canvas changed after 50% opacity stroke"

# --- Set opacity to 100% (key 0) and draw another stroke ---
key 0
wait_for 0.2 "Set 100% opacity"
drag $((CANVAS_CX + 10)) $CANVAS_CY $((CANVAS_CX + 30)) $CANVAS_CY
wait_for 0.3 "Draw 100% stroke"

park_mouse
AFTER_100=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "opacity-100pct")
assert_regions_differ "$AFTER_50" "$AFTER_100" "canvas changed after 100% opacity stroke"
assert_no_crash

# --- Undo both strokes ---
key ctrl+z
wait_for 0.3 "Undo stroke 2"
key ctrl+z
wait_for 0.3 "Undo stroke 1"

park_mouse
AFTER_UNDO=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "opacity-undone")
assert_regions_differ "$AFTER_100" "$AFTER_UNDO" "canvas should change after undoing strokes"

# --- Restore 100% opacity ---
key 0
wait_for 0.2 "Restore 100% opacity"

assert_window_exists
