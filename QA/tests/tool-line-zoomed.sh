#!/bin/bash
# =============================================================================
# tool-line-zoomed.sh — QA test: a line drawn while zoomed in lands where it was
# drawn. The line tool is allowed in the apron, and on a promoted layer canvas
# (x,y) is buffer (x+apronW, y+apronH); the commit wrote raw canvas coordinates,
# so a zoomed-in line landed in the canvas's top-left corner instead (Rick,
# 2026-10-10; gotcha #14).
# =============================================================================
info "=== Line tool zoomed in Test ==="
canvas_focus b
key grave; sleep 0.2
CORNER_X=$CANVAS_OFFSET_X; CORNER_Y=$CANVAS_OFFSET_Y
park_mouse
snap_region "$CORNER_X" "$CORNER_Y" 60 40 "corner-before"; CORNER0="$SNAP_RESULT"
snap_region $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 50 )) 140 100 "middle-before"; MIDDLE0="$SNAP_RESULT"

info "Zoom in (Ctrl+= x4), line tool, drag a line near the middle"
for n in 1 2 3 4; do key ctrl+equal; sleep 0.3; done
key l; sleep 0.3
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 40 )) $(( CANVAS_CX + 60 )) $(( CANVAS_CY + 60 )); sleep 0.5

info "Back to 100% (Ctrl+0)"
key ctrl+0; sleep 0.5
park_mouse
snap_region "$CORNER_X" "$CORNER_Y" 60 40 "corner-after"; CORNER1="$SNAP_RESULT"
snap_region $(( CANVAS_CX - 70 )) $(( CANVAS_CY - 50 )) 140 100 "middle-after"; MIDDLE1="$SNAP_RESULT"
assert_regions_differ "$MIDDLE0" "$MIDDLE1" "the zoomed-in line was drawn near the middle, where it was dragged"
assert_regions_same "$CORNER0" "$CORNER1" "nothing landed in the canvas's top-left corner"
screenshot "line-zoomed-result"
assert_no_crash
info "=== Line tool zoomed in Test PASSED ==="
