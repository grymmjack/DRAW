#!/bin/bash
# QA/tests/brush-shape.sh
# Test: Brush Shape Toggle
# Tests backslash (\) to cycle brush shape, verifying organizer widget changes.

# --- Setup: brush tool, canvas focus ---
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# --- Snap organizer region BEFORE shape toggle ---
if [[ "$TOOLBOX_DOCK" == "RIGHT" ]]; then
    ORG_X=$(( VP_W - TOOLBOX_W + 2 ))
else
    ORG_X=2
fi
ORG_Y=$(( MENUBAR_H + TOOLBAR_H + 2 ))
ORG_W=$(( TOOLBOX_W - 4 ))
ORG_H=30

BEFORE=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bshape-before")
assert_no_crash

# --- Toggle brush shape (backslash key) ---
key backslash
wait_for 0.3 "Toggle brush shape"

# --- Snap organizer AFTER toggle ---
AFTER=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bshape-after")
assert_regions_differ "$BEFORE" "$AFTER" "organizer changed after brush shape toggle"

# --- Toggle back to restore ---
key backslash
wait_for 0.3 "Toggle brush shape back"

RESTORED=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bshape-restored")
# Note: may not be identical due to shape cycling (3 shapes), but we verified change happened

assert_window_exists
