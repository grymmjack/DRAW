#!/bin/bash
# =============================================================================
# util-grid-modes.sh — QA test: Grid mode cycling and canvas border
# Tests: Ctrl+' (cycle grid geometry), # (canvas border toggle)
# =============================================================================

info "=== Grid Modes Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Ensure grid is ON first --
info "Turning grid ON (apostrophe)"
key apostrophe
wait_for 0.3 "Grid toggled"

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "grid-mode-square"
SQUARE="$SNAP_RESULT"
assert_no_crash

# -- Cycle to Diagonal grid: Ctrl+' --
info "Cycling grid mode (Ctrl+apostrophe)"
key ctrl+apostrophe
wait_for 0.3 "Grid mode cycled"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "grid-mode-diagonal"
DIAGONAL="$SNAP_RESULT"
assert_regions_differ "$SQUARE" "$DIAGONAL" "Grid mode change should alter grid appearance"

# -- Cycle back to original (Diagonal→Isometric→Hex→Square) --
key ctrl+apostrophe
wait_for 0.2 "Isometric"
key ctrl+apostrophe
wait_for 0.2 "Hex"
key ctrl+apostrophe
wait_for 0.2 "Square again"
assert_no_crash

# -- Toggle grid OFF --
key apostrophe
wait_for 0.3 "Grid off"

# -- Test canvas border toggle: # --
info "Toggling canvas border (#)"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "border-before"
BORDER_BEFORE="$SNAP_RESULT"

key numbersign
wait_for 0.3 "Canvas border toggled"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "border-after"
BORDER_AFTER="$SNAP_RESULT"
assert_regions_differ "$BORDER_BEFORE" "$BORDER_AFTER" "Canvas border toggle should change appearance"

# -- Toggle border back --
key numbersign
wait_for 0.3 "Canvas border restored"
assert_no_crash

assert_window_exists
info "=== Grid Modes Test PASSED ==="
