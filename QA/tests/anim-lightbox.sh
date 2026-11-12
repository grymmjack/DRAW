#!/bin/bash
# =============================================================================
# anim-lightbox.sh — QA test: the lightbox view (Animation 2.1, TOOLS/ANIM-LB).
#
# Num 0 / ANIM > Lightbox swaps the sheet for the lightbox: the strip of
# frames, the transport bar, and 3 / 5 / 7 editor panes (Num *) with the
# current frame in the middle. Every picture is cut from the composited
# sheet, so each pane must show its frame's own mark: the fixture gives frame
# n a mark of its own colour, and the checks look for that colour in each
# pane's screenshot. The transport bar's |< < PLAY > >|, loop menu and + work; a
# press outside the pane pictures draws nothing (drawing in them:
# anim-lightbox-draw.sh).
#
# Dump: ANIMLB shown x1 y1 x2 y2 stripY stripH barY barH edY edH stripFirst
# stripN cellW cellH panes paneW paneH pad; ANIMLBC x w per control (1 |<,
# 2 <, 3 PLAY, 4 >, 5 >|, 6 loop, ... 14 +); ANIM / ANIMC as in the other
# animation tests.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: lightbox ==="

LB_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LB_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LB_DIR="/tmp/draw-qa-lightbox-$$"
mkdir -p "$LB_DIR"
LB_DRAW=()
LB_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0 e08020) # frame n = LB_COLORS[n-1]
for n in 0 1 2 3 4 5 6; do
    x=$(( (n % 4) * 16 + 2 )); y=$(( (n / 4) * 16 + 2 ))
    LB_DRAW+=(-fill "#${LB_COLORS[$n]}" -draw "rectangle $x,$y $(( x + 1 + n )),$(( y + 9 ))")
done
magick -size 64x32 xc:none "${LB_DRAW[@]}" "$LB_DIR/plain.png"
LB_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$LB_PY" put "$LB_DIR/plain.png" "$LB_DIR/sheet.png" drAn "$LB_BLOB"

lb_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
lb_line() { grep -m1 "^$1 " "$LB_DUMP" 2>/dev/null; }
lb_read() { # A_COUNT A_CUR A_LOOP A_GRID A_PLAY, A_T; LB_*; C_X[k] C_W[k]
    lb_settle
    read -r _ _ A_COUNT A_CUR _ _ _ _ _ _ _ A_LOOP A_GRID _ _ _ _ A_PLAY _ <<< "$(lb_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(lb_line ANIMC)"
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(lb_line ANIMLB)"
    local c; c=($(lb_line ANIMLBC)); C_X=(); C_W=()
    for k in $(seq 1 14); do C_X[$k]=${c[$((2 * k - 1))]:-0}; C_W[$k]=${c[$((2 * k))]:-0}; done
}
lb_key() { park_mouse; key "$1"; wait_for 0.4 "$1"; }
lb_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 0.6 "$1"
}
lb_ctl() { # K - click transport control K
    click $(( C_X[$1] + C_W[$1] / 2 )) $(( LB_BY + LB_BH / 2 ))
    wait_for 0.4 "control $1"
}
lb_colors() { # FILE -> the frame numbers whose mark colour is in it
    local hist out="" n; hist=$(magick "$1" -format %c histogram:info:- 2>/dev/null | tr 'a-f' 'A-F')
    for n in 1 2 3 4 5 6 7; do
        grep -q "#${LB_COLORS[$((n - 1))]^^}" <<< "$hist" && out+=" $n"
    done
    echo "${out# }"
}
lb_snap() { # X Y W H LABEL - snap a viewport region with the floating Preview
    # window (it shows the current frame too) painted out where it overlaps
    local x=$1 y=$2 w=$3 h=$4 px py pw ph sc ix1 iy1 ix2 iy2
    snap_region "$x" "$y" "$w" "$h" "$5" >&2
    read -r _ _ px py pw ph _ <<< "$(lb_line 'WIN preview')"
    [[ -z "${pw:-}" || "${pw:-0}" -le 0 ]] && return
    ix1=$(( px > x ? px : x )); iy1=$(( py > y ? py : y ))
    ix2=$(( px + pw < x + w ? px + pw : x + w )); iy2=$(( py + ph < y + h ? py + ph : y + h ))
    (( ix2 <= ix1 || iy2 <= iy1 )) && return
    sc=$(( $(magick identify -format %w "$SNAP_RESULT") / w ))
    magick "$SNAP_RESULT" -fill black -draw "rectangle $(( (ix1 - x) * sc )),$(( (iy1 - y) * sc )) $(( (ix2 - x) * sc - 1 )),$(( (iy2 - y) * sc - 1 ))" "$SNAP_RESULT"
}
lb_pane() { # K - snap pane K's picture area, echo the frames seen in it
    lb_snap $(( LB_X1 + LB_PAD + $1 * (LB_PW + LB_PAD) )) $(( LB_EY + LB_PAD )) "$LB_PW" "$LB_PH" "pane$1"
    lb_colors "$SNAP_RESULT"
}
lb_panes_expect() { # "F0|F1|..." LABEL - pane k must show exactly frame Fk ("" = empty), one per pane
    local want=$1 got="" k
    for k in $(seq 0 $(( LB_P - 1 ))); do got+="$(lb_pane "$k")|"; done
    got="${got%|}"
    [[ "$got" == "$want" ]] && pass "$2 (panes: $got)" || fail "$2: panes show [$got], wanted [$want]"
}
lb_strip_want() { # the frames the strip should show: stripFirst..+stripN-1
    seq "$LB_SF" $(( LB_SF + LB_SN - 1 )) | tr '\n' ' ' | sed 's/ $//'
}

