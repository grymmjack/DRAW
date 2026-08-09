#!/bin/bash
# =============================================================================
# layer-group-auto-layer.sh — QA test: GROUP_DRAW_AUTO_LAYER
#
# With the setting on, drawing on a group header does NOT refuse. The guard in
# MOUSE_dispatch_tool_hold calls LAYERS_new_in_group%, which creates a blank
# layer as the top child of that group and selects it, then deliberately falls
# through so the SAME stroke lands on the new layer — the user should not have
# to click twice.
#
# Needs its own file because it needs its own config, and the harness gives one
# DRAW instance per file. The test edits QA/DRAW.qa.cfg, relaunches, and
# restores the original at the end — the harness shares this shell with every
# later test, so leaving the config modified would change the whole suite.
#
# CONFIG parsing is a flat "SELECT CASE UCASE$(configKey$)" with no section
# tracking, so appending the key at the end of the file is enough.
# =============================================================================

info "=== Group Auto-Add Layer Test ==="

QA_CFG_BACKUP="${QA_CFG}.autolayer-bak"
cp "$QA_CFG" "$QA_CFG_BACKUP" || { fail "could not back up $QA_CFG"; return 0 2>/dev/null; }

# Turn the setting on and restart DRAW so CONFIG_load picks it up.
printf '\nGROUP_DRAW_AUTO_LAYER=TRUE\n' >> "$QA_CFG"
info "Relaunching with GROUP_DRAW_AUTO_LAYER=TRUE"
draw_quit
draw_launch 15
wait_for 1.0 "DRAW up with auto-add enabled"
assert_no_crash

LP_HEADER_H=16
LAYER_ENTRY_H=20
row_y() { echo $(( LP_Y + LP_HEADER_H + $1 * LAYER_ENTRY_H + LAYER_ENTRY_H / 2 )); }
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
snap_region 0 0 "$VP_W" "$VP_H" "auto-view-before"
VIEW_BEFORE="$SNAP_RESULT"

# -- Draw on the group --
info "Drawing on the group header with auto-add enabled"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 10 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 ))
wait_for 1.0 "Stroke should have landed on a new layer"
assert_no_crash

# No dialog: auto-add makes the draw succeed, so warning would be nagging about
# something that worked.
park_mouse
snap_region 0 0 "$VP_W" "$VP_H" "auto-view-after"
VIEW_AFTER="$SNAP_RESULT"

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

# ---------------------------------------------------------------------------
# Restore — the harness shares this shell, so the config and a running DRAW
# instance must both be handed back in their original state.
# ---------------------------------------------------------------------------
info "Restoring the original QA config"
draw_quit
mv "$QA_CFG_BACKUP" "$QA_CFG"
draw_launch 15
wait_for 0.8 "Default instance restored"

if grep -q '^GROUP_DRAW_AUTO_LAYER=TRUE' "$QA_CFG"; then
    fail "QA config still has GROUP_DRAW_AUTO_LAYER=TRUE — later tests would inherit it"
else
    pass "QA config restored"
fi

assert_no_crash
assert_window_exists
info "=== Group Auto-Add Layer Test PASSED ==="
