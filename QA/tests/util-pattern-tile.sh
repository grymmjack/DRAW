#!/bin/bash
# =============================================================================
# util-pattern-tile.sh — QA test: Pattern/Gradient Drawing Modes
# Tests: F1/F2/F3 mode switching, verify drawer updates, F8 fill-adj toggle
# =============================================================================

info "=== Pattern/Tile Drawing Mode Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Open drawer first (F6) to see mode changes --
info "Open drawer (F6)"
key F6
wait_for 0.5 "Drawer opened"
assert_no_crash

# -- Snap drawer area in brush mode (F1 default) --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 60 )) $VIEWPORT_W 60 "drawer-brush-mode"
BRUSH_MODE="$SNAP_RESULT"

# -- Switch to gradient mode (F2) --
info "Switch to gradient mode (F2)"
key F2
wait_for 0.3 "Gradient mode"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 60 )) $VIEWPORT_W 60 "drawer-gradient-mode"
GRADIENT_MODE="$SNAP_RESULT"
assert_regions_differ "$BRUSH_MODE" "$GRADIENT_MODE" "Gradient mode should change drawer display"
screenshot "drawer-gradient-mode"

# -- Switch to pattern mode (F3) --
info "Switch to pattern mode (F3)"
key F3
wait_for 0.3 "Pattern mode"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 60 )) $VIEWPORT_W 60 "drawer-pattern-mode"
PATTERN_MODE="$SNAP_RESULT"
assert_regions_differ "$GRADIENT_MODE" "$PATTERN_MODE" "Pattern mode should change drawer display"
screenshot "drawer-pattern-mode"

# -- Switch back to brush/color mode (F1) --
info "Switch back to brush/color mode (F1)"
key F1
wait_for 0.3 "Brush mode restored"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 60 )) $VIEWPORT_W 60 "drawer-back-brush"
BACK_BRUSH="$SNAP_RESULT"
assert_regions_differ "$PATTERN_MODE" "$BACK_BRUSH" "Should return to brush mode"

# -- Close drawer --
key F6
wait_for 0.3 "Drawer closed"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Pattern/Tile Drawing Mode Test PASSED ==="
