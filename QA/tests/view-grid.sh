#!/bin/bash
# =============================================================================
# view-grid.sh — QA test: Toggle grid overlay visibility
# Tests: g (toggle grid on/off)
# Verifies grid overlay appears and disappears on canvas
# =============================================================================

# -- Establish known state --
info "=== View Grid Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap canvas area before grid --
park_mouse
BEFORE_GRID=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "grid-before")
assert_no_crash

# -- Toggle grid ON: key g --
info "Toggle grid ON (g)"
key g
wait_for 0.3 "Grid toggled on"
assert_no_crash

# -- Snap after grid on --
park_mouse
GRID_ON=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "grid-on")
assert_regions_differ "$BEFORE_GRID" "$GRID_ON" "Grid overlay should be visible on canvas"
screenshot "grid-on"

# -- Toggle grid OFF: key g --
info "Toggle grid OFF (g)"
key g
wait_for 0.3 "Grid toggled off"
assert_no_crash

# -- Snap after grid off --
park_mouse
GRID_OFF=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "grid-off")
assert_regions_same "$BEFORE_GRID" "$GRID_OFF" "Grid should be gone after toggling off"
screenshot "grid-off"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== View Grid Test PASSED ==="
