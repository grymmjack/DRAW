#!/bin/bash
# =============================================================================
# view-grid.sh — QA test: Toggle grid overlay visibility
# Tests: g (toggle grid on/off)
# Verifies grid overlay appears and disappears on canvas
# =============================================================================

# -- Establish known state --
info "=== View Grid Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Increase grid size for better visibility --
info "Increasing grid size"
key period
key period
key period
key period
key period
wait_for 0.3 "Grid size increased"

# -- Snap work area before grid --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-before"
BEFORE_GRID="$SNAP_RESULT"
assert_no_crash

# -- Toggle grid ON: apostrophe key (_KEYDOWN(39)) --
info "Toggle grid ON (apostrophe)"
key apostrophe
wait_for 0.5 "Grid toggled on"
assert_no_crash

# -- Snap after grid on --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-on"
GRID_ON="$SNAP_RESULT"
assert_regions_differ "$BEFORE_GRID" "$GRID_ON" "Grid overlay should be visible on canvas"
screenshot "grid-on"

# -- Toggle grid OFF: apostrophe key --
info "Toggle grid OFF (apostrophe)"
key apostrophe
wait_for 0.5 "Grid toggled off"
assert_no_crash

# -- Snap after grid off --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-off"
GRID_OFF="$SNAP_RESULT"
assert_regions_same "$BEFORE_GRID" "$GRID_OFF" "Grid should be gone after toggling off"
screenshot "grid-off"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== View Grid Test PASSED ==="
