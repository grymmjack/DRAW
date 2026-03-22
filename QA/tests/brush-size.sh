#!/bin/bash
# QA/tests/brush-size.sh
# Test: Brush Size Increase/Decrease
# Tests ] to increase and [ to decrease brush size, verifying organizer widget changes.

# --- Setup: brush tool, canvas focus ---
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap organizer region BEFORE size change ---
# Organizer is in the toolbar column; brush size widget is at slot 2 (top-right area)
if [[ "$TOOLBOX_DOCK" == "RIGHT" ]]; then
    ORG_X=$(( VP_W - TOOLBOX_W + 2 ))
else
    ORG_X=2
fi
ORG_Y=$(( MENUBAR_H + TOOLBAR_H + 2 ))
ORG_W=$(( TOOLBOX_W - 4 ))
ORG_H=30

park_mouse
BEFORE=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bsize-before")
assert_no_crash

# --- Increase brush size 3 times ---
key bracketright
wait_for 0.2 "Size +1"
key bracketright
wait_for 0.2 "Size +2"
key bracketright
wait_for 0.2 "Size +3"

# --- Snap organizer AFTER increase ---
park_mouse
AFTER_INC=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bsize-after-inc")
assert_regions_differ "$BEFORE" "$AFTER_INC" "organizer changed after brush size increase"

# --- Decrease brush size 3 times to restore ---
key bracketleft
wait_for 0.2 "Size -1"
key bracketleft
wait_for 0.2 "Size -2"
key bracketleft
wait_for 0.2 "Size -3"

# --- Snap organizer AFTER decrease (should match original) ---
park_mouse
AFTER_DEC=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bsize-after-dec")
assert_regions_same "$BEFORE" "$AFTER_DEC" "organizer restored after brush size decrease"

assert_window_exists
