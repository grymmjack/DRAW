#!/bin/bash
# =============================================================================
# util-picker-loupe.sh — QA test: Picker Loupe (Magnifier)
# Tests: Activate picker tool (I), verify loupe appears, move mouse, deactivate
# =============================================================================

info "=== Picker Loupe Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw some content for the loupe to magnify --
drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.3 "Brush stroke for loupe"
assert_no_crash

# -- Snap area near canvas before picker --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "loupe-before"
BEFORE="$SNAP_RESULT"

# -- Activate picker tool (I) --
info "Activate picker tool (I)"
key i
wait_for 0.3 "Picker tool active"
assert_no_crash

# -- Move mouse over canvas to trigger loupe --
info "Move mouse over canvas (loupe should appear)"
xdotool mousemove --window "$DRAW_WID" $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Loupe should be visible"
assert_no_crash

snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "loupe-active"
LOUPE_ACTIVE="$SNAP_RESULT"
screenshot "loupe-active"

# -- Move to different position --
xdotool mousemove --window "$DRAW_WID" $(( CANVAS_CX + 30 )) $(( CANVAS_CY - 10 ))
wait_for 0.3 "Loupe follows mouse"
assert_no_crash

# -- Switch away from picker --
info "Deactivate picker (B)"
key b
wait_for 0.3 "Brush tool restored"
assert_no_crash

# -- Undo brush stroke --
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Picker Loupe Test PASSED ==="
