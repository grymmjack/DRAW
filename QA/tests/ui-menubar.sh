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
snap_region 100 0 200 150 "menubar-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Open FILE menu: tap Alt (press + release) --
info "Open FILE menu (Alt tap)"
key --clearmodifiers Alt_L
wait_for 0.5 "Menu opened"
assert_no_crash

# -- Snap after menu open --
park_mouse
snap_region 100 0 200 150 "menubar-open"
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
snap_region 100 0 200 150 "menubar-closed"
MENU_CLOSED="$SNAP_RESULT"
assert_regions_differ "$MENU_OPEN" "$MENU_CLOSED" "Menu dropdown should disappear after Escape"
assert_regions_same "$BEFORE" "$MENU_CLOSED" "Menu close should restore original state"
screenshot "menubar-closed"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== UI Menubar Test PASSED ==="
