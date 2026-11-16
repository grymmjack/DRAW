#!/bin/bash
# =============================================================================
# hold-e-dot-spray.sh — QA test: Hold E erases the way the Dot / Spray tool
# paints (BUGS.md 2026-11-15)
#
#  - Dot + Hold E: a drag erases ONE dot where it was pressed - it used to swap
#    in the Eraser, which dragged a solid line
#  - Spray + Hold E: the erase is the spray pattern (red specks stay between the
#    erased ones) - it used to be one solid brush stroke
#  - releasing E: Dot paints again (the color comes back)
#
# Fixture: a 320x200 PNG, solid red; any gray in a snap is the transparency
# checkerboard showing through an erased pixel.
# =============================================================================
info "=== Hold E: Dot and Spray erase in their own way ==="
HE_DIR="$(mktemp -d /tmp/draw-qa-holde-XXXXXX)"
magick -size 320x200 xc:'#c00000' "PNG32:$HE_DIR/red.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$HE_DIR/red.png"
draw_launch 15; wait_for 1.5 "red image loaded"
assert_no_crash
CX=$CANVAS_CX; CY=$CANVAS_CY
sat_min() { magick "$1" -colorspace HSL -channel G -separate -format '%[fx:minima]' info: 2>/dev/null; }
sat_max() { magick "$1" -colorspace HSL -channel G -separate -format '%[fx:maxima]' info: 2>/dev/null; }
lt() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a < b)}'; }

# -- Dot --
key d; wait_for 0.3 "dot"
key grave; wait_for 0.1 "pointer"
for i in 1 2 3 4 5 6; do key bracketright; sleep 0.05; done
Y=$(( CY - 30 ))
driver_input_key_hold down e; sleep 0.5
drag $(( CX - 60 )) $Y $(( CX + 60 )) $Y
driver_input_key_hold up e; sleep 0.3
park_mouse; wait_for 0.4 "dot erase"
snap_region $(( CX - 62 )) $(( Y - 1 )) 6 2 "dot-start"; S=$(sat_min "$SNAP_RESULT")
lt "$S" 0.2 && pass "Dot + Hold E erased a dot where it was pressed" || fail "no erased dot at the press point (min saturation $S)"
snap_region $(( CX - 20 )) $(( Y - 1 )) 40 2 "dot-path"; S=$(sat_min "$SNAP_RESULT")
lt 0.8 "$S" && pass "Dot + Hold E: nothing erased along the drag (one dot)" || fail "the drag erased a line (min saturation $S)"
screenshot "hold-e-dot"

# releasing E: the Dot paints its FG again (the erased spot gets painted over)
snap_region $(( CX - 61 )) $(( Y - 1 )) 2 2 "dot-erased"; ERASED="$SNAP_RESULT"
click $(( CX - 60 )) $Y; wait_for 0.4 "a dot"
park_mouse
snap_region $(( CX - 61 )) $(( Y - 1 )) 2 2 "dot-repaint"
assert_regions_differ "$ERASED" "$SNAP_RESULT" "after E is released the Dot paints its color again"

# -- Spray --
key k; wait_for 0.3 "spray"
for i in 1 2 3 4 5 6 7; do key bracketright; sleep 0.05; done
Y=$(( CY + 30 ))
read -r ax ay <<< "$(_abs "$CX" "$Y")"
driver_input_key_hold down e; sleep 0.5
raw_move "$ax" "$ay"; sleep 0.1
raw_button down 1; sleep 0.25
raw_button up 1
driver_input_key_hold up e; sleep 0.3
park_mouse; wait_for 0.4 "spray erase"
# the old hold-E swapped in the Eraser: a solid disc, so the middle of the
# press was all erased. The spray leaves red specks there among erased ones.
snap_region $(( CX - 80 )) $(( Y - 40 )) 160 80 "spray-erase"; SMIN=$(sat_min "$SNAP_RESULT")
snap_region $(( CX - 6 )) $(( Y - 6 )) 12 12 "spray-middle"; SMAX=$(sat_max "$SNAP_RESULT")
info "spray: min saturation around the press $SMIN, max in its middle $SMAX"
screenshot "hold-e-spray"
lt "$SMIN" 0.2 && pass "Spray + Hold E erased pixels" || fail "Spray + Hold E erased nothing (min saturation $SMIN)"
lt 0.8 "$SMAX" && pass "Spray + Hold E is a spray pattern: red stays in the middle of the press" \
    || fail "Spray + Hold E erased a solid disc (max saturation in the middle $SMAX)"
assert_no_crash
rm -rf "$HE_DIR"
