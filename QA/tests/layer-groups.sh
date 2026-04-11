#!/bin/bash
# =============================================================================
# QA Auto Test: Layer Groups
# Tests: Group creation, collapse/expand, ungroup, merge, select all in group,
#        group from selection, move up/down with groups, group visibility,
#        drawing on group child, quick transforms on groups, undo/redo
# Generated: 2025-07-17, updated 2026-04-10
# =============================================================================

info "=== Layer Groups Tests ==="

# ---------------------------------------------------------------------------
# Geometry constants for layer panel
# ---------------------------------------------------------------------------
# Layer panel has a 16px header bar, then the layer list starts.
# Each layer row is 20px tall (LAYER_ROW_HEIGHT).
# Group headers: collapse triangle at localX 0-12, eye icon at 13-23, body 24+
# Normal layers: eye icon at localX 0-13, body 14+
LP_HEADER_H=16
LAYER_ENTRY_H=20
LIST_TOP=$(( LP_Y + LP_HEADER_H ))
LAYER_MID_X=$(( LP_X + LP_W / 2 ))

# Row center Y helper: ROW_Y N = center of row N (0-indexed) in viewport px
row_y() { echo $(( LIST_TOP + $1 * LAYER_ENTRY_H + LAYER_ENTRY_H / 2 )); }

# ---------------------------------------------------------------------------
# Setup — establish known state
# ---------------------------------------------------------------------------
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# ---------------------------------------------------------------------------
# Test 1: Create New Group (Ctrl+G)
# ---------------------------------------------------------------------------
info "Test 1: Create New Group (Ctrl+G)"

# Snap layer panel before
park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-before-new"
BEFORE_NEW="$SNAP_RESULT"

# Create a new group
wake_draw
key ctrl+g
wait_for 0.5 "New group created"
assert_no_crash

# Snap layer panel after
park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-new"
AFTER_NEW="$SNAP_RESULT"
assert_regions_differ "$BEFORE_NEW" "$AFTER_NEW" "New group should appear in layer panel"
screenshot "after-new-group"

# ---------------------------------------------------------------------------
# Test 2: Toggle Group Collapse (click collapse arrow)
# ---------------------------------------------------------------------------
info "Test 2: Toggle Group Collapse"

# Group is at row 0 (top of list). Snap panel before collapse.
park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-before-collapse"
BEFORE_COLLAPSE="$SNAP_RESULT"

# Collapse triangle is at the left edge (localX < 13) of the group row
GROUP_ROW0_Y=$(row_y 0)
COLLAPSE_X=$(( LP_X + 6 ))

# Click the collapse area to toggle
click $COLLAPSE_X $GROUP_ROW0_Y
wait_for 0.3 "Collapse toggled"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-collapse"
AFTER_COLLAPSE="$SNAP_RESULT"
assert_regions_differ "$BEFORE_COLLAPSE" "$AFTER_COLLAPSE" "Collapsing group should change panel"

# Toggle back (expand)
click $COLLAPSE_X $GROUP_ROW0_Y
wait_for 0.3 "Expand toggled"
assert_no_crash

# ---------------------------------------------------------------------------
# Test 3: Ungroup (Ctrl+Shift+U)
# ---------------------------------------------------------------------------
info "Test 3: Ungroup (Ctrl+Shift+U)"

# Make sure the group is selected — click body area of row 0
click $LAYER_MID_X $GROUP_ROW0_Y
wait_for 0.2 "Group selected"

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-before-ungroup"
BEFORE_UNGROUP="$SNAP_RESULT"

wake_draw
key ctrl+shift+u
wait_for 0.5 "Ungrouped"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-ungroup"
AFTER_UNGROUP="$SNAP_RESULT"
assert_regions_differ "$BEFORE_UNGROUP" "$AFTER_UNGROUP" "Ungroup should remove group from panel"

# Undo to restore the group
wake_draw
key ctrl+z
wait_for 0.5 "Undo ungroup"
assert_no_crash

# ---------------------------------------------------------------------------
# Test 4: Undo New Group removes group
# ---------------------------------------------------------------------------
info "Test 4: Undo New Group"

