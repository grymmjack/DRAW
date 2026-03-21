#!/bin/bash
# =============================================================================
# ui-toolbar-toggle.sh — QA test: Toggle toolbar visibility with Tab
# Tests: Tab (hide toolbar), Tab (show toolbar)
# Verifies toolbar column disappears and reappears
# =============================================================================

# -- Toolbar region depends on dock side --
if [[ "$TOOLBOX_DOCK" == "LEFT" ]]; then
    TB_X=0
else
    TB_X=$(( VIEWPORT_W - TOOLBAR_W ))
fi
TB_Y=$MENU_BAR_H
TB_W=$TOOLBAR_W
TB_H=100

# -- Establish known state --
info "=== UI Toolbar Toggle Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Snap toolbar region before --
BEFORE=$(snap_region $TB_X $TB_Y $TB_W $TB_H "toolbar-before")
assert_no_crash

# -- Toggle toolbar OFF: Tab --
info "Hide toolbar (Tab)"
key Tab
wait_for 0.3 "Toolbar hidden"
assert_no_crash

# -- Snap after hide --
HIDDEN=$(snap_region $TB_X $TB_Y $TB_W $TB_H "toolbar-hidden")
assert_regions_differ "$BEFORE" "$HIDDEN" "Toolbar region should change when hidden"
screenshot "toolbar-hidden"

# -- Toggle toolbar ON: Tab --
info "Show toolbar (Tab)"
key Tab
wait_for 0.3 "Toolbar restored"
assert_no_crash

# -- Snap after restore --
RESTORED=$(snap_region $TB_X $TB_Y $TB_W $TB_H "toolbar-restored")
assert_regions_differ "$HIDDEN" "$RESTORED" "Toolbar region should change when restored"
screenshot "toolbar-restored"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== UI Toolbar Toggle Test PASSED ==="
