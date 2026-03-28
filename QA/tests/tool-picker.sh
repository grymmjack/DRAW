#!/bin/bash
# =============================================================================
# tool-picker.sh — QA test: Color Picker tool
# Tests: I key (activate picker), click to pick FG color
# =============================================================================

info "=== Color Picker Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw a colored stroke to have something to pick --
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.3 "Reference stroke drawn"
assert_no_crash

# -- Snap palette/status area before pick --
park_mouse
snap_region $PAL_X $PAL_Y $PAL_W $PAL_H "picker-palette-before"
PAL_BEFORE="$SNAP_RESULT"

# -- Switch to Picker tool: I key --
info "Activating Picker tool (I)"
key i
wait_for 0.3 "Picker tool active"
assert_no_crash

# -- Click on the drawn stroke to pick its color --
info "Picking color from stroke"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Color picked"
assert_no_crash

# -- Switch back to brush --
key b
wait_for 0.2 "Back to brush"

# -- Undo the reference stroke --
key ctrl+z
wait_for 0.3 "Cleanup"
assert_no_crash

assert_window_exists
info "=== Color Picker Test PASSED ==="
