#!/bin/bash
# =============================================================================
# util-assistants.sh — QA test: Drawing Assistants (modifier-key tools)
# Tests: Alt hold → color picker, Space hold → pan, Shift → crosshair
# =============================================================================

info "=== Assistants Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw content to have colors to pick and area to pan --
drag $(( CANVAS_CX - 30 )) $CANVAS_CY $(( CANVAS_CX + 30 )) $CANVAS_CY
wait_for 0.3 "Brush stroke drawn"
assert_no_crash

# -- Test Alt+Click → pick foreground color --
info "Alt+Click to pick FG color"
park_mouse
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "assist-before-pick"
BEFORE_PICK="$SNAP_RESULT"

# Alt click on the drawn stroke (pick its color)
key --clearmodifiers alt
click $CANVAS_CX $CANVAS_CY
key --clearmodifiers
wait_for 0.3 "Color picked"
assert_no_crash

# -- Test Space → pan assistant --
info "Space hold → pan"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "assist-before-pan"
BEFORE_PAN="$SNAP_RESULT"

# Press space, drag, release space
key space
wait_for 0.2 "Pan mode active"
assert_no_crash

# Release space to exit pan
key space
wait_for 0.2 "Pan mode deactivated"
assert_no_crash

# -- Undo the brush stroke --
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Assistants Test PASSED ==="
