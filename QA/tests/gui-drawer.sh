#!/bin/bash
# =============================================================================
# gui-drawer.sh — QA test: Drawer Panel (Brushes/Gradients/Patterns)
# Tests: F1/F2/F3 mode switching.
#
# Phase 6 fix (2026-05): old test used F6 to toggle drawer visibility, but
# F6 = Pixel Perfect toggle (action 8006). The drawer panel has no toggle
# hotkey — it is visible by default (DRAWER.BM:13). F1/F2/F3 cycle its
# mode (8001/8002/8003).
# =============================================================================

info "=== Drawer Panel Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap bottom area showing drawer (visible by default) --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 80 )) $VIEWPORT_W 80 "drawer-brush"
BRUSH_MODE="$SNAP_RESULT"
assert_no_crash

# -- Switch to Gradient mode (F2) --
info "Switch to gradient mode (F2)"
key F2
wait_for 0.3 "Gradient mode"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 80 )) $VIEWPORT_W 80 "drawer-gradient"
GRADIENT_MODE="$SNAP_RESULT"
assert_regions_differ "$BRUSH_MODE" "$GRADIENT_MODE" "Drawer should change to gradient mode"
screenshot "drawer-gradient"

# -- Switch to Pattern mode (F3) --
info "Switch to pattern mode (F3)"
key F3
wait_for 0.3 "Pattern mode"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 80 )) $VIEWPORT_W 80 "drawer-pattern"
PATTERN_MODE="$SNAP_RESULT"
assert_regions_differ "$GRADIENT_MODE" "$PATTERN_MODE" "Drawer should change to pattern mode"
screenshot "drawer-pattern"

# -- Switch back to Brush mode (F1) --
info "Switch to brush mode (F1)"
key F1
wait_for 0.3 "Brush mode"
assert_no_crash

park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H - PALETTE_H - 80 )) $VIEWPORT_W 80 "drawer-back-to-brush"
BACK_TO_BRUSH="$SNAP_RESULT"
assert_regions_differ "$PATTERN_MODE" "$BACK_TO_BRUSH" "Drawer should change back to brush mode"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Drawer Panel Test PASSED ==="
