#!/bin/bash
# =============================================================================
# transform-quick.sh — QA test: Quick transform keys (flip, rotate)
# Tests: H (flip H), > (rotate CW), < (rotate CCW)
# =============================================================================

info "=== Transform Quick Keys Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw an asymmetric shape to detect transforms --
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 15 ))
wait_for 0.3 "Top line"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.3 "Left edge (L-shape)"
assert_no_crash

# -- Snap before flip --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "xform-before"
BEFORE="$SNAP_RESULT"

# -- Flip horizontally: H --
info "Flip horizontal (H)"
key h
wait_for 0.5 "Flipped H"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "xform-after-fliph"
FLIP_H="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$FLIP_H" "Horizontal flip should change canvas"

# -- Flip back to original --
key h
wait_for 0.5 "Flipped H back"

# -- Rotate CW: > (shift+period) --
info "Rotate 90 CW (>)"
key shift+period
wait_for 0.5 "Rotated CW"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "xform-after-rotcw"
ROT_CW="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$ROT_CW" "Rotate CW should change canvas"

# -- Rotate CCW: < (shift+comma) --
info "Rotate 90 CCW (<)"
key shift+comma
wait_for 0.5 "Rotated CCW (back to original)"
assert_no_crash

# -- Undo all --
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Cleanup"
assert_no_crash

assert_window_exists
info "=== Transform Quick Keys Test PASSED ==="
