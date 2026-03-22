#!/bin/bash
# QA/tests/brush-shape.sh
# Test: Brush Shape Toggle
# Tests pipe (|) to cycle brush shape, verifying organizer widget changes.

# --- Setup: brush tool, canvas focus ---
canvas_focus b
wait_for 0.3 "Brush tool ready"

# Increase brush size for visibility and hide pointer arrow
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# --- Snap organizer region BEFORE shape toggle ---
if [[ "$TOOLBOX_DOCK" == "RIGHT" ]]; then
    ORG_X=$(( VP_W - TOOLBOX_W + 2 ))
else
    ORG_X=2
fi
ORG_Y=$(( MENUBAR_H + TOOLBAR_H + 2 ))
ORG_W=$(( TOOLBOX_W - 4 ))
ORG_H=30

park_mouse
BEFORE=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bshape-before")
assert_no_crash

# --- Toggle brush shape (pipe key = Shift+backslash) ---
key shift+backslash
wait_for 0.3 "Toggle brush shape"

# --- Snap organizer AFTER toggle ---
park_mouse
AFTER=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bshape-after")
assert_regions_differ "$BEFORE" "$AFTER" "organizer changed after brush shape toggle"

# --- Toggle back to restore ---
key shift+backslash
wait_for 0.3 "Toggle brush shape back"

assert_no_crash
assert_window_exists
