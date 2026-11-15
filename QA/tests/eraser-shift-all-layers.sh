#!/bin/bash
# =============================================================================
# eraser-shift-all-layers.sh — QA test: Eraser + Shift erases on every layer
# under the brush (BUGS.md 2026-11-15: "HOLD SHIFT is not erasing on all layers").
#
# Fixture: a 320x200 PNG, solid red. Ctrl+Shift+D duplicates it, so two red
# layers cover the middle. A Shift+drag with the Eraser must clear BOTH: the
# swath shows the transparency checkerboard (grays) - any red left means a layer
# was skipped.
#   1. the top layer moved past the right edge first: it is apron-promoted
#      (its buffer is bigger than the canvas), and the "is there paint under the
#      brush" scan read raw canvas coords there (gotcha #14)
#   2. a new layer with a thin white line, crossed by one fast stroke: the scan
#      looked only at each frame's end point, so the line's layer was skipped
#      and the line stood (fails on the old build)
# =============================================================================
info "=== Eraser: Shift erases all layers ==="
ES_DIR="$(mktemp -d /tmp/draw-qa-eraser-XXXXXX)"
magick -size 320x200 xc:'#c00000' "PNG32:$ES_DIR/red.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$ES_DIR/red.png"
draw_launch 15; wait_for 1.5 "red image loaded"
assert_no_crash

CX=$CANVAS_CX; CY=$CANVAS_CY
red_left() { # PNG -> max saturation (the checkerboard is gray, the red is 1.0)
    magick "$1" -colorspace HSL -channel G -separate -format '%[fx:maxima]' info: 2>/dev/null
}
shift_erase() { # Y
    key e; wait_for 0.3 "eraser"
    driver_input_key_hold down shift; sleep 0.2
    drag $(( CX - 50 )) "$1" $(( CX + 50 )) "$1"
    driver_input_key_hold up shift; sleep 0.3
    park_mouse; wait_for 0.5 "erased"
}

key ctrl+shift+d; wait_for 0.6 "duplicate layer"
key e; wait_for 0.3 "eraser"
for i in 1 2 3 4 5 6; do key bracketright; sleep 0.05; done

# -- 1. the top layer apron-promoted --
key ctrl+a; wait_for 0.5 "select all"
key v; wait_for 0.3 "move"
drag $CX $(( CY + 30 )) $(( CX + 40 )) $(( CY + 30 )); wait_for 0.5 "moved past the edge"
key b; wait_for 0.3 "commit"; key ctrl+d; wait_for 0.3 "deselect"
shift_erase $(( CY + 30 ))
snap_region $(( CX - 10 )) $(( CY + 29 )) 50 2 "eraser-apron"
S=$(red_left "$SNAP_RESULT"); info "max saturation in swath 1: $S"
awk -v s="$S" 'BEGIN{exit !(s < 0.2)}' && pass "apron-promoted layer: Shift+erase cleared both" || fail "apron layer: red left in the swath (saturation $S)"

# -- 2. a thin line crossed in one frame: the stroke's ends are both off the
#    line, so a scan of the end point alone never saw that layer --
key ctrl+shift+n; wait_for 0.6 "new layer"
key l; wait_for 0.3 "line"
drag $CX $(( CY - 60 )) $CX $(( CY - 5 )); wait_for 0.5 "a white line"
snap_region $(( CX - 8 )) $(( CY - 31 )) 16 2 "line-before"; LB="$SNAP_RESULT"
L=$(magick "$LB" -colorspace HSL -channel B -separate -format '%[fx:maxima]' info: 2>/dev/null)
awk -v l="$L" 'BEGIN{exit !(l > 0.9)}' && pass "the line is drawn (lightness $L)" || fail "no line on the new layer (lightness $L)"
key e; wait_for 0.3 "eraser"
shift_erase $(( CY - 30 ))
snap_region $(( CX - 8 )) $(( CY - 31 )) 16 2 "line-after"
L=$(magick "$SNAP_RESULT" -colorspace HSL -channel B -separate -format '%[fx:maxima]' info: 2>/dev/null)
S=$(red_left "$SNAP_RESULT")
info "after: max lightness $L, max saturation $S"
screenshot "eraser-shift-all-layers"
awk -v l="$L" -v s="$S" 'BEGIN{exit !(l < 0.9 && s < 0.2)}' \
    && pass "a fast Shift+erase across a thin line erased it and the layers under it" \
    || fail "the line or the red is left (lightness $L, saturation $S)"
key b
assert_no_crash
rm -rf "$ES_DIR"