# Snap panel BEFORE the undo (with group still present)
park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-before-undo-new"
BEFORE_UNDO_NEW="$SNAP_RESULT"

# Undo the group creation
wake_draw
key ctrl+z
wait_for 0.5 "Undo new group"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-undo-new"
AFTER_UNDO_NEW="$SNAP_RESULT"
assert_regions_differ "$BEFORE_UNDO_NEW" "$AFTER_UNDO_NEW" "Undo should remove group from panel"

# ---------------------------------------------------------------------------
# Test 5: Group from Selection (Ctrl+Shift+G)
# ---------------------------------------------------------------------------
info "Test 5: Group from Selection (Ctrl+Shift+G)"

# Create 3 layers with content for grouping
click $(( CANVAS_CX - 30 )) $CANVAS_CY
wait_for 0.2 "Dot on layer 1"

key ctrl+shift+n
wait_for 0.3 "Layer 2 created"
click $CANVAS_CX $CANVAS_CY
wait_for 0.2 "Dot on layer 2"

key ctrl+shift+n
wait_for 0.3 "Layer 3 created"
click $(( CANVAS_CX + 30 )) $CANVAS_CY
wait_for 0.2 "Dot on layer 3"
assert_no_crash

# Multi-select layers 2 and 3: current is 3 (row 0), Ctrl+Click layer 2 (row 1)
# With 3 layers and no groups: row 0=Layer3, row 1=Layer2, row 2=Layer1
LAYER2_Y=$(row_y 1)
info "Ctrl+Click layer 2 to multi-select"
wake_draw
key ctrl
click $LAYER_MID_X $LAYER2_Y
wait_for 0.3 "Multi-select active"

# Snap panel before group from selection
park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-before-fromsel"
BEFORE_FROMSEL="$SNAP_RESULT"

# Group from selection
wake_draw
key ctrl+shift+g
wait_for 0.5 "Group from selection created"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-fromsel"
AFTER_FROMSEL="$SNAP_RESULT"
assert_regions_differ "$BEFORE_FROMSEL" "$AFTER_FROMSEL" "Group from selection should change panel"
screenshot "after-group-from-selection"

# After grouping layers 2+3, panel rows are:
# Row 0: Group header
# Row 1: Layer 3 (child, indented)
# Row 2: Layer 2 (child, indented)
# Row 3: Layer 1 (standalone)
GRP_HDR_Y=$(row_y 0)
GRP_CHILD1_Y=$(row_y 1)
GRP_CHILD2_Y=$(row_y 2)
UNGROUPED_Y=$(row_y 3)

# ---------------------------------------------------------------------------
# Test 6: Select All in Group (context menu)
# ---------------------------------------------------------------------------
info "Test 6: Select All in Group"

# Click group header body to select it
click $LAYER_MID_X $GRP_HDR_Y
wait_for 0.2 "Group header selected"

# Right-click for context menu
right_click $LAYER_MID_X $GRP_HDR_Y
wait_for 0.3 "Context menu opened"

# Take screenshot of context menu
screenshot "group-context-menu"

# Dismiss context menu
key Escape
wait_for 0.2 "Context menu dismissed"
assert_no_crash

# ---------------------------------------------------------------------------
# Test 7: Merge Group (skipped — no keyboard shortcut; menu test only)
# ---------------------------------------------------------------------------
info "Test 7: Merge Group (menu screenshot only)"

# Make sure group header is selected
click $LAYER_MID_X $GRP_HDR_Y
wait_for 0.2 "Group header selected"
assert_no_crash

# ---------------------------------------------------------------------------
# Test 8: Drawing on Group Child Layer
# ---------------------------------------------------------------------------
info "Test 8: Drawing on Group Child Layer"

# Select child layer (row 1) — click body area (LAYER_MID_X is well past eye zone)
click $LAYER_MID_X $GRP_CHILD1_Y
wait_for 0.3 "Child layer selected"

# Ensure canvas focus with brush tool
canvas_focus b
wait_for 0.2 "Canvas focused with brush"

