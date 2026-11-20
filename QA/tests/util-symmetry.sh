#!/bin/bash
# =============================================================================
# util-symmetry.sh — QA test: Symmetry mode cycling and drawing
# Tests: F7 (cycle modes), draw with symmetry active, undo, F8 clears symmetry
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
# the mirror side alone (right of the axis, clear of the guide): it must change when the
# stroke is drawn on the left - catches a mirror painted to the layer but never shown
park_mouse
snap_region $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 20 )) 30 40 "sym-mirror-before"
MBEFORE="$SNAP_RESULT"

# -- Draw a stroke off-center; mirror should appear --
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX - 30 )) $(( CANVAS_CY + 10 ))
wait_for 0.5 "Symmetry stroke drawn"

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "sym-after-draw"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Symmetry stroke should be visible"
snap_region $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 20 )) 30 40 "sym-mirror-after"
assert_regions_differ "$MBEFORE" "$SNAP_RESULT" "The mirrored stroke shows on the other side of the axis"

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
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "sym-asterisk"
AST="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AST" "Asterisk symmetry shows its guides"

# -- F8 with no custom brush / paint mode: Clear Symmetry (was dead after Fill Adjust took F8) --
key F8
wait_for 0.3 "Symmetry cleared"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "sym-cleared"
assert_regions_same "$BEFORE" "$SNAP_RESULT" "F8 clears symmetry (the guides go, the canvas is as it started)"
assert_no_crash

assert_window_exists
info "=== Symmetry Test PASSED ==="
