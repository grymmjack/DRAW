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

# -- Select All and capture as custom brush --
# XTEST drag doesn't reliably create marquee selections on XWayland,
# so use Ctrl+A (Select All) which directly sets MARQUEE.ACTIVE/USER_CREATED.
info "Selecting entire canvas with Ctrl+A"
key Escape
wait_for 0.2 "Clear any active state"
wake_draw
key ctrl+a
wait_for 0.5 "Select All applied"
assert_no_crash

# -- Capture as custom brush: Ctrl+B --
# Ctrl+B captures from marquee and auto-switches to brush tool
info "Capturing custom brush (Ctrl+B)"
wake_draw
key ctrl+b
wait_for 1.0 "Custom brush captured and brush tool activated"
assert_no_crash

# -- Stamp brush at a new location --
# First snap the work area before stamping
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "cbr-before-stamp"
BEFORE_STAMP="$SNAP_RESULT"

# Stamp by clicking on canvas (brush tool with custom brush active)
info "Stamping custom brush"
local stamp_x stamp_y
stamp_x=$(( CANVAS_CX + 40 ))
stamp_y=$(( CANVAS_CY ))
# Use drag (press+move+release) instead of click for more reliable stamp
wake_draw
drag $stamp_x $stamp_y $(( stamp_x + 2 )) $stamp_y
wait_for 1.0 "Custom brush stamped"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "cbr-after-stamp"
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
wake_draw
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
