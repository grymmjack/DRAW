#!/bin/bash
# =============================================================================
# view-pan.sh — QA test: Pan canvas with middle-click drag
# Tests: Middle-click drag to pan, Ctrl+0 to reset view
# Verifies panning shifts the canvas and reset restores it
# =============================================================================

# -- Establish known state --
info "=== View Pan Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap work area before pan --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "pan-before"
BEFORE_PAN="$SNAP_RESULT"
assert_no_crash

# -- Pan canvas: middle-click drag (button 2) --
# Stepped by hand rather than via drag(), which jumps straight from press to
# release with one intermediate move. Panning accumulates per-frame mouse
# deltas, so a single jump can be consumed in one frame — or land while DRAW is
# idling and be missed entirely. That made this assertion fail roughly one run
# in three. Eight small moves give the pan handler continuous motion to follow.
info "Panning canvas with middle-click drag"
read -r PAN_AX1 PAN_AY1 <<< "$(_abs "$CANVAS_CX" "$CANVAS_CY")"
read -r PAN_AX2 PAN_AY2 <<< "$(_abs "$(( CANVAS_CX + 40 ))" "$(( CANVAS_CY + 30 ))")"
draw_focus
xdotool mousemove "$PAN_AX1" "$PAN_AY1"
sleep 0.15
xdotool mousedown 2
sleep 0.1
for step in 1 2 3 4 5 6 7 8; do
    xdotool mousemove \
        $(( PAN_AX1 + (PAN_AX2 - PAN_AX1) * step / 8 )) \
        $(( PAN_AY1 + (PAN_AY2 - PAN_AY1) * step / 8 ))
    sleep 0.05
done
sleep 0.2
xdotool mouseup 2
wait_for 0.4 "Pan applied"
assert_no_crash

# -- Snap after pan --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "pan-after"
AFTER_PAN="$SNAP_RESULT"
assert_regions_differ "$BEFORE_PAN" "$AFTER_PAN" "Panning should shift the canvas view"
screenshot "pan-after"

# -- Reset view: Ctrl+0 --
info "Reset view (Ctrl+0)"
key ctrl+0
wait_for 0.3 "View reset"
assert_no_crash

# -- Snap after reset --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "pan-reset"
AFTER_RESET="$SNAP_RESULT"
assert_regions_same "$BEFORE_PAN" "$AFTER_RESET" "View reset should restore original pan position"
screenshot "pan-reset"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== View Pan Test PASSED ==="