info "Launching DRAW with a 64x32 sheet of 16x16 frames (7, current 3)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LB_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"

lb_read
[[ "${LB_SHOWN:-}" == 0 && "$A_GRID" == -1 ]] && pass "starts in sheet view (frame grid drawn)" || fail "start: lightbox shown '${LB_SHOWN:-}' grid '$A_GRID'"

# -- Num 0: the lightbox --
lb_key KP_0
lb_read
if [[ "${LB_SHOWN:-}" == -1 ]]; then
    pass "Num 0: lightbox shown"
else
    fail "Num 0: lightbox shown '${LB_SHOWN:-}'"
fi
# the strip: as many cells as fit (frame-shaped, the band's height), current in view
LB_FIT=$(( (LB_X2 - LB_X1 + 1 - LB_PAD) / (LB_CW + LB_PAD) )); (( LB_FIT > 7 )) && LB_FIT=7
[[ "$LB_P" == 3 && "$LB_SN" == "$LB_FIT" && "$LB_SF" == 1 && "$A_GRID" == 0 && "$LB_CW" == "$LB_CH" ]] \
    && pass "3 panes, $LB_SN square cells in the strip from frame 1, no sheet grid" \
    || fail "layout: panes $LB_P strip $LB_SF+$LB_SN (fit $LB_FIT) cell ${LB_CW}x$LB_CH grid $A_GRID"
(( LB_SY >= LB_Y1 && LB_BY == LB_SY + LB_SH && LB_EY == LB_BY + LB_BH && LB_EY + LB_EH - 1 == LB_Y2 )) \
    && pass "strip, bar and editor stack down the work area" || fail "bands: area y $LB_Y1-$LB_Y2 strip $LB_SY+$LB_SH bar $LB_BY+$LB_BH editor $LB_EY+$LB_EH"

