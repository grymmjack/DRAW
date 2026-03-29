#!/bin/bash
# =============================================================================
# ui-menubar.sh — QA test: Open and close menu bar
# Tests: Alt tap (toggle FILE menu open), Escape (close menu)
# Verifies menu dropdown appears and closes without crash
# =============================================================================

# -- Establish known state --
info "=== UI Menubar Test ==="
canvas_focus b
wait_for 0.3 "Canvas focused, brush tool"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap menubar + dropdown region before --
park_mouse
snap_region $WORK_LEFT 0 300 150 "menubar-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Open FILE menu: click the FILE label --
# FILE label is at approximately WORK_LEFT + 4..21, Y = 0..12
# (menuBarLeftEdge = layer_panel_width when docked left, MENU_PAD_LEFT=4)
info "Open FILE menu (mouse click on label)"
click $(( WORK_LEFT + 12 )) 6
wait_for 0.5 "Menu opened"
assert_no_crash

# -- Snap after menu open (do NOT park_mouse — moving away from menu closes it) --
snap_region $WORK_LEFT 0 300 150 "menubar-open"
MENU_OPEN="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$MENU_OPEN" "FILE menu dropdown should be visible"
screenshot "menubar-open"

# -- Close menu: Escape --
info "Close menu (Escape)"
key Escape
wait_for 0.3 "Menu closed"
assert_no_crash

# -- Snap after menu close --
park_mouse
snap_region $WORK_LEFT 0 300 150 "menubar-closed"
MENU_CLOSED="$SNAP_RESULT"
assert_regions_differ "$MENU_OPEN" "$MENU_CLOSED" "Menu dropdown should disappear after Escape"
assert_regions_same "$BEFORE" "$MENU_CLOSED" "Menu close should restore original state"
screenshot "menubar-closed"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== UI Menubar Test PASSED ==="
