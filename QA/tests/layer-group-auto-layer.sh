#!/bin/bash
# QA-OPTIONS: GROUP_DRAW_AUTO_LAYER=TRUE
# =============================================================================
# layer-group-auto-layer.sh — QA test: GROUP_DRAW_AUTO_LAYER
#
# With the setting on, drawing on a group header does NOT refuse. The guard in
# MOUSE_dispatch_tool_hold calls LAYERS_new_in_group%, which creates a blank
# layer as the top child of that group and selects it, then deliberately falls
# through so the SAME stroke lands on the new layer — the user should not have
# to click twice.
#
# The option is set for THIS test's launch via the `# QA-OPTIONS:` line above,
# which the harness turns into `--option GROUP_DRAW_AUTO_LAYER=TRUE` on DRAW's
# command line (overrides the .cfg). That replaces the old edit-cfg-then-quit-
# and-relaunch dance: a mid-test relaunch disturbed window/click targeting and
# the drawn strokes never reached the canvas. No config file is touched, so
# there is nothing to restore and no state leaks into later tests.
# =============================================================================

info "=== Group Auto-Add Layer Test ==="
assert_no_crash

CR_X=$(( CANVAS_CX - 50 ))
CR_Y=$(( CANVAS_CY - 50 ))

canvas_focus b
wait_for 0.4 "Brush tool ready"
key grave
wait_for 0.2 "Pointer arrow hidden"

# -- Two layers with content, then group them (the group becomes current) --
click $(( CANVAS_CX - 30 )) "$CANVAS_CY"
wait_for 0.3 "Dot on Background"
key ctrl+shift+n
wait_for 0.5 "Layer 2 created"
click $(( CANVAS_CX + 30 )) "$CANVAS_CY"
wait_for 0.3 "Dot on Layer 2"
key ctrl+shift+g
wait_for 0.8 "Grouped — the group is the current layer"
assert_no_crash

park_mouse
snap_region "$LP_X" "$LP_Y" "$LP_W" 110 "auto-panel-before"
PANEL_BEFORE="$SNAP_RESULT"
snap_region "$CR_X" "$CR_Y" 100 100 "auto-canvas-before"
CANVAS_BEFORE="$SNAP_RESULT"

# -- Draw on the group --
info "Drawing on the group header with auto-add enabled"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 10 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 ))
wait_for 1.0 "Stroke should have landed on a new layer"
assert_no_crash

# No dialog: auto-add makes the draw succeed, so a warning would be nagging about
# something that worked.
park_mouse
snap_region "$CR_X" "$CR_Y" 100 100 "auto-canvas-after"
assert_regions_differ "$CANVAS_BEFORE" "$SNAP_RESULT" \
    "With auto-add on, the stroke should paint (on the new layer) instead of being refused"
screenshot "group-auto-layer-drawn"

snap_region "$LP_X" "$LP_Y" "$LP_W" 110 "auto-panel-after"
assert_regions_differ "$PANEL_BEFORE" "$SNAP_RESULT" \
    "A new layer should appear inside the group"

# -- Undo puts the canvas back --
wake_draw
key ctrl+z
wait_for 0.8 "Stroke undone"
assert_no_crash

assert_window_exists
info "=== Group Auto-Add Layer Test PASSED ==="
