#!/bin/bash
# QA/tests/tool-switching.sh
# Test: Tool Switching
# Cycles through all tool hotkeys and verifies no crash + canvas unaffected.

# --- Setup: brush tool, canvas focus ---
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Snap canvas BEFORE cycling ---
BEFORE=$(snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 40 )) 80 80 "switch-before")
assert_no_crash

# --- Cycle through all tool hotkeys ---
TOOLS="b d l r c f k e m w p"
for t in $TOOLS; do
    key "$t"
    wait_for 0.15 "Switch to tool $t"
done
assert_no_crash "after cycling all tools"

# --- Also test Shift variants ---
key "shift+r"
wait_for 0.15 "Filled rect"
key "shift+c"
wait_for 0.15 "Filled ellipse"
assert_no_crash "after shift variants"

# --- Snap canvas AFTER cycling ---
AFTER=$(snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 40 )) 80 80 "switch-after")

# Canvas should be unchanged — no tool drew anything
assert_regions_same "$BEFORE" "$AFTER" "canvas unchanged after tool cycling"

# --- Restore brush tool ---
key b
wait_for 0.2 "Restore brush"

assert_window_exists
