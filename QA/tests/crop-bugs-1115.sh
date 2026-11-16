#!/bin/bash
# =============================================================================
# crop-bugs-1115.sh — QA test: the Crop tool and rect-marquee items from
# PLANS/BUGS.md (2026-11-15)
#
#  1. the Crop button starts with NO box (it used to box the whole canvas):
#     drag the crop rectangle
#  2. Shift+Right nudges the box and the shade outside it follows at once (the
#     overlay is in the cached scene: it waited for a mouse move)
#  3. a click away (no drag) clears the box - it made a 1x1 box
#  4. the rect marquee: a click away clears the selection - it made a 1x1 one
#  5. Image > Crop boxes the whole image and zooms out first when the canvas
#     runs past the view (zoomed in, its edges were off screen)
#  6. a double-click on the Crop button trims the canvas to the artwork (the
#     visible layers' pixels): here the 20x20 square. Ctrl+Z / Ctrl+Y undo and
#     redo it - a shrink crop was not undoable, and redo of a crop re-cut the
#     top-left corner
#
# Fixture: a 320x200 transparent PNG, a 20x20 red square at (150, 90).
# Dump: MARQ <active> <user> <x> <y> <w> <h> <live> | CANVAS w h <crop> |
#       VIEW zoom offX offY tool | CVORG x y | SCR ... | MENU x y w h | MENUI ids
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Crop tool + marquee: BUGS.md 2026-11-15 ==="
CR_DIR="$(mktemp -d /tmp/draw-qa-crop-XXXXXX)"
magick -size 320x200 xc:none -fill '#c00000' -draw 'rectangle 150,90 169,109' "PNG32:$CR_DIR/square.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$CR_DIR/square.png"
draw_launch 15; wait_for 1.5 "square loaded"
assert_no_crash
dk_begin
CX=$CANVAS_CX; CY=$CANVAS_CY
marq()   { read -r _ MQ_ACT MQ_USER MQ_X MQ_Y MQ_W MQ_H MQ_LIVE <<< "$(grep -m1 '^MARQ ' "$DK_DUMP")"; }
canvas() { read -r _ C_W C_H C_CROP <<< "$(grep -m1 '^CANVAS ' "$DK_DUMP")"; }
btn()    { awk -v n="$1" '$1=="BTN" && $2=="toolbox" && $6==n {print $7+int($9/2)" "$8+int($10/2); exit}' "$DK_DUMP"; }
read -r KX KY <<< "$(btn crop)"
[[ -n "$KY" ]] || fail "no Crop button in the toolbox dump"

# -- 1. the Crop button: no box --
click "$KX" "$KY"; wait_for 0.5 "crop mode"; dk_park; dk_settle; marq; canvas
(( C_CROP == 1 )) && pass "the Crop button starts crop mode" || fail "not in crop mode (CANVAS $C_W $C_H $C_CROP)"
(( MQ_ACT == 0 )) && pass "crop mode starts with no box (drag one)" || fail "crop mode boxed $MQ_X,$MQ_Y ${MQ_W}x$MQ_H"
drag $(( CX - 80 )) $(( CY - 60 )) $(( CX + 80 )) $(( CY + 60 )); wait_for 0.5 "drag the crop box"
dk_park; dk_settle; marq
(( MQ_ACT != 0 && MQ_W > 40 && MQ_H > 30 )) && pass "the drag made the crop box (${MQ_W}x$MQ_H)" || fail "no crop box after the drag: MARQ $MQ_ACT ${MQ_W}x$MQ_H"
screenshot "crop-dragged"

# -- 2. Shift+Right: the shade follows without a mouse move --
# a strip just inside the box's left edge (clear of the edge handles) goes from
# lit to shaded when the box moves 10px right
SX=$(( CX - 80 + 6 )); SY=$(( CY - 40 ))
snap_region "$SX" "$SY" 10 6 "crop-lit"; LIT="$SNAP_RESULT"
key shift+Right; wait_for 0.6 "nudge the box"
snap_region "$SX" "$SY" 10 6 "crop-shaded"
assert_regions_differ "$LIT" "$SNAP_RESULT" "the shade follows an arrow-key nudge at once"
marq; info "box after the nudge: $MQ_X,$MQ_Y ${MQ_W}x$MQ_H"

# -- 3. a click away clears the box --
click $(( CX + 120 )) $(( CY + 80 )); wait_for 0.5 "click away"; dk_park; dk_settle; marq
(( MQ_ACT == 0 )) && pass "a click away clears the crop box" || fail "a click away left a box: $MQ_X,$MQ_Y ${MQ_W}x$MQ_H"
key Escape; wait_for 0.4 "end crop"; dk_settle; canvas
(( C_CROP == 0 )) && pass "Esc ends crop mode" || fail "still in crop mode"

