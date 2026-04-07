#!/bin/bash
# =============================================================================
# gui-drawer.sh — QA test: Drawer Panel (Brushes/Gradients/Patterns)
# Tests: Toggle visibility (F6), slot selection, mode switching (F1/F2/F3)
# =============================================================================

info "=== Drawer Panel Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap bottom area BEFORE opening drawer --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 80 )) $VIEWPORT_W 80 "drawer-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Open drawer with F6 --
info "Open drawer (F6)"
key F6
wait_for 0.5 "Drawer opened"
assert_no_crash

# -- Snap after opening --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 80 )) $VIEWPORT_W 80 "drawer-open"
DRAWER_OPEN="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$DRAWER_OPEN" "Drawer panel should appear"
screenshot "drawer-open"

# -- Switch to Gradient mode (F2) --
info "Switch to gradient mode (F2)"
key F2
wait_for 0.3 "Gradient mode"
assert_no_crash
screenshot "drawer-gradient"

# -- Switch to Pattern mode (F3) --
info "Switch to pattern mode (F3)"
key F3
wait_for 0.3 "Pattern mode"
assert_no_crash
screenshot "drawer-pattern"

# -- Switch back to Brush mode (F1) --
info "Switch to brush mode (F1)"
key F1
wait_for 0.3 "Brush mode"
assert_no_crash

# -- Close drawer with F6 --
info "Close drawer (F6)"
key F6
wait_for 0.3 "Drawer closed"
assert_no_crash

# -- Verify closed --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 80 )) $VIEWPORT_W 80 "drawer-closed"
DRAWER_CLOSED="$SNAP_RESULT"
assert_regions_differ "$DRAWER_OPEN" "$DRAWER_CLOSED" "Drawer panel should disappear"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Drawer Panel Test PASSED ==="
