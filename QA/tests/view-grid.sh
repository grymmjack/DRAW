#!/bin/bash
# =============================================================================
# view-grid.sh — QA test: Toggle grid overlay visibility
# Tests: g (toggle grid on/off)
# Verifies grid overlay appears and disappears on canvas
# =============================================================================

# -- Establish known state --
info "=== View Grid Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Snap canvas area before grid --
BEFORE_GRID=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "grid-before")
assert_no_crash

# -- Toggle grid ON: key g --
info "Toggle grid ON (g)"
key g
wait_for 0.3 "Grid toggled on"
assert_no_crash

# -- Snap after grid on --
GRID_ON=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "grid-on")
assert_regions_differ "$BEFORE_GRID" "$GRID_ON" "Grid overlay should be visible on canvas"
screenshot "grid-on"

# -- Toggle grid OFF: key g --
info "Toggle grid OFF (g)"
key g
wait_for 0.3 "Grid toggled off"
assert_no_crash

# -- Snap after grid off --
GRID_OFF=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "grid-off")
assert_regions_same "$BEFORE_GRID" "$GRID_OFF" "Grid should be gone after toggling off"
screenshot "grid-off"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== View Grid Test PASSED ==="
