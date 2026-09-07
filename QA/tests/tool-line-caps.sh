#!/bin/bash
# =============================================================================
# tool-line-caps.sh — QA test: line start/end caps during an active drag
# Tests: s (cycle start cap), e (cycle end cap) while the line is being dragged
#
# Regression guard: S and E are also the Smart-Shapes and Eraser tool hotkeys.
# Once they became dispatched=TRUE bindings in INPUT/INPUT.BM the dispatcher
# switched tools mid-drag instead of cycling caps. CTX_DRAWING_IN_PROGRESS now
# forbids both bindings while TOOL_LINE is dragging.
#
# Offscreen reliability: snap_region does _qa_focus + a 1s sleep that idles DRAW
# out and DROPS the held-drag state (LINE_TOOL.DRAGGING). Once the drag is lost,
# 's' is read as the Smart-Shapes tool switch and 'e' triggers the Eraser instead
# of cycling caps (KEYBOARD.BM only cycles caps / blocks the eraser-hold WHILE
# LINE_TOOL.DRAGGING). So this test takes NO snap_region during the drag: it keeps
# the drag alive with a continuous mouse jiggle through the s/e taps and the
# commit, and does every assertion afterwards from stable idle snaps.
# =============================================================================

info "=== Line Caps Test ==="

# -- Establish known state: line tool, fat brush so caps are visible --
canvas_focus l
wait_for 0.3 "Line tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Baselines (both at idle, so they are stable): the toolbar's active-tool
#    highlight, and the blank canvas. Every assertion below compares against these
#    idle snaps — the drag itself is never interrupted by a snap. --
park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H "linecaps-toolbar-before"
TOOLBAR_BEFORE="$SNAP_RESULT"
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "linecaps-canvas-blank"
CANVAS_BLANK="$SNAP_RESULT"
assert_no_crash

# -- Begin a drag and HOLD it (the harness `drag` helper releases, so the
#    press/move/release is done inline here) --
LX1=$(( CANVAS_CX - 40 )); LY1=$(( CANVAS_CY - 20 ))
LX2=$(( CANVAS_CX + 40 )); LY2=$(( CANVAS_CY + 20 ))
read -r AX1 AY1 <<< "$(_abs "$LX1" "$LY1")"
read -r AX2 AY2 <<< "$(_abs "$LX2" "$LY2")"

info "Press and hold at ($LX1,$LY1), drag to ($LX2,$LY2) without releasing"
draw_focus
xdotool mousemove "$AX1" "$AY1"; sleep 0.1
xdotool mousedown 1 mousemove $(( AX1 + 1 )) "$AY1"; sleep 0.05
xdotool mousemove "$AX2" "$AY2"; sleep 0.3
assert_no_crash

# -- Cycle both caps in ONE continuous active-drag phase, then commit — with NO
#    snap_region anywhere in the middle so the drag is never dropped. --
_jiggle() { local n=$1; for _j in $(seq 1 "$n"); do xdotool mousemove $(( AX2 - (_j % 2) * 4 )) "$AY2"; sleep 0.03; done; xdotool mousemove "$AX2" "$AY2"; }

info "Cycle start (s) + end (e) caps mid-drag (continuous jiggle, no snaps), then commit"
_jiggle 6
# Bracket each cap key INSIDE mouse movement within a single xdotool invocation so
# it can't land in a frame gap. move -> key -> move keeps the tap in an active frame.
xdotool mousemove $(( AX2 - 3 )) "$AY2" key s mousemove "$AX2" "$AY2" mousemove $(( AX2 - 2 )) "$AY2"
_jiggle 5
xdotool mousemove $(( AX2 - 3 )) "$AY2" key e mousemove "$AX2" "$AY2" mousemove $(( AX2 - 2 )) "$AY2"
_jiggle 5
assert_no_crash

# -- Commit the line (drag still alive) --
info "Release to commit the line"
xdotool mouseup 1; sleep 0.4
assert_no_crash

# -- Stable idle checks:
#    (1) The committed line (with caps) differs from the blank canvas → caps drew.
#    (2) The active tool is STILL LINE — if s or e had switched tools mid-drag,
#        that tool (Smart Shapes / Eraser) would be active now. --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "linecaps-committed"
COMMITTED="$SNAP_RESULT"
assert_regions_differ "$CANVAS_BLANK" "$COMMITTED" \
    "s/e mid-drag drew a line with caps on the canvas"
screenshot "line-with-caps"

park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H "linecaps-toolbar-after-commit"
TOOLBAR_AFTERCOMMIT="$SNAP_RESULT"
assert_regions_same "$TOOLBAR_BEFORE" "$TOOLBAR_AFTERCOMMIT" \
    "s/e mid-drag must NOT switch tools (still LINE after commit)" 200

# -- After release, s is an ordinary tool hotkey again (switches to Smart Shapes) --
info "Press s after release (should switch to Smart Shapes)"
wake_draw          # leave idle mode first — the prior snap's sleep drops us to idle, which eats the keypress
key s
wait_for 0.4 "Tool switched"
park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H "linecaps-toolbar-after"
TOOLBAR_AFTER="$SNAP_RESULT"
assert_regions_differ "$TOOLBAR_BEFORE" "$TOOLBAR_AFTER" \
    "s outside a drag should still switch tools"

assert_no_crash
assert_window_exists
info "=== Line Caps Test PASSED ==="
