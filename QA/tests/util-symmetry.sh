#!/bin/bash
# =============================================================================
# util-symmetry.sh — QA test: Symmetry mode cycling and drawing
# Tests: F7 (cycle modes), draw with symmetry active, undo
# =============================================================================

info "=== Symmetry Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap canvas before symmetry --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "sym-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Enable vertical symmetry: F7 once --
info "Enabling vertical symmetry (F7)"
key F7
wait_for 0.3 "Symmetry mode: Vertical"
assert_no_crash

# -- Draw a stroke off-center; mirror should appear --
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX - 30 )) $(( CANVAS_CY + 10 ))
wait_for 0.5 "Symmetry stroke drawn"

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "sym-after-draw"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Symmetry stroke should be visible"

# -- Undo symmetry stroke --
key ctrl+z
wait_for 0.5 "Undo symmetry stroke"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "sym-after-undo"
UNDO="$SNAP_RESULT"
assert_regions_differ "$AFTER" "$UNDO" "Undo should remove symmetry stroke"

# -- Cycle through remaining modes: Cross, Asterisk, Off --
info "Cycling through remaining symmetry modes"
key F7
wait_for 0.2 "Symmetry mode: Cross"
key F7
wait_for 0.2 "Symmetry mode: Asterisk"
key F7
wait_for 0.2 "Symmetry mode: Off"
assert_no_crash

assert_window_exists
info "=== Symmetry Test PASSED ==="
