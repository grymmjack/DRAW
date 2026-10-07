#!/bin/bash
# =============================================================================
# annotate-tools.sh — QA test: the Annotate tools on a fake capture (640x400
# fixture, fit 1:1, canvas origin at viewport 273,51 in the Annotate layout).
#   x + drag   Redact pixelates the box at once
#   n + click  Numbered callout; Ctrl+Z removes it again
#   a + drag   Arrow (line with an arrowhead)
#   Ctrl+S     quick-saves a PNG into CAPTURE_SAVE_DIR (no dialog)
#   h + drag   Highlighter (yellow brush on a Multiply layer)
#   Ctrl+Enter Done: back to the document and workspace from before
# QA-OPTIONS: WORKSPACE=default CAPTURE_BACKEND=COMMAND CAPTURE_COMMAND=QA/fixtures/fake-capture.sh CAPTURE_DELAY=0 CAPTURE_HIDE_DRAW=FALSE CAPTURE_WORKSPACE=annotate CAPTURE_SAVE_DIR=QA/results/annotate-shots
# =============================================================================

info "=== Annotate tools Test ==="
SHOTS="$DRAW_ROOT/QA/results/annotate-shots"
rm -rf "$SHOTS"
key Escape
park_mouse
wait_for 0.4 "settle"
snap_region 2 $(( MENU_BAR_H + 20 )) 60 220 "left-default"; L0="$SNAP_RESULT"

# A document of your own first: a brush stroke Done must bring back
slow_drag_pre() {
    mouse_down $1 $2; wait_for 0.25 "pressed"
    hover $(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 )); wait_for 0.2 "dragging"
    hover $3 $4; wait_for 0.25 "dragged"; mouse_up
}
canvas_focus b
wait_for 0.3 "brush"
slow_drag_pre $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 ))
park_mouse
wait_for 0.3 "stroke"
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 30 )) 100 60 "doc-before"; D0="$SNAP_RESULT"

key ctrl+shift+p
wait_for 1.5 "picker"
key space
wait_for 2.0 "capture document in Annotate"
park_mouse
wait_for 0.3 "settle"
OX=273; OY=51
cv() { echo $(( OX + $1 )) $(( OY + $2 )); }
# A drag spread over several frames: DRAW idles at 15 fps, and the harness's
# quick drag can land press + move in one frame (a zero-length line).
slow_drag() {
    mouse_down $1 $2
    wait_for 0.25 "pressed"
    hover $(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 ))
    wait_for 0.2 "dragging"
    hover $3 $4
    wait_for 0.25 "dragged"
    mouse_up
}

# --- Redact ---
snap_region $(( OX + 250 )) $(( OY + 100 )) 80 80 "redact-before"; R0="$SNAP_RESULT"
key x
wait_for 0.3 "redact armed"
slow_drag $(cv 250 100) $(cv 330 180)
wait_for 0.6 "pixelated"
park_mouse
snap_region $(( OX + 250 )) $(( OY + 100 )) 80 80 "redact-after"; R1="$SNAP_RESULT"
assert_regions_differ "$R0" "$R1" "Redact pixelated the dragged box"

# --- Numbered callout + undo ---
snap_region $(( OX + 430 )) $(( OY + 80 )) 40 40 "callout-before"; N0="$SNAP_RESULT"
key n
wait_for 0.3 "callout armed"
click $(cv 450 100)
wait_for 0.5 "callout placed"
park_mouse
snap_region $(( OX + 430 )) $(( OY + 80 )) 40 40 "callout-after"; N1="$SNAP_RESULT"
assert_regions_differ "$N0" "$N1" "a numbered callout was placed"
screenshot "annotate-callout"
key ctrl+z
wait_for 0.5 "undo"
park_mouse
snap_region $(( OX + 430 )) $(( OY + 80 )) 40 40 "callout-undone"; N2="$SNAP_RESULT"
assert_regions_same "$N0" "$N2" "Ctrl+Z removes the callout"

# --- Arrow ---
snap_region $(( OX + 260 )) $(( OY + 300 )) 60 50 "arrow-before"; A0="$SNAP_RESULT"
key a
wait_for 0.3 "arrow"
slow_drag $(cv 100 250) $(cv 300 330)
wait_for 0.5 "drawn"
park_mouse
snap_region $(( OX + 260 )) $(( OY + 300 )) 60 50 "arrow-after"; A1="$SNAP_RESULT"
assert_regions_differ "$A0" "$A1" "the arrow was drawn"

# --- Highlighter ---
snap_region $(( OX + 40 )) $(( OY + 250 )) 120 30 "hl-before"; H0="$SNAP_RESULT"
key h
wait_for 0.4 "highlighter"
slow_drag $(cv 40 265) $(cv 160 265)
wait_for 0.4 "highlighted"
park_mouse
snap_region $(( OX + 40 )) $(( OY + 250 )) 120 30 "hl-after"; H1="$SNAP_RESULT"
assert_regions_differ "$H0" "$H1" "the highlighter marked the picture"
screenshot "annotate-tools"

# --- Quick save + Done ---
key ctrl+s
wait_for 1.0 "quick save"
if ls "$SHOTS"/DRAW-*.png >/dev/null 2>&1; then
    pass "Ctrl+S quick-saved $(basename "$(ls "$SHOTS"/DRAW-*.png | head -1)")"
else
    fail "no quick-saved PNG in $SHOTS"
fi
key ctrl+Return
wait_for 1.5 "done"
park_mouse
wait_for 0.3 "settle"
snap_region 2 $(( MENU_BAR_H + 20 )) 60 220 "left-back"; L1="$SNAP_RESULT"
assert_regions_same "$L0" "$L1" "Ctrl+Enter went back to the Default workspace"
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 30 )) 100 60 "doc-after"; D1="$SNAP_RESULT"
assert_regions_same "$D0" "$D1" "Ctrl+Enter brought back the document you had before"

assert_no_crash
assert_window_exists
info "=== Annotate tools Test PASSED ==="
