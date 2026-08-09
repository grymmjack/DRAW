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
# Snap the WHOLE toolbar column (toolbar + organizer), not a guessed sub-band.
# The brush-size widget's exact Y is theme/scale driven, and at SMALL sizes the
# only pixels that move are the top ~20px of the organizer. A tight band pinned
# to MENU_BAR_H+TOOLBAR_H sat entirely below them and reported "no effect" even
# though ']' worked fine. Nothing else in this column changes while the tool and
# colors are held constant, so the wider region is safe for both the differ and
# the restore-to-same assertion — and it survives future layout drift.
if [[ "$TOOLBOX_DOCK" == "RIGHT" ]]; then
    ORG_X=$(( VP_W - TOOLBAR_W + 2 ))
else
    ORG_X=2
fi
ORG_Y=$MENU_BAR_H
ORG_W=$(( TOOLBAR_W - 4 ))
ORG_H=$(( TOOLBAR_H + ORGANIZER_H ))

park_mouse
snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bsize-before"
BEFORE="$SNAP_RESULT"
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
snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bsize-after-inc"
AFTER_INC="$SNAP_RESULT"
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
snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "bsize-after-dec"
AFTER_DEC="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER_DEC" "organizer restored after brush size decrease"

assert_window_exists
