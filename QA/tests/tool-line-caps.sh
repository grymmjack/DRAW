#!/bin/bash
# =============================================================================
# tool-line-caps.sh — QA test: line start/end caps during an active drag
# Tests: s (cycle start cap), e (cycle end cap) while the line is being dragged
#
# Regression guard: S and E are also the Smart-Shapes and Eraser tool hotkeys.
# Once they became dispatched=TRUE bindings in INPUT/INPUT.BM the dispatcher
# switched tools mid-drag instead of cycling caps. CTX_DRAWING_IN_PROGRESS now
# forbids both bindings while TOOL_LINE is dragging.
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

# -- Baseline of the toolbar: the active-tool highlight must not move --
park_mouse
snap_region $TB_X $TB_Y $TB_W $TB_H "linecaps-toolbar-before"
TOOLBAR_BEFORE="$SNAP_RESULT"
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

# -- Snapshot the live line preview before touching any cap key --
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "linecaps-preview-nocaps"
PREVIEW_NOCAPS="$SNAP_RESULT"

# -- Press S mid-drag: should cycle the START cap, NOT switch to Smart Shapes.
#    Mid-drag key detection is idle-fragile offscreen: snap_region's focus+1s
#    sleep lets DRAW idle out, and an idle frame drops the cap key (or, if the
#    drag is not active, 's' is read as the Smart-Shapes tool switch). So HOLD the
#    key while jiggling the mouse (keeps the input loop in active frames), and
#    RETRY until the cap actually shows. The loop stops the instant the cap
#    registers, so it never over-cycles past the first cap style. --
info "Press s mid-drag (cycle start cap) — retry until it registers"
PREVIEW_STARTCAP="$PREVIEW_NOCAPS"
for _try in 1 2 3 4 5; do
    xdotool keydown s
    for _j in 1 2 3 4; do xdotool mousemove $(( AX2 - (_j % 2) * 3 )) "$AY2"; sleep 0.04; done
    xdotool mousemove "$AX2" "$AY2"
    xdotool keyup s; sleep 0.3
    snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "linecaps-preview-startcap"
    PREVIEW_STARTCAP="$SNAP_RESULT"
    _dc=$(_parse_ae "$(compare -metric AE -fuzz 2% "$PREVIEW_NOCAPS" "$PREVIEW_STARTCAP" /dev/null 2>&1 || true)")
    if [[ "${_dc:-0}" -gt 20 ]] 2>/dev/null; then info "start cap registered on try $_try (${_dc}px)"; break; fi
    info "start cap not visible yet (try $_try) — retrying"
done
assert_no_crash
assert_regions_differ "$PREVIEW_NOCAPS" "$PREVIEW_STARTCAP" \
    "s mid-drag should draw a start cap on the line preview"

# -- Press E mid-drag: should cycle the END cap, NOT switch to Eraser. Same
#    held-key + jiggle + retry technique as the 's' cap above. --
info "Press e mid-drag (cycle end cap) — retry until it registers"
PREVIEW_ENDCAP="$PREVIEW_STARTCAP"
for _try in 1 2 3 4 5; do
    xdotool keydown e
    for _j in 1 2 3 4; do xdotool mousemove $(( AX2 - (_j % 2) * 3 )) "$AY2"; sleep 0.04; done
    xdotool mousemove "$AX2" "$AY2"
    xdotool keyup e; sleep 0.3
    snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "linecaps-preview-endcap"
    PREVIEW_ENDCAP="$SNAP_RESULT"
    _dc=$(_parse_ae "$(compare -metric AE -fuzz 2% "$PREVIEW_STARTCAP" "$PREVIEW_ENDCAP" /dev/null 2>&1 || true)")
    if [[ "${_dc:-0}" -gt 20 ]] 2>/dev/null; then info "end cap registered on try $_try (${_dc}px)"; break; fi
    info "end cap not visible yet (try $_try) — retrying"
done
assert_no_crash
assert_regions_differ "$PREVIEW_STARTCAP" "$PREVIEW_ENDCAP" \
    "e mid-drag should draw an end cap on the line preview"

# -- The whole point of the fix: the active tool must still be LINE --
snap_region $TB_X $TB_Y $TB_W $TB_H "linecaps-toolbar-during"
TOOLBAR_DURING="$SNAP_RESULT"
assert_regions_same "$TOOLBAR_BEFORE" "$TOOLBAR_DURING" \
    "s/e mid-drag must NOT switch tools (toolbar selection unchanged)" 200

# -- Commit the line --
info "Release to commit the line"
xdotool mouseup 1; sleep 0.4
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "linecaps-committed"
COMMITTED="$SNAP_RESULT"
assert_regions_differ "$PREVIEW_NOCAPS" "$COMMITTED" \
    "Committed line with caps should be on the canvas"
screenshot "line-with-caps"

# -- After release, s/e are ordinary tool hotkeys again --
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
