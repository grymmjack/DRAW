#!/bin/bash
# =============================================================================
# gui-float-zorder.sh — QA test: overlapping floating windows stack like OS
# windows (GUI/WINZ).
#   A) floating dock panels (toolbox + layers): the one in front is drawn whole
#      (content, grip, border) over the one behind; a press on the one behind
#      brings it to the front; a click in the overlap goes to the front one only
#   B) native windows (Color Mixer + Advanced Color Picker): a press on the one
#      behind brings it to the front
#   C) a floating dock panel over a native window: in front, it is drawn whole
#      over it; a press on the native window brings that one back up
# Rick, 2026-11-06: "the drag bar handle isn't drawn in the proper z-index.
# same with the borders" / "clicking the title bar of the panel should bring it
# forward in the z-index, like regular windows".
# Reads WZ <held> <name...> (front to back), BTN, P, WIN, VIEW (tool = 5th).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LAYER_PANEL_WIDTH=200 SNAP_PANEL_EDGES=0 COLOR_MIXER_VISIBLE=1 COLOR_MIXER_X=560 COLOR_MIXER_Y=60 ADV_COLOR_PICKER_VISIBLE=1 ADV_COLOR_PICKER_X=620 ADV_COLOR_PICKER_Y=150
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Floating windows stack front to back Test ==="
dk_begin
dk_scr

front() { awk '$1 == "WZ" {print $3}' "$DK_DUMP"; }
tool()  { awk '$1 == "VIEW" {print $5}' "$DK_DUMP"; }
win()   { read -r _ _ W_X W_Y W_W W_H _ <<< "$(grep "^WIN $1 " "$DK_DUMP")"; }
settle() { dk_park; dk_settle; }
ahead() { # a b label: a nearer the front than b
    local l; l=$(grep '^WZ' "$DK_DUMP")
    if awk -v a="$1" -v b="$2" '$1 == "WZ" {for (i = 3; i <= NF; i++) {if ($i == a) {ok = 1; exit} if ($i == b) exit}} END {exit !ok}' "$DK_DUMP"; then pass "$3: $1 in front of $2"; else fail "$3: $1 not in front of $2 [$l]"; fi
}
expect_front() { # name label
    local f; f=$(front)
    if [[ "$f" == "$1" ]]; then pass "$2: $1 in front"; else fail "$2: $f in front, not $1 [$(grep '^WZ' "$DK_DUMP")]"; fi
}

# ---- A) two floating dock panels -------------------------------------------
dk_move toolbox float $(( CAN_LX + 70 )) $(( DOCK_TOP + 50 ))
dk_expect_floating toolbox
dk_move layers float $(( CAN_RX - 150 )) $(( DOCK_BOT - 150 ))
dk_expect_floating layers
settle
dk_p toolbox; TFX=$P_FX; TFY=$P_FY; TFW=$P_FW; TFH=$P_FH; TCY=$P_Y
info "toolbox window $TFX,$TFY ${TFW}x$TFH (content from y=$TCY)"
# the toolbox's lower-right quarter (the part the layers will cover), and its whole content
QX=$(( TFX + TFW / 2 )); QY=$(( TFY + TFH / 2 )); QW=$(( TFW / 2 - 2 )); QH=$(( TFH / 2 - 2 ))
snap_region "$QX" "$QY" "$QW" "$QH" "tb-quarter-alone"; Q_ALONE=$SNAP_RESULT
snap_region $(( TFX + 1 )) "$TCY" $(( TFW - 2 )) $(( TFY + TFH - 1 - TCY )) "tb-alone"; TB_ALONE=$SNAP_RESULT

# the layers' top-left onto the middle of the toolbox
dk_p layers
GX=$(( P_FX + P_FW / 2 )); GY=$(( P_FY + 2 ))
dk_drag "$GX" "$GY" $(( GX + QX - P_FX )) $(( GY + QY - P_FY ))
settle
dk_p layers; LFX=$P_FX; LFY=$P_FY; LFW=$P_FW
info "layers window $LFX,$LFY ${LFW}x$P_FH"
(( LFX <= QX + 2 && LFY <= QY + 2 && LFX + LFW >= QX + QW )) || fail "the layers did not land over the toolbox's quarter"
expect_front layers "dragged over the toolbox"
snap_region "$QX" "$QY" "$QW" "$QH" "tb-quarter-covered"; Q_COVERED=$SNAP_RESULT
assert_regions_differ "$Q_ALONE" "$Q_COVERED" "the layers in front cover the toolbox's quarter"

# a toolbox button inside the covered quarter (centre), and a tool to compare
read -r BCX BCY BTOOL <<< "$(awk -v x1="$QX" -v y1="$QY" -v x2=$(( QX + QW )) -v y2=$(( QY + QH )) \
    '$1 == "BTN" && $2 == "toolbox" && $4 == 1 {cx = $(NF-3) + int($(NF-1) / 2); cy = $(NF-2) + int($NF / 2);
     if (cx > x1 + 2 && cx < x2 - 2 && cy > y1 + 2 && cy < y2 - 2) {print cx, cy, $5; exit}}' "$DK_DUMP")"
info "toolbox button under the layers at $BCX,$BCY (tool $BTOOL), tool now $(tool)"
if [[ -n "$BCX" ]]; then
    T0=$(tool)
    click "$BCX" "$BCY"; wait_for 0.4 "click in the overlap"
    settle
    if [[ "$(tool)" == "$T0" ]]; then pass "a click in the overlap goes to the layers in front (tool stays $T0)"; else fail "the toolbox behind the layers took the click (tool $T0 -> $(tool))"; fi
