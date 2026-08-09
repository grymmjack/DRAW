#!/bin/bash
# =============================================================================
# layer-group-draw-guard.sh — QA test: drawing tools on a group header layer
#
# A group is a container: its imgHandle& is a 1x1 placeholder that only marks
# the slot as in use, so a stroke aimed at a group is written into a 1x1 buffer
# and vanishes. MOUSE_dispatch_tool_hold now intercepts that.
#
# Covers the DEFAULT configuration:
#   GROUP_DRAW_NOTIFY     = TRUE   warn and refuse
#   GROUP_DRAW_AUTO_LAYER = FALSE
# The auto-add path has its own file (layer-group-auto-layer.sh) because it
# needs a different config and therefore a different DRAW instance.
#
# Also covers the "not paintable" badge tooltip on the group row, and checks
# the guard is not over-broad: a layer INSIDE the group still paints normally.
#
# NOTE: this is the first coverage of the DRAW_alert guard family — the
# text-layer and symbol-child guards next to it in MOUSE_dispatch_tool_hold
# have never been exercised by the suite.
# =============================================================================

LP_HEADER_H=16
LAYER_ENTRY_H=20
LAYER_MID_X=$(( LP_X + LP_W / 2 ))
row_y() { echo $(( LP_Y + LP_HEADER_H + $1 * LAYER_ENTRY_H + LAYER_ENTRY_H / 2 )); }
CR_X=$(( CANVAS_CX - 50 ))
CR_Y=$(( CANVAS_CY - 50 ))

info "=== Group Draw Guard Test ==="
canvas_focus b
wait_for 0.4 "Brush tool ready"
key grave
wait_for 0.2 "Pointer arrow hidden"

# -- Two layers with content, then group them --
# Ctrl+Shift+G ends in LAYERS_select groupIdx%, so the GROUP is the current
# layer straight afterwards — exactly the state the guard is about, with no
# row-clicking needed to get there.
click $(( CANVAS_CX - 30 )) "$CANVAS_CY"
wait_for 0.3 "Dot on Background"
key ctrl+shift+n
wait_for 0.5 "Layer 2 created"
click $(( CANVAS_CX + 30 )) "$CANVAS_CY"
wait_for 0.3 "Dot on Layer 2"
key ctrl+shift+g
wait_for 0.8 "Grouped — the group is now the current layer"
assert_no_crash

# ---------------------------------------------------------------------------
# 1. The "not paintable" badge shows a tooltip
# ---------------------------------------------------------------------------
# Badge geometry from LAYER_PANEL_render: drawn at panelW-19-8 .. panelW-20 on
# the second text line of the group row (rowTop+11 .. rowTop+18). row_y returns
# rowTop+10, so the badge's vertical centre is row_y + 4.
info "Hovering the not-paintable badge"
BADGE_X=$(( LP_X + LP_W - 23 ))
BADGE_Y=$(( $(row_y 0) + 4 ))

park_mouse
wait_for 0.8 "Any previous tooltip expired"
snap_region "$LP_X" "$LP_Y" "$LP_W" 90 "guard-tip-off"
TIP_OFF="$SNAP_RESULT"

# Hover without clicking, and hold still past CFG.TOOLTIP_HOVER_DELAY_MS (500).
read -r BADGE_AX BADGE_AY <<< "$(_abs "$BADGE_X" "$BADGE_Y")"
draw_focus
xdotool mousemove "$BADGE_AX" "$BADGE_AY"
sleep 1.6
snap_region "$LP_X" "$LP_Y" "$LP_W" 90 "guard-tip-on"
assert_regions_differ "$TIP_OFF" "$SNAP_RESULT" \
    "Hovering the not-paintable badge should show a tooltip"
screenshot "group-nopaint-tooltip"

# ---------------------------------------------------------------------------
# 2. Drawing on the group warns, and paints nothing
# ---------------------------------------------------------------------------
info "Attempting to draw on the group header"
park_mouse
wait_for 0.8 "Tooltip gone"
snap_region "$CR_X" "$CR_Y" 100 100 "guard-canvas-before"
CANVAS_BEFORE="$SNAP_RESULT"
snap_region 0 0 "$VP_W" "$VP_H" "guard-view-before"
VIEW_BEFORE="$SNAP_RESULT"

drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 10 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 ))
wait_for 1.2 "Warning dialog should be up"
assert_no_crash

snap_region 0 0 "$VP_W" "$VP_H" "guard-view-warned"
assert_regions_differ "$VIEW_BEFORE" "$SNAP_RESULT" \
    "Drawing on a group should raise the 'Cannot Draw on a Group' warning"
screenshot "group-draw-warning"

# Dismiss it. The message box runs its own 60fps modal loop reading _KEYHIT, so
# a keypress here is reliable (unlike an idle main loop).
key Return
wait_for 1.2 "Warning dismissed"
assert_no_crash

park_mouse
snap_region 0 0 "$VP_W" "$VP_H" "guard-view-dismissed"
assert_regions_same "$VIEW_BEFORE" "$SNAP_RESULT" \
    "Dismissing the warning should restore the previous view"

snap_region "$CR_X" "$CR_Y" 100 100 "guard-canvas-after"
assert_regions_same "$CANVAS_BEFORE" "$SNAP_RESULT" \
    "Nothing should be painted when the target is a group"

# ---------------------------------------------------------------------------
# 3. The guard is not over-broad — a layer inside the group still paints
# ---------------------------------------------------------------------------
# Row 1 is the group's child (row 0 is the group header). Switch tools with
# `key b` rather than canvas_focus: canvas_focus clicks with the MOVE tool,
# which re-selects the group header and would undo this selection.
info "Painting on a layer inside the group"
click "$LAYER_MID_X" "$(row_y 1)"
wait_for 0.6 "Child layer selected"
key b
wait_for 0.4 "Brush tool"

park_mouse
snap_region "$CR_X" "$CR_Y" 100 100 "guard-child-before"
CHILD_BEFORE="$SNAP_RESULT"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 25 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 35 ))
wait_for 0.6 "Stroke on the child layer"
assert_no_crash

park_mouse
snap_region "$CR_X" "$CR_Y" 100 100 "guard-child-after"
assert_regions_differ "$CHILD_BEFORE" "$SNAP_RESULT" \
    "A layer inside the group should still paint normally"

assert_no_crash
assert_window_exists
info "=== Group Draw Guard Test PASSED ==="
