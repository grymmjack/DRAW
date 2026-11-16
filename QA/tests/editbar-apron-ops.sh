#!/bin/bash
# =============================================================================
# editbar-apron-ops.sh — QA test: the Edit bar's Flip H / Flip V / Scale /
# Rotate keep art that reaches into the apron (BUGS.md 2026-11-15)
#
# An Edit bar op and its inverse run (Flip H twice, Flip V twice, Rotate CW then
# CCW, Scale 2x then -50%) on art at the canvas's right edge, then the art is
# moved back onto the canvas and its red area counted: it must all be there.
#
#  straddle  - a 40x40 square moved half past the edge (the layer is promoted),
#              no selection
#  sel       - the same, with a selection drawn round the whole square, the
#              apron half included
#  edge      - art on the canvas by the edge, a selection round it; the op
#              itself pushes it past the edge (2x of a 20x20, CW of a 20x60)
#  edge-nosel - the same with no selection: the whole layer turns / doubles
#              about the canvas centre. This is what lost art: the layer's
#              buffer was the canvas, so what went past the edge was cut (a 90
#              degree turn of a 320x200 layer, a 2x). Now the layer is promoted
#              into the apron first, as a Move does.
#
# Dump: VIEW zoom offX offY tool | CVORG x y | BTN editbar i kind id name x y w h
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Edit bar ops keep apron art ==="
EA_DIR="$(mktemp -d /tmp/draw-qa-edapron-XXXXXX)"
magick -size 320x200 xc:none -fill '#c00000' -draw 'rectangle 140,80 179,119' "PNG32:$EA_DIR/square.png"
magick -size 320x200 xc:none -fill '#c00000' -draw 'rectangle 300,90 319,109' "PNG32:$EA_DIR/edge-small.png"
magick -size 320x200 xc:none -fill '#c00000' -draw 'rectangle 290,70 309,129' "PNG32:$EA_DIR/edge-tall.png"

start() { # FIXTURE
    draw_quit; draw_settle
    DRAW_EXTRA_ARGS="$EA_DIR/$1"
    draw_launch 15; wait_for 1.5 "loaded"
    dk_begin
    read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
    read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
    key grave; wait_for 0.1 "pointer"
}
sx() { echo $(( OX + $1 * Z / 100 )); }
sy() { echo $(( OY + $1 * Z / 100 )); }
eb() { awk -v n="$1" '$1=="BTN" && $2=="editbar" && $6==n {print $7+int($9/2)" "$8+int($10/2); exit}' "$DK_DUMP"; }
ebclick() { local X Y; read -r X Y <<< "$(eb "$1")"; click "$X" "$Y"; wait_for 0.6 "$1"; }
move_layer() { # DX (canvas px) - the whole layer (no selection), applied
    key ctrl+d; wait_for 0.2 "deselect"
    key v; wait_for 0.3 "move tool"
    drag "$(sx 150)" "$(sy 30)" "$(sx $(( 150 + $1 )))" "$(sy 30)"; wait_for 0.6 "move"
    key Return; wait_for 0.5 "apply"
}
red_area() { # canvas px of red in canvas (20..319, 20..179)
    dk_park
    snap_region "$(sx 20)" "$(sy 20)" $(( 300 * Z / 100 )) $(( 160 * Z / 100 )) "area"
    magick "$SNAP_RESULT" -colorspace HSL -channel G -separate -threshold 80% -format '%[fx:mean]' info: 2>/dev/null | awk '{printf "%d", $1 * 300 * 160 + 0.5}'
}
check() { # NAME WANT
    local got; got=$(red_area)
    screenshot "editbar-apron-$1"
    if (( got * 100 >= $2 * 95 && got * 100 <= $2 * 105 )); then pass "$1: all the art is back (${got}px of $2)"
    else fail "$1: ${got}px of the art left (want $2): the op cut what was in the apron"; fi
}

# -- straddle: no selection --
for op in "flip-h flip-h" "flip-v flip-v" "rotate-cw rotate-ccw" "scale-up scale-down"; do
    set -- $op
    start square.png; move_layer 160            # x 300..339
    key b; wait_for 0.2 "brush"
    ebclick "$1"; ebclick "$2"
    move_layer -160
    check "straddle-$1-$2" 1600
done

# -- sel: a selection round the whole square, apron half included --
for op in "flip-h flip-h" "flip-v flip-v" "rotate-cw rotate-ccw" "scale-up scale-down"; do
    set -- $op
    start square.png; move_layer 160
    key m; wait_for 0.2 "marquee"
    drag "$(sx 290)" "$(sy 70)" "$(sx 350)" "$(sy 130)"; wait_for 0.4 "select into the apron"
    ebclick "$1"; ebclick "$2"
    key Return; wait_for 0.4 "apply"; key ctrl+d; wait_for 0.3 "deselect"
    move_layer -160
    check "sel-$1-$2" 1600
done

# -- edge: the op pushes the art past the edge, and back --
start edge-small.png                            # 20x20 at x 300..319 -> 2x = 290..329
key m; wait_for 0.2 "marquee"
drag "$(sx 298)" "$(sy 88)" "$(sx 319)" "$(sy 111)"; wait_for 0.4 "select"
ebclick scale-up; ebclick scale-down
key Return; wait_for 0.4 "apply"; key ctrl+d; wait_for 0.3 "deselect"
move_layer -100
check "edge-scale-up-down" 400
start edge-tall.png                             # 20x60 at x 290..309 -> CW = 60x20, x 270..329
key m; wait_for 0.2 "marquee"
drag "$(sx 288)" "$(sy 68)" "$(sx 311)" "$(sy 131)"; wait_for 0.4 "select"
ebclick rotate-cw; ebclick rotate-ccw
key Return; wait_for 0.4 "apply"; key ctrl+d; wait_for 0.3 "deselect"
move_layer -100
check "edge-rotate-cw-ccw" 1200
# -- edge, no selection: the whole-layer op pushes it past the edge, and back --
start edge-small.png                            # 2x about the canvas centre: x 280..319 -> 440..479
key b; wait_for 0.2 "brush"
ebclick scale-up; ebclick scale-down
move_layer -100
check "edge-nosel-scale-up-down" 400
start edge-tall.png                             # CW about (160,100): x 290..309 -> y 230..249, past the bottom
key b; wait_for 0.2 "brush"
ebclick rotate-cw; ebclick rotate-ccw
move_layer -100
check "edge-nosel-rotate-cw-ccw" 1200
start edge-small.png                            # 2x alone: x 280..319 -> 440..479, all in the apron
key b; wait_for 0.2 "brush"
ebclick scale-up
move_layer -200                                 # -> 240..279: on the canvas, 40x40
check "edge-nosel-scale-up-move" 1600
start edge-tall.png                             # rotate, then Ctrl+Z: back as it was
key b; wait_for 0.2 "brush"
ebclick rotate-cw
key ctrl+z; wait_for 0.5 "undo"
move_layer -100
check "edge-nosel-rotate-undo" 1200
assert_no_crash
rm -rf "$EA_DIR"
