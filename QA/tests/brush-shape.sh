#!/bin/bash
# QA/tests/brush-shape.sh
# Test: Brush Shape Toggle
# Verify that pipe key (|) cycles brush shape without crashing.
# Visual comparison is unreliable at small sizes so we just test the toggle works.

# --- Setup: brush tool, canvas focus ---
canvas_focus b
wait_for 0.3 "Brush tool ready"

# Increase brush size and hide pointer arrow
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Toggle brush shape multiple times ---
info "Cycling brush shape"
key shift+backslash
wait_for 0.2 "Shape toggled 1"
assert_no_crash

key shift+backslash
wait_for 0.2 "Shape toggled 2"
assert_no_crash

key shift+backslash
wait_for 0.2 "Shape toggled 3 (back to original)"
assert_no_crash

# --- Draw a stroke to confirm tool still works ---
info "Drawing brush stroke after shape cycling"
drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.3 "Stroke drawn"
screenshot "brush-shape-after-toggle"

# --- Cleanup ---
key ctrl+z
wait_for 0.2 "Undo stroke"

assert_no_crash
assert_window_exists