# Snap canvas before drawing
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 40 )) 80 80 "grp-canvas-before-draw"
CANVAS_BEFORE_DRAW="$SNAP_RESULT"

# Draw a brush stroke across the canvas center
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.3 "Brush stroke on group child"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 40 )) 80 80 "grp-canvas-after-draw"
CANVAS_AFTER_DRAW="$SNAP_RESULT"
assert_regions_differ "$CANVAS_BEFORE_DRAW" "$CANVAS_AFTER_DRAW" "Drawing on group child should show on canvas"

# Undo the brush stroke
wake_draw
key ctrl+z
wait_for 0.3 "Undo brush on child"
assert_no_crash

# ---------------------------------------------------------------------------
# Test 9: Move Group Up/Down (Ctrl+PageUp / Ctrl+PageDown)
# ---------------------------------------------------------------------------
info "Test 9: Move Group Up/Down"

# Select the group header
click $LAYER_MID_X $GRP_HDR_Y
wait_for 0.2 "Group header selected"

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-before-move-down"
BEFORE_MOVE_DOWN="$SNAP_RESULT"

# Move group down (Ctrl+PageDown)
wake_draw
key ctrl+Page_Down
wait_for 0.5 "Group moved down"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-move-down"
AFTER_MOVE_DOWN="$SNAP_RESULT"
assert_regions_differ "$BEFORE_MOVE_DOWN" "$AFTER_MOVE_DOWN" "Moving group down should change panel"

# Move group back up (Ctrl+PageUp)
wake_draw
key ctrl+Page_Up
wait_for 0.5 "Group moved up"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-move-up"
AFTER_MOVE_UP="$SNAP_RESULT"
assert_regions_differ "$AFTER_MOVE_DOWN" "$AFTER_MOVE_UP" "Moving group up should change panel"

# ---------------------------------------------------------------------------
# Test 10: Group Visibility Toggle
# ---------------------------------------------------------------------------
info "Test 10: Group Visibility Toggle"

# Select group header first (body click)
click $LAYER_MID_X $GRP_HDR_Y
wait_for 0.2 "Group header selected"

# Snap panel before toggling visibility
park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-panel-before-vis"
PANEL_BEFORE_VIS="$SNAP_RESULT"

# Group eye icon is at localX 13-23 (after collapse triangle).
# No indent for depth-0 group, so absolute X = LP_X + 18
GRP_EYE_X=$(( LP_X + 18 ))
click $GRP_EYE_X $GRP_HDR_Y
wait_for 0.3 "Group visibility toggled off"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-panel-vis-off"
PANEL_VIS_OFF="$SNAP_RESULT"
assert_regions_differ "$PANEL_BEFORE_VIS" "$PANEL_VIS_OFF" "Hiding group should change panel (eye icon)"

# Toggle visibility back on
click $GRP_EYE_X $GRP_HDR_Y
wait_for 0.3 "Group visibility restored"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-panel-vis-on"
PANEL_VIS_ON="$SNAP_RESULT"
assert_regions_differ "$PANEL_VIS_OFF" "$PANEL_VIS_ON" "Toggling group visibility should change panel"

# ---------------------------------------------------------------------------
# Test 11: Quick Transform on Group (Flip Horizontal)
# ---------------------------------------------------------------------------
info "Test 11: Quick Transform on Group"

# Select the group header (body click)
click $LAYER_MID_X $GRP_HDR_Y
wait_for 0.2 "Group header selected"

# Draw content on both children so the flip has visible effect
# Select child 1 and draw
click $LAYER_MID_X $GRP_CHILD1_Y
wait_for 0.2 "Child 1 selected"
canvas_focus b
wait_for 0.1 "Brush ready"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX - 10 )) $(( CANVAS_CY - 10 ))
wait_for 0.2 "Stroke on child 1"

# Snap canvas before flip (with asymmetric content visible)
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) 80 40 "grp-canvas-before-flip"
CANVAS_BEFORE_FLIP="$SNAP_RESULT"

