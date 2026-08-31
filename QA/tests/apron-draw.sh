#!/bin/bash
# Ad-hoc: verify a stroke STARTED on the apron (outside canvas) begins drawing when
# it crosses onto the canvas (Rick's "begin outside, start on a canvas edge").
info "=== Apron -> canvas draw ==="
canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5; do key bracketright; done
wait_for 0.2 "Brush enlarged"
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
key grave ; wait_for 0.2 "pointer hidden"

# Sample a strip just inside the LEFT canvas edge, where the stroke should begin.
GX=$(( CANVAS_OFFSET_X + 4 )); GY=$(( CANVAS_CY - 20 )); GW=60; GH=40
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "apron-before"; BEFORE="$SNAP_RESULT"

# Press on the apron 60px LEFT of the canvas edge, drag onto the canvas centre.
drag $(( CANVAS_OFFSET_X - 60 )) "$CANVAS_CY" "$CANVAS_CX" "$CANVAS_CY"
wait_for 0.3 "apron->canvas drag done"
key grave ; park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "apron-after"; AFTER="$SNAP_RESULT"
screenshot "apron-draw-after"

assert_regions_differ "$BEFORE" "$AFTER" "Stroke from apron must draw once it reaches the canvas"
assert_no_crash
assert_window_exists
info "=== done ==="
