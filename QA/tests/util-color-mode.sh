#!/bin/bash
# =============================================================================
# util-color-mode.sh — QA test: FG/BG Color Mode
# Tests: X to swap FG/BG, Ctrl+D to reset defaults, verify palette strip updates
# =============================================================================

info "=== Color Mode Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap status bar color area BEFORE swap --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) 80 $STATUS_H "color-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Swap FG/BG with X --
info "Swap FG/BG (X)"
key x
wait_for 0.3 "Colors swapped"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) 80 $STATUS_H "color-swapped"
SWAPPED="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$SWAPPED" "Swap should change status bar color indicators"
screenshot "color-swapped"

# -- Swap back with X --
info "Swap back (X)"
key x
wait_for 0.3 "Colors swapped back"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) 80 $STATUS_H "color-restored"
RESTORED="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$RESTORED" "Double swap should restore original"

# -- Reset to defaults with Ctrl+D --
info "Reset defaults (Ctrl+D)"
key ctrl+d
wait_for 0.3 "Colors reset"
assert_no_crash
screenshot "color-reset"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Color Mode Test PASSED ==="
