#!/bin/bash
# =============================================================================
# layer-groups-child.sh — QA test: selecting and painting a layer inside a group
#
# Split out of layer-groups.sh, where this ran after a dozen other sub-tests
# against one shared document and was really measuring accumulated state.
#
# Verified panel layout for the setup below (captured from a real run):
#   Row 0: Group 1 (1)   group header
#   Row 1: Layer 2       the group's child
#   Row 2: Background    outside the group
#
# Two things worth knowing about this setup:
#
#   * The group is created IN PLACE, so it is not necessarily row 0 in other
#     flows — do not copy these indices without re-checking.
#   * The harness has no true ctrl+click: `key ctrl` presses AND releases Ctrl,
#     so the click after it is a plain click that REPLACES the selection. That
#     is why Ctrl+Shift+G nests only the current layer here, giving a group
#     with exactly one child.
#
# Panel geometry: LAYER_PANEL_render sets panelY% = 0, the list starts below a
# 16px header, rows are 20px — so row N's centre is 26 + N*20. The eye zone is
# localX < 14, so click the row BODY at LP_X + LP_W/2 to select without
# toggling visibility.
# =============================================================================

LP_HEADER_H=16
LAYER_ENTRY_H=20
LAYER_MID_X=$(( LP_X + LP_W / 2 ))
row_y() { echo $(( LP_Y + LP_HEADER_H + $1 * LAYER_ENTRY_H + LAYER_ENTRY_H / 2 )); }

info "=== Layer Group Child Test ==="
canvas_focus b
wait_for 0.4 "Brush tool ready"
key grave
wait_for 0.2 "Pointer arrow hidden"

# -- Two layers, each with a dot --
click $(( CANVAS_CX - 30 )) "$CANVAS_CY"
wait_for 0.3 "Dot on Background"
key ctrl+shift+n
wait_for 0.5 "Layer 2 created"
click $(( CANVAS_CX + 30 )) "$CANVAS_CY"
wait_for 0.3 "Dot on Layer 2"
assert_no_crash

park_mouse
snap_region "$LP_X" "$LP_Y" "$LP_W" 90 "child-panel-flat"
FLAT_PANEL="$SNAP_RESULT"

# -- Group the current layer --
wake_draw
key ctrl+shift+g
wait_for 0.8 "Group created (and selected by LAYERS_group_from_selection%)"
assert_no_crash

park_mouse
snap_region "$LP_X" "$LP_Y" "$LP_W" 90 "child-panel-grouped"
GROUPED_PANEL="$SNAP_RESULT"
assert_regions_differ "$FLAT_PANEL" "$GROUPED_PANEL" "Ctrl+Shift+G should add a group row"
screenshot "group-child-panel"

# -- Selecting the CHILD must select the child, not its parent group --
# Photoshop behaviour: a plain click selects exactly the row clicked. If this
# ever regresses to selecting the parent, painting below turns into a silent
# no-op, because paint commands refuse to draw on a group.
click "$LAYER_MID_X" "$(row_y 1)"
wait_for 0.5 "Child layer selected"
assert_no_crash

park_mouse
snap_region "$LP_X" "$LP_Y" "$LP_W" 90 "child-panel-child-selected"
CHILD_SELECTED="$SNAP_RESULT"
assert_regions_differ "$GROUPED_PANEL" "$CHILD_SELECTED" \
    "Clicking the child row should move the selection off the group header"

# -- Painting on the child must reach the canvas --
# Deliberately NOT canvas_focus here. That helper switches to the Move tool and
# clicks the canvas, and Move is not selection-neutral once groups exist:
# MOVE_reset restores the selection to the group header via
# "LAYERS_select moveGroupOrigin%", and clicking with Move on a group header
# auto-selects its children for a linked move. Either one silently moves
# CURRENT_LAYER% off the child selected above, and painting on a group is a
# no-op — which is what made this look like a drawing bug.
key b
wait_for 0.4 "Brush tool"
park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 50 )) 100 100 "child-canvas-before"
BEFORE_DRAW="$SNAP_RESULT"

drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 ))
wait_for 0.5 "Stroke drawn on group child"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 50 )) 100 100 "child-canvas-after"
AFTER_DRAW="$SNAP_RESULT"
assert_regions_differ "$BEFORE_DRAW" "$AFTER_DRAW" \
    "Painting on a layer inside a group should show on the canvas"
screenshot "group-child-drawn"

# -- Undo restores the pre-stroke canvas --
wake_draw
key ctrl+z
wait_for 0.6 "Stroke undone"
park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 50 )) 100 100 "child-canvas-undo"
assert_regions_same "$BEFORE_DRAW" "$SNAP_RESULT" \
    "Undo should remove the stroke from the group child"

assert_no_crash
assert_window_exists
info "=== Layer Group Child Test PASSED ==="