# a floating window parked on the work area's edge (the user profile's Color
# Mixer, top-left) must not cover the transport bar: the lightbox lays out beside it
LB_COVER=""
while read -r _ nm wx wy ww wh slot; do
    [[ "$slot" == 0 ]] || continue
    for k in 1 5 14; do
        cx=$(( C_X[$k] + C_W[$k] / 2 )); cy=$(( LB_BY + LB_BH / 2 ))
        (( cx >= wx && cx < wx + ww && cy >= wy && cy < wy + wh )) && LB_COVER+=" $nm:ctl$k"
    done
done < <(grep "^WIN " "$LB_DUMP")
[[ -z "$LB_COVER" ]] && pass "no floating window covers |<, >| or + (area x $LB_X1-$LB_X2)" || fail "transport controls covered:$LB_COVER"

if [[ "${LB_SHOWN:-}" == -1 ]]; then
    # the strip shows every frame's own drawing
    lb_snap "$LB_X1" "$LB_SY" $(( LB_X2 - LB_X1 + 1 )) "$LB_SH" "strip"
    LB_S=$(lb_colors "$SNAP_RESULT")
    [[ "$LB_S" == "$(lb_strip_want)" ]] && pass "the strip shows frames $LB_S" || fail "the strip shows frames [$LB_S], wanted [$(lb_strip_want)]"

    lb_panes_expect "2|3|4" "panes: frame 2, the current frame 3, frame 4"

    lb_key KP_5
    lb_read
    [[ "$A_CUR" == 4 ]] && lb_panes_expect "3|4|5" "Num 5: the panes follow (3 4 5)" || fail "Num 5: current $A_CUR"

    # -- Num *: 5 panes, then 7, then 1 (the big frame, 2026-11-12), then 3 --
    lb_key KP_Multiply
    lb_read
    [[ "$LB_P" == 5 ]] && lb_panes_expect "2|3|4|5|6" "Num *: 5 panes round frame 4" || fail "Num *: panes $LB_P, wanted 5"
    lb_key KP_1
    lb_read
    [[ "$A_CUR" == 1 ]] && lb_panes_expect "||1|2|3" "Num 1: frame 1 in the middle, nothing before it" || fail "Num 1: current $A_CUR"
    lb_key KP_Multiply
    lb_read; [[ "$LB_P" == 7 ]] && pass "Num * again: 7 panes" || fail "panes $LB_P, wanted 7"
    lb_key KP_Multiply
    lb_read; [[ "$LB_P" == 1 ]] && lb_panes_expect "1" "Num * again: 1 pane, the current frame (big frame)" || fail "panes $LB_P, wanted 1"
    lb_key KP_Multiply
    lb_read; [[ "$LB_P" == 3 ]] && pass "Num * again: back to 3 panes" || fail "panes $LB_P, wanted 3"

    # -- the transport bar --
    lb_ctl 4; lb_read; [[ "$A_CUR" == 2 ]] && pass "bar >: frame 2" || fail "bar >: current $A_CUR"
    lb_ctl 5; lb_read; [[ "$A_CUR" == 7 ]] && pass "bar >|: frame 7" || fail "bar >|: current $A_CUR"
    lb_panes_expect "6|7|" "frame 7: nothing after it"
    lb_ctl 2; lb_read; [[ "$A_CUR" == 6 ]] && pass "bar <: frame 6" || fail "bar <: current $A_CUR"
    lb_ctl 1; lb_read; [[ "$A_CUR" == 1 ]] && pass "bar |<: frame 1" || fail "bar |<: current $A_CUR"
    lb_ctl 3; lb_read; [[ "$A_PLAY" == -1 ]] && pass "bar PLAY" || fail "bar PLAY: playing '$A_PLAY'"
    lb_ctl 3; lb_read; [[ "$A_PLAY" == 0 ]] && pass "bar STOP" || fail "bar STOP: playing '$A_PLAY'"
    LB_L0=$A_LOOP
    # the loop chip opens a menu of the modes (2.4; anim-lightbox-bar tests it in full)
    lb_ctl 6; read -r _ _ _ LB_MO _ _ LB_MX LB_MY LB_MW _ <<< "$(lb_line ANIMLBE)"
    click $(( ${LB_MX:-0} + ${LB_MW:-0} / 2 )) $(( ${LB_MY:-0} + 2 + 12 + 6 )); wait_for 0.4 "pick Backward"
    lb_read; [[ "$LB_MO" == -1 && "$A_LOOP" == 1 ]] && pass "bar loop chip: its menu sets Backward" || fail "loop chip: menu '$LB_MO', loop $LB_L0 -> $A_LOOP"
    lb_ctl 6; read -r _ _ _ _ _ _ LB_MX LB_MY LB_MW _ <<< "$(lb_line ANIMLBE)"
    click $(( ${LB_MX:-0} + ${LB_MW:-0} / 2 )) $(( ${LB_MY:-0} + 2 + LB_L0 * 12 + 6 )); wait_for 0.4 "pick the first mode"
    lb_read; [[ "$A_LOOP" == "$LB_L0" ]] && pass "and back to the first loop mode" || fail "loop back: $A_LOOP"
    lb_ctl 14; lb_read
    [[ "$A_COUNT" == 8 && "$A_CUR" == 8 ]] && pass "bar +: a frame added, now current" || fail "bar +: count $A_COUNT current $A_CUR"
    lb_snap "$LB_X1" "$LB_SY" $(( LB_X2 - LB_X1 + 1 )) "$LB_SH" "strip8"
    LB_S=$(lb_colors "$SNAP_RESULT") # frame 8 is a copy of 7: same colour
    [[ $(( LB_SF + LB_SN - 1 )) == 8 && "$LB_S" == "$(lb_strip_want | sed 's/ 8$//')" ]] && pass "the strip scrolls to show it (frames $LB_SF-8)" \
        || fail "strip after +: frames $LB_SF+$LB_SN, colours [$LB_S]"
    lb_key ctrl+z
    lb_read; [[ "$A_COUNT" == 7 ]] && pass "undo +" || fail "undo +: count $A_COUNT"

    # -- a press beside the pane pictures (the label row) and in the strip
    # draws nothing (drawing in the pictures: anim-lightbox-draw.sh) --
    LB_BEFORE="$A_T"
    read -r _ _ _ _ _ LBP_Y _ LBP_H _ <<< "$(lb_line ANIMLBP)"
    click $(( LB_X1 + LB_PAD + LB_PW + LB_PAD + LB_PW / 2 )) $(( ${LBP_Y:-$LB_EY} + ${LBP_H:-$LB_PH} + 2 ))
    wait_for 0.4 "click under the middle pane's picture"
    click $(( LB_X1 + LB_PAD + LB_CW / 2 )) $(( LB_SY + LB_PAD + LB_CH / 2 ))
    wait_for 0.4 "click in the strip"
    lb_read
    [[ "$A_T" == "$LB_BEFORE" ]] && pass "clicks beside the pictures and in the strip draw nothing" || fail "lightbox clicks drew: [$LB_BEFORE] -> [$A_T]"
fi

# -- back to the sheet, and through the menu --
lb_key KP_0
lb_read
[[ "${LB_SHOWN:-}" == 0 && "$A_GRID" == -1 ]] && pass "Num 0 again: sheet view, the frame grid back" || fail "Num 0 off: shown '${LB_SHOWN:-}' grid '$A_GRID'"
lb_cmd "toggle lightbox"
lb_read; [[ "${LB_SHOWN:-}" == -1 ]] && pass "Toggle Lightbox command: on" || fail "command on: shown '${LB_SHOWN:-}'"
lb_cmd "toggle lightbox"
lb_read; [[ "${LB_SHOWN:-}" == 0 ]] && pass "Toggle Lightbox command: off" || fail "command off: shown '${LB_SHOWN:-}'"
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LB_DIR"
assert_window_exists
