#!/bin/bash
# =============================================================================
# ui-palette.sh — QA test: FG/BG color swap
# Tests: x (swap FG/BG colors), x (swap back)
# Verifies palette strip updates visually on color swap
# =============================================================================

# -- Establish known state --
info "=== UI Palette Test ==="
canvas_focus b
wait_for 0.3 "Canvas focused, brush tool"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap palette region before swap --
park_mouse
snap_region $PAL_X $PAL_Y $PAL_W $PAL_H "palette-before-swap"
BEFORE_SWAP="$SNAP_RESULT"
assert_no_crash

# -- Swap FG/BG colors: key x --
info "Swap FG/BG (x)"
key x
wait_for 0.3 "Colors swapped"
assert_no_crash

# -- Snap after swap --
park_mouse
snap_region $PAL_X $PAL_Y $PAL_W $PAL_H "palette-after-swap"
AFTER_SWAP="$SNAP_RESULT"
assert_regions_differ "$BEFORE_SWAP" "$AFTER_SWAP" "FG/BG swap should change palette display"
screenshot "palette-swapped"

# -- Swap back: key x --
info "Swap back (x)"
key x
wait_for 0.3 "Colors swapped back"
assert_no_crash

# -- Snap after swap back --
park_mouse
snap_region $PAL_X $PAL_Y $PAL_W $PAL_H "palette-after-swap-back"
AFTER_SWAP_BACK="$SNAP_RESULT"
assert_regions_same "$BEFORE_SWAP" "$AFTER_SWAP_BACK" "Swapping back should restore original colors"
screenshot "palette-restored"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== UI Palette Test PASSED ==="
