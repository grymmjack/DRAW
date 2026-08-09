#!/bin/bash
# =============================================================================
# tool-switch-matrix.sh — QA test: every tool hotkey actually activates its tool
#
# tool-switching.sh presses all the tool letters and then asserts the CANVAS is
# unchanged. That is a useful safety check, but it passes just as happily when
# a hotkey does nothing at all — a dead binding is indistinguishable from a
# working one.
#
# This test closes that hole by reading the status bar, which renders the
# active tool's name (STATUS_render's SELECT CASE on CURRENT_TOOL%). For each
# letter: return to BRUSH, press the letter, and require the status bar to
# differ from the BRUSH baseline. Every tool below has a name distinct from
# "BRUSH", so a bar that still reads BRUSH means the key never took effect.
#
# Each letter is asserted independently against the same baseline, so one dead
# binding reports exactly which one it is instead of derailing the sequence.
#
# Excluded on purpose:
#   t  text tool   — modal; it takes over the keyboard (CTX_TEXT_ACTIVE) and
#                    would swallow the letters that follow
#   s  smart shape — double-tap cycling has its own timing test
#   o, w           — conditional bindings whose target depends on tool state
# =============================================================================

info "=== Tool Switch Matrix Test ==="
canvas_focus b
wait_for 0.4 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

SB_X=0
SB_Y=$(( VIEWPORT_H - STATUS_H ))
SB_W=$VIEWPORT_W
SB_H=$STATUS_H

park_mouse
snap_region "$SB_X" "$SB_Y" "$SB_W" "$SB_H" "matrix-brush-baseline"
BRUSH_BASELINE="$SNAP_RESULT"

# letter:expected tool name (name is for the failure message only)
TOOL_MATRIX="d:DOT l:LINE p:POLY-FILL r:RECT-FILL c:ELLIPSE-FILL q:BEZIER v:MOVE k:SPRAY z:ZOOM f:FILL i:PICKER m:MARQUEE"

for entry in $TOOL_MATRIX; do
    letter=${entry%%:*}
    toolname=${entry##*:}

    key "$letter"
    wait_for 0.4 "Switch to $toolname ($letter)"
    park_mouse
    snap_region "$SB_X" "$SB_Y" "$SB_W" "$SB_H" "matrix-tool-$letter"
    assert_regions_differ "$BRUSH_BASELINE" "$SNAP_RESULT" \
        "'$letter' should activate $toolname (status bar still reads BRUSH — binding dead?)"
    assert_no_crash

    # Back to brush for the next comparison. Marquee and move can leave overlay
    # state behind, so give the reset an extra beat.
    key b
    wait_for 0.35 "Back to brush"
done

# The baseline must still be reproducible at the end — proves the bar is
# genuinely tracking CURRENT_TOOL% rather than having drifted mid-run.
park_mouse
snap_region "$SB_X" "$SB_Y" "$SB_W" "$SB_H" "matrix-brush-final"
assert_regions_same "$BRUSH_BASELINE" "$SNAP_RESULT" \
    "Status bar should read BRUSH again after cycling every tool"

assert_no_crash
assert_window_exists
info "=== Tool Switch Matrix Test PASSED ==="
