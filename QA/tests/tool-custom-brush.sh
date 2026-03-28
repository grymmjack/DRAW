#!/bin/bash
# =============================================================================
# tool-custom-brush.sh — QA test: Custom Brush capture and manipulation
# Tests: Marquee+Ctrl+B (capture), stamp, Home (flip H), End (flip V), Ctrl+B (clear)
# =============================================================================

info "=== Custom Brush Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw something to capture as custom brush --
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 15 ))
wait_for 0.3 "Horizontal line drawn"
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX - 15 )) $(( CANVAS_CY + 15 ))
wait_for 0.3 "Vertical line drawn (L-shape)"
assert_no_crash

# -- Switch to Marquee tool and select the L-shape --
info "Selecting region with Marquee"
key m
wait_for 0.3 "Marquee tool active"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 ))
wait_for 0.5 "Marquee selection made"
assert_no_crash

# -- Capture as custom brush: Ctrl+B --
info "Capturing custom brush (Ctrl+B)"
key ctrl+b
wait_for 0.5 "Custom brush captured"
assert_no_crash

# -- Stamp brush at a new location --
park_mouse
snap_region $(( CANVAS_CX + 40 )) $(( CANVAS_CY - 30 )) 80 60 "cbr-before-stamp"
BEFORE_STAMP="$SNAP_RESULT"

info "Stamping custom brush"
click $(( CANVAS_CX + 60 )) $CANVAS_CY
wait_for 0.5 "Custom brush stamped"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX + 40 )) $(( CANVAS_CY - 30 )) 80 60 "cbr-after-stamp"
AFTER_STAMP="$SNAP_RESULT"
assert_regions_differ "$BEFORE_STAMP" "$AFTER_STAMP" "Custom brush stamp should be visible"

# -- Flip brush horizontally: Home --
info "Flipping brush horizontally (Home)"
key Home
wait_for 0.3 "Brush flipped H"
assert_no_crash

# -- Flip brush vertically: End --
info "Flipping brush vertically (End)"
key End
wait_for 0.3 "Brush flipped V"
assert_no_crash

# -- Clear custom brush: Ctrl+B again --
info "Clearing custom brush (Ctrl+B)"
key ctrl+b
wait_for 0.5 "Custom brush cleared"
assert_no_crash

# -- Undo all drawn content --
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Cleanup"
assert_no_crash

assert_window_exists
info "=== Custom Brush Test PASSED ==="