else
    fail "no toolbox button found inside the covered quarter"
fi

# press the toolbox's title (above the layers): to the front, drawn whole
click $(( TFX + 10 )) $(( TFY + 2 )); wait_for 0.4 "toolbox title pressed"
settle
expect_front toolbox "pressed its title"
snap_region "$QX" "$QY" "$QW" "$QH" "tb-quarter-front"
assert_regions_same "$Q_ALONE" "$SNAP_RESULT" "the toolbox in front is drawn whole over the layers (buttons, border)" 40
screenshot "zorder-toolbox-front"
if [[ -n "$BCX" ]]; then
    click "$BCX" "$BCY"; wait_for 0.4 "click the button, toolbox in front"
    settle
    if [[ "$(tool)" != "$T0" ]]; then pass "in front, the toolbox takes the click (tool $T0 -> $(tool))"; else fail "the toolbox in front did not take the click (tool stays $T0)"; fi
fi

# press the layers' grip right of the toolbox: the layers back to the front
click $(( TFX + TFW + 20 )) $(( LFY + 2 )); wait_for 0.4 "layers grip pressed"
settle
expect_front layers "pressed its grip"
snap_region "$QX" "$QY" "$QW" "$QH" "tb-quarter-back"
assert_regions_same "$Q_COVERED" "$SNAP_RESULT" "the layers in front again cover the quarter as before" 40

# ---- B) two native windows --------------------------------------------------
win colormixer; MX=$W_X; MY=$W_Y; MW=$W_W; MH=$W_H
win advcolorpicker; AX=$W_X; AY=$W_Y; AW=$W_W; AH=$W_H
info "mixer $MX,$MY ${MW}x$MH, advanced picker $AX,$AY ${AW}x$AH"
[[ -n "$MW" && -n "$AW" ]] || { fail "the Color Mixer / Advanced Color Picker are not showing"; exit 1; }
OX=$(( AX > MX ? AX : MX )); OY=$(( AY > MY ? AY : MY ))
OX2=$(( AX + AW < MX + MW ? AX + AW : MX + MW )); OY2=$(( AY + AH < MY + MH ? AY + AH : MY + MH ))
(( OX2 - OX > 10 && OY2 - OY > 10 )) || fail "the mixer and the picker do not overlap ($OX,$OY - $OX2,$OY2)"
snap_region "$OX" "$OY" $(( OX2 - OX )) $(( OY2 - OY )) "nat-start"; N_START=$SNAP_RESULT
ahead advcp mixer "native windows at start"
click $(( MX + 12 )) $(( MY + 3 )); wait_for 0.4 "mixer title pressed"
settle
expect_front mixer "pressed the mixer's title"
snap_region "$OX" "$OY" $(( OX2 - OX )) $(( OY2 - OY )) "nat-mixer"
assert_regions_differ "$N_START" "$SNAP_RESULT" "the mixer comes up over the picker"
click $(( AX + AW - 30 )) $(( AY + 3 )); wait_for 0.4 "picker title pressed"
settle
expect_front advcp "pressed the picker's title"
snap_region "$OX" "$OY" $(( OX2 - OX )) $(( OY2 - OY )) "nat-advcp"
assert_regions_same "$N_START" "$SNAP_RESULT" "the picker back in front looks as it did" 40
screenshot "zorder-natives"

# ---- C) a floating dock panel over a native window ---------------------------
# the toolbox in front of the layers again (drawn whole - checked above), as
# the reference: the tool picked in A changed its highlighted button
click $(( TFX + 10 )) $(( TFY + 2 )); wait_for 0.4 "toolbox title pressed"
settle
snap_region $(( TFX + 1 )) "$TCY" $(( TFW - 2 )) $(( TFY + TFH - 1 - TCY )) "tb-ref"; TB_ALONE=$SNAP_RESULT
win colormixer; MX=$W_X; MY=$W_Y; MW=$W_W; MH=$W_H
dk_p toolbox
GX=$(( P_FX + 10 )); GY=$(( P_FY + 2 ))
dk_drag "$GX" "$GY" $(( GX + (MX - TFW / 2) - P_FX )) $(( GY + (MY + MH / 2) - P_FY ))
settle
dk_p toolbox; T2X=$P_FX; T2Y=$P_FY; T2C=$P_Y
info "toolbox moved to $T2X,$T2Y (mixer at $MX,$MY)"
(( T2X + TFW > MX + 10 )) || fail "the toolbox did not land over the mixer"
expect_front toolbox "dragged over the mixer"
snap_region $(( T2X + 1 )) "$T2C" $(( TFW - 2 )) $(( T2Y + TFH - 1 - T2C )) "tb-over-mixer"; TB_OVER=$SNAP_RESULT
assert_regions_same "$TB_ALONE" "$TB_OVER" "the toolbox in front is drawn whole over the Color Mixer" 40
screenshot "zorder-toolbox-over-mixer"
click $(( MX + 12 )) $(( MY + 3 )); wait_for 0.4 "mixer title pressed"
settle
expect_front mixer "pressed the mixer's title"
snap_region $(( T2X + 1 )) "$T2C" $(( TFW - 2 )) $(( T2Y + TFH - 1 - T2C )) "tb-under-mixer"
assert_regions_differ "$TB_OVER" "$SNAP_RESULT" "the mixer in front covers the toolbox again"

assert_window_exists
info "=== Floating windows stack front to back Test PASSED ==="
