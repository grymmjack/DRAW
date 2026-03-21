#!/bin/bash
# =============================================================================
# ui-palette.sh — QA test: FG/BG color swap
# Tests: x (swap FG/BG colors), x (swap back)
# Verifies palette strip updates visually on color swap
# =============================================================================

# -- Palette + status bar region at bottom of viewport --
PAL_X=0
PAL_Y=$(( VIEWPORT_H - STATUS_H - PALETTE_H ))
PAL_W=$VIEWPORT_W
PAL_H=$(( STATUS_H + PALETTE_H ))

# -- Establish known state --
info "=== UI Palette Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Snap palette region before swap --
BEFORE_SWAP=$(snap_region $PAL_X $PAL_Y $PAL_W $PAL_H "palette-before-swap")
assert_no_crash

# -- Swap FG/BG colors: key x --
info "Swap FG/BG (x)"
key x
wait_for 0.2 "Colors swapped"
assert_no_crash

# -- Snap after swap --
AFTER_SWAP=$(snap_region $PAL_X $PAL_Y $PAL_W $PAL_H "palette-after-swap")
assert_regions_differ "$BEFORE_SWAP" "$AFTER_SWAP" "FG/BG swap should change palette display"
screenshot "palette-swapped"

# -- Swap back: key x --
info "Swap back (x)"
key x
wait_for 0.2 "Colors swapped back"
assert_no_crash

# -- Snap after swap back --
AFTER_SWAP_BACK=$(snap_region $PAL_X $PAL_Y $PAL_W $PAL_H "palette-after-swap-back")
assert_regions_same "$BEFORE_SWAP" "$AFTER_SWAP_BACK" "Swapping back should restore original colors"
screenshot "palette-restored"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== UI Palette Test PASSED ==="
