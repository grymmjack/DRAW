#!/bin/bash
# =============================================================================
# ui-menubar.sh — QA test: Open and close menu bar
# Tests: Alt tap (toggle FILE menu open), Escape (close menu)
# Verifies menu dropdown appears and closes without crash
# =============================================================================

# -- Establish known state --
info "=== UI Menubar Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Snap menubar + dropdown region before (include space for dropdown) --
BEFORE=$(snap_region 0 0 $VIEWPORT_W 120 "menubar-before")
assert_no_crash

# -- Open FILE menu: tap Alt (press + release) --
info "Open FILE menu (Alt tap)"
key Alt_L
wait_for 0.3 "Menu opened"
assert_no_crash

# -- Snap after menu open --
MENU_OPEN=$(snap_region 0 0 $VIEWPORT_W 120 "menubar-open")
assert_regions_differ "$BEFORE" "$MENU_OPEN" "FILE menu dropdown should be visible"
screenshot "menubar-open"

# -- Close menu: Escape --
info "Close menu (Escape)"
key Escape
wait_for 0.3 "Menu closed"
assert_no_crash

# -- Snap after menu close --
MENU_CLOSED=$(snap_region 0 0 $VIEWPORT_W 120 "menubar-closed")
assert_regions_differ "$MENU_OPEN" "$MENU_CLOSED" "Menu dropdown should disappear after Escape"
assert_regions_same "$BEFORE" "$MENU_CLOSED" "Menu close should restore original state"
screenshot "menubar-closed"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== UI Menubar Test PASSED ==="
