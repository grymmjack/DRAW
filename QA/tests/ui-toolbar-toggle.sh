#!/bin/bash
# =============================================================================
# ui-toolbar-toggle.sh — QA test: Toggle toolbar visibility with Tab
# Tests: Tab (hide toolbar), Tab (show toolbar)
# Verifies toolbar column disappears and reappears
# =============================================================================

# TB_H: just the top portion we care about (not full toolbar height)
TB_H_SNAP=100

# -- Establish known state --
info "=== UI Toolbar Toggle Test ==="
canvas_focus b
wait_for 0.3 "Canvas focused, brush tool"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap toolbar region before --
park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H_SNAP "toolbar-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Toggle toolbar OFF: Tab --
info "Hide toolbar (Tab)"
key Tab
wait_for 0.5 "Toolbar hidden"
assert_no_crash

# -- Snap after hide --
park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H_SNAP "toolbar-hidden"
HIDDEN="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$HIDDEN" "Toolbar region should change when hidden"
screenshot "toolbar-hidden"

# -- Toggle toolbar ON: Tab --
info "Show toolbar (Tab)"
key Tab
wait_for 0.5 "Toolbar restored"
assert_no_crash

# -- Snap after restore --
park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H_SNAP "toolbar-restored"
RESTORED="$SNAP_RESULT"
assert_regions_differ "$HIDDEN" "$RESTORED" "Toolbar region should change when restored"
screenshot "toolbar-restored"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== UI Toolbar Toggle Test PASSED ==="
