#!/bin/bash
# =============================================================================
# workspace-switch-restore.sh — QA test: the workspace switcher (Ctrl+Shift+W,
# the command palette pre-filtered to "Workspace: ") switches Default ->
# Annotate (layer panel + advanced bar hidden, toolbox docked left) and back
# to Default, which restores the original layout exactly. Also checks the
# pinned config was not rewritten with the workspace's panel state.
# =============================================================================

info "=== Workspace switch + restore Test ==="
key Escape
park_mouse
wait_for 0.4 "settle"

LX=2; LY=$(( MENU_BAR_H + 20 ))
RX=$(( VIEWPORT_W - 70 )); RY=$(( MENU_BAR_H + 20 ))
snap_region $LX $LY 60 220 "left-default";  L0="$SNAP_RESULT"
snap_region $RX $RY 60 220 "right-default"; R0="$SNAP_RESULT"

switch_to() {
    key ctrl+shift+w
    wait_for 0.5 "switcher open"
    type_text "$1"
    wait_for 0.3 "filtered"
    key Return
    wait_for 1.0 "workspace applied"
    park_mouse
    wait_for 0.3 "settle"
}

switch_to ann
snap_region $LX $LY 60 220 "left-annotate";  L1="$SNAP_RESULT"
snap_region $RX $RY 60 220 "right-annotate"; R1="$SNAP_RESULT"
screenshot "workspace-switched-annotate"
assert_regions_differ "$L0" "$L1" "Annotate: left side changes (layers hidden, toolbox docked left)"
assert_regions_differ "$R0" "$R1" "Annotate: right side changes (toolbox + advanced bar moved/hidden)"

switch_to def
snap_region $LX $LY 60 220 "left-back";  L2="$SNAP_RESULT"
snap_region $RX $RY 60 220 "right-back"; R2="$SNAP_RESULT"
screenshot "workspace-switched-default"
assert_regions_same "$L0" "$L2" "back to Default: left side restored"
assert_regions_same "$R0" "$R2" "back to Default: right side restored"

if [[ -n "$DRAW_CFG" ]] && grep -q '^WORKSPACE=default' "$DRAW_CFG" \
   && grep -q '^LAYERS_PANEL_DOCK_EDGE=LEFT' "$DRAW_CFG" && grep -q '^TOOLBOX_DOCK_EDGE=RIGHT' "$DRAW_CFG"; then
    pass "config keeps the user's docks and remembers WORKSPACE=default"
else
    fail "config was changed by the workspace (or DRAW_CFG unset): $(grep -E '^(WORKSPACE|LAYERS_PANEL_DOCK_EDGE|TOOLBOX_DOCK_EDGE)=' "$DRAW_CFG" 2>/dev/null | tr '\n' ' ')"
fi

assert_no_crash
assert_window_exists
info "=== Workspace switch + restore Test PASSED ==="