# -- 4. rect marquee: a click away clears --
key m; wait_for 0.3 "marquee"
drag $(( CX - 40 )) $(( CY - 30 )) $(( CX + 40 )) $(( CY + 30 )); wait_for 0.5 "select"; dk_settle; marq
(( MQ_LIVE != 0 )) && pass "the marquee selected ${MQ_W}x$MQ_H" || fail "no selection after the drag"
click $(( CX + 120 )) $(( CY + 80 )); wait_for 0.5 "click away"; dk_park; dk_settle; marq
(( MQ_LIVE == 0 )) && pass "a click away clears the selection" || fail "a click away left a selection: $MQ_X,$MQ_Y ${MQ_W}x$MQ_H"

# -- 5. Image > Crop: zoomed in, it zooms out to show the edges --
for i in 1 2 3; do scroll_up "$CX" "$CY"; sleep 0.2; done
wait_for 0.4 "zoomed in"; dk_park; dk_settle
read -r _ Z0 _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
info "zoomed to $Z0%"
read -r _ _ IX IW <<< "$(grep -m1 '^MROOT image ' "$DK_DUMP")"
click $(( IX + IW / 2 )) 6; wait_for 0.6 "image menu"; dk_settle
read -r _ MX MY MW MH <<< "$(grep -m1 '^MENU ' "$DK_DUMP")"
ROWY=$(( MY + 2 )); FOUND=""
for id in $(grep -m1 '^MENUI' "$DK_DUMP" | cut -d' ' -f2-); do
    if [[ "$id" == 0 ]]; then ROWY=$(( ROWY + 5 )); continue; fi
    if [[ "$id" == 1802 ]]; then FOUND=$(( ROWY + 6 )); break; fi
    ROWY=$(( ROWY + 12 ))
done
if [[ -z "$FOUND" ]]; then
    fail "no Crop (1802) in the Image menu"; key Escape
else
    click $(( MX + MW / 2 )) "$FOUND"; wait_for 0.8 "Image > Crop"; dk_park; dk_settle
    marq; canvas; dk_scr
    read -r _ Z1 _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
    read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
    RX=$(( OX + C_W * Z1 / 100 - 1 )); BY=$(( OY + C_H * Z1 / 100 - 1 ))
    info "Image > Crop: $Z0% -> $Z1%, canvas $OX,$OY..$RX,$BY in view $CAN_LX..$CAN_RX x $DOCK_TOP..$DOCK_BOT"
    (( C_CROP == 1 && MQ_ACT != 0 && MQ_W == C_W && MQ_H == C_H )) && pass "Image > Crop boxes the whole image" || fail "Image > Crop box: crop $C_CROP MARQ $MQ_ACT ${MQ_W}x$MQ_H"
    (( OX >= CAN_LX && RX <= CAN_RX && OY >= DOCK_TOP && BY <= DOCK_BOT )) && pass "Image > Crop zoomed out: the image's edges are in view" || fail "the image runs out of view at $Z1%"
    screenshot "crop-image-menu"
    key Escape; wait_for 0.4 "cancel"
fi

# -- 6. double-click the Crop button: trim to the artwork --
read -r KX KY <<< "$(btn crop)"
double_click "$KX" "$KY"; wait_for 0.8 "trim"; dk_park; dk_settle; canvas
(( C_W == 20 && C_H == 20 && C_CROP == 0 )) && pass "a double-click trims the canvas to the artwork (20x20)" || fail "after the double-click: canvas ${C_W}x$C_H crop $C_CROP (want 20x20, crop off)"
screenshot "crop-trimmed"
key ctrl+z; wait_for 0.6 "undo the trim"; dk_settle; canvas
(( C_W == 320 && C_H == 200 )) && pass "Ctrl+Z undoes the trim" || fail "undo: canvas ${C_W}x$C_H"
dk_park; dk_settle; dk_scr
read -r _ Z2 _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
red_at() { snap_region $(( $1 - 1 )) $(( $2 - 1 )) 3 3 "px"; magick "$SNAP_RESULT" -colorspace HSL -channel G -separate -format '%[fx:minima]' info: 2>/dev/null | awk '{exit !($1 > 0.8)}'; }
red_at $(( OX + 160 * Z2 / 100 )) $(( OY + 100 * Z2 / 100 )) && pass "the undo put the square back where it was" || fail "after the undo the square is not at (160,100)"
key ctrl+y; wait_for 0.6 "redo the trim"; dk_park; dk_settle; canvas; dk_scr
read -r _ Z3 _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
(( C_W == 20 && C_H == 20 )) && pass "Ctrl+Y redoes the trim (20x20)" || fail "redo: canvas ${C_W}x$C_H"
red_at $(( OX + 2 * Z3 / 100 )) $(( OY + 2 * Z3 / 100 )) && red_at $(( OX + 17 * Z3 / 100 )) $(( OY + 17 * Z3 / 100 )) \
    && pass "the redo cut the same region (the square fills the canvas)" || fail "the redo cut the wrong region"
screenshot "crop-redo"
assert_no_crash
rm -rf "$CR_DIR"