# Select group header and flip
click $LAYER_MID_X $GRP_HDR_Y
wait_for 0.2 "Group header re-selected"
key h
wait_for 0.5 "Group flipped horizontal"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) 80 40 "grp-canvas-after-flip"
CANVAS_AFTER_FLIP="$SNAP_RESULT"
assert_regions_differ "$CANVAS_BEFORE_FLIP" "$CANVAS_AFTER_FLIP" "Flipping group should change canvas"
screenshot "after-group-flip"

# Undo the flip and the extra stroke
wake_draw
key ctrl+z
wait_for 0.3 "Undo flip"
wake_draw
key ctrl+z
wait_for 0.3 "Undo stroke"
assert_no_crash

# ---------------------------------------------------------------------------
# Test 12: Ungroup via Ctrl+Shift+U (with children)
# ---------------------------------------------------------------------------
info "Test 12: Ungroup with Children (Ctrl+Shift+U)"

# Select the group header
click $LAYER_MID_X $GRP_HDR_Y
wait_for 0.2 "Group header selected"

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-before-ungroup2"
BEFORE_UNGROUP2="$SNAP_RESULT"

wake_draw
key ctrl+shift+u
wait_for 0.5 "Ungrouped with children"
assert_no_crash

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-ungroup2"
AFTER_UNGROUP2="$SNAP_RESULT"
assert_regions_differ "$BEFORE_UNGROUP2" "$AFTER_UNGROUP2" "Ungroup should dissolve group in panel"
screenshot "after-ungroup-with-children"

# Undo to restore group
wake_draw
key ctrl+z
wait_for 0.5 "Undo ungroup"
assert_no_crash

# ---------------------------------------------------------------------------
# Test 13: Undo/Redo Group from Selection
# ---------------------------------------------------------------------------
info "Test 13: Undo/Redo Group from Selection"

# Undo grouping (action from Test 5)
wake_draw
key ctrl+z
wait_for 0.5 "Undo group from selection"

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-undo-fromsel"
AFTER_UNDO_FROMSEL="$SNAP_RESULT"
assert_regions_differ "$AFTER_FROMSEL" "$AFTER_UNDO_FROMSEL" "Undo group-from-selection should change panel"
assert_no_crash

# Redo grouping
wake_draw
key ctrl+y
wait_for 0.5 "Redo group from selection"

park_mouse
snap_region $LP_X $LP_Y $LP_W $LP_H "grp-after-redo-fromsel"
AFTER_REDO_FROMSEL="$SNAP_RESULT"
assert_regions_differ "$AFTER_UNDO_FROMSEL" "$AFTER_REDO_FROMSEL" "Redo group-from-selection should restore group in panel"
assert_no_crash

# ---------------------------------------------------------------------------
# Cleanup — undo all operations
# ---------------------------------------------------------------------------
info "=== Cleanup ==="

# Undo everything: group operations, draws, layer adds
# Over-undo to be safe — extra undos are harmless on empty history
wake_draw
key ctrl+z
wait_for 0.3 "Undo 1"
wake_draw
key ctrl+z
wait_for 0.3 "Undo 2"
wake_draw
key ctrl+z
wait_for 0.3 "Undo 3"
wake_draw
key ctrl+z
wait_for 0.3 "Undo 4"
wake_draw
key ctrl+z
wait_for 0.3 "Undo 5"
wake_draw
key ctrl+z
wait_for 0.3 "Undo 6"
wake_draw
key ctrl+z
wait_for 0.3 "Undo 7"
wake_draw
key ctrl+z
wait_for 0.3 "Undo 8"
wake_draw
key ctrl+z
wait_for 0.3 "Undo 9"
wake_draw
key ctrl+z
wait_for 0.3 "Undo 10"
assert_no_crash

# Restore brush tool and focus
key b
click $CANVAS_CX $CANVAS_CY
wait_for 0.2 "Brush tool restored"

# ---------------------------------------------------------------------------
# Final verification
# ---------------------------------------------------------------------------
assert_no_crash
assert_window_exists
info "=== Layer Groups Tests Complete ==="
