#!/bin/bash
# =============================================================================
# lane-key-clipboard.sh — QA test: copy / cut / paste / delete on the X-sheet's
# key selection (TOOLS/ANIM-XLANE ANIM_XL_keys_*, ANIM_ACT_KEYS_*).
#
# Rick 2026-11-16: "can we add cut/copy/paste keyframes - and it can operate on
# a selection of frames in a lane? ... copy/paste automation from one section
# of time to another".
#
#   - X keys frame 1 = 0, frame 4 = 6 (2 a frame); Y keys frames 1, 3
#   - frames 2-3 of X selected (no key in it), Ctrl+C: the clipboard has keys
#     baked at both ends - 2 and 4 ("copy what you see")
#   - frame 5, Ctrl+V: X keys on 5 (2) and 6 (4); the pasted span selected;
#     Ctrl+Z takes it back
#   - Delete on frames 3-4 of X + Y: X's key on 4 and Y's on 3 gone, one Ctrl+Z
#   - Ctrl+X on frame 4 of X: copied (6) and gone
#   - copied from layer 1, a new layer, Ctrl+V: the keys go on the new layer's X
#   - a pixel Ctrl+C makes the pixels the newest copy (Ctrl+V pastes them again)
#
# Dump: XLSEL, XLCB rows frames newest lane=f:v..., LLN entry id slot lanes.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Animation: copy / cut / paste / delete lane keys ==="

KC_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
KC_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
KC_DIR="/tmp/draw-qa-keyclip-$$"
mkdir -p "$KC_DIR"
KC_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
KC_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 + 5 ))
    KC_DRAW+=(-fill "#${KC_COLORS[$n]}" -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 96x16 xc:none "${KC_DRAW[@]}" "PNG32:$KC_DIR/plain.png"
python3 "$KC_PY" put "$KC_DIR/plain.png" "$KC_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

kc_line() { grep -m1 "^$1 " "$KC_DUMPF" 2>/dev/null; }
kc_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(kc_line ANIMXSLO)"
    read -r _ XA_SLOT XA_Y _ <<< "$(kc_line ANIMXSLA)"
    XF=($(kc_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(kc_line ANIMXS)"
    read -r _ _ A_COUNT A_CUR _ <<< "$(kc_line ANIM)"
    XM=($(kc_line ANIMXLM))
    LLN="$(grep -m1 '^LLN ' "$KC_DUMPF" | cut -d' ' -f5-)"
    LLNS="$(grep '^LLN ' "$KC_DUMPF" | cut -d' ' -f4- | tr '\n' '|')"
    read -r _ S_ON S_F1 S_F2 S_N S_LANES <<< "$(kc_line XLSEL)"
    read -r _ CB_N CB_W CB_LAST CB_K <<< "$(kc_line XLCB)"
}
kc_s() { echo "frame ${A_CUR:-?} sel '${S_ON:-}' ${S_F1:-?}-${S_F2:-?} [${S_LANES:-}] clip '${CB_N:-?} ${CB_W:-?} ${CB_LAST:-?} ${CB_K:-}' lanes [$LLNS]"; }
kc_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; kc_read; }
kc_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
kc_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
kc_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
kc_pick() { local iy; iy=$(kc_item "$1"); [[ -z "$iy" ]] && return 1; kc_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); kc_read; }
kc_lane_y() { grep -m1 "^ANIMXSLN 1 $1 " "$KC_DUMPF" 2>/dev/null | cut -d' ' -f4; }
kc_drag() { # X0 Y0 X1 Y1
    mouse_down "$1" "$2"; hover $(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 )); sleep 0.15; hover "$3" "$4"; sleep 0.3
    mouse_up; wait_for 0.6 "drop"; kc_read
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$KC_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key ctrl+0; wait_for 0.6 "zoom"; key KP_8; wait_for 0.6 "x-sheet"
kc_read
if [[ "$XO_SLOT" != 1 || "$(kc_fmid 4)" == 0 ]]; then
    fail "start: no lanes arrow / frames (arrow '${XO_SLOT:-}' frames '${XF[*]}')"
else
    kc_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); kc_read
    kc_hclick "$(kc_fmid 1)" $(( XA_Y + XLH / 2 )); kc_read; kc_pick 31101
    kc_hclick "$(kc_fmid 1)" $(( XA_Y + XLH / 2 )); kc_read; kc_pick 31102
    XY=$(( $(kc_lane_y 1) + XLH / 2 )); YY=$(( $(kc_lane_y 2) + XLH / 2 ))
    double_click "$(kc_fmid 4)" "$XY"; wait_for 0.6 "a key on X"
    double_click "$(kc_fmid 4)" "$XY"; wait_for 0.9 "input box"
    key ctrl+a; type_text "6"; key Return; wait_for 0.8 "typed 6"
    double_click "$(kc_fmid 3)" "$YY"; wait_for 0.6 "a key on Y"
    kc_read
    [[ "$LLN" == "1=0:0:0,3:6:0 2=0:0:0,2:0:0" ]] && pass "X keys 1 (0) and 4 (6), Y keys 1 and 3" || fail "setup: $(kc_s)"

    # -- copy what you see: frames 2-3 of X, no key in them --
    kc_drag "$(kc_fmid 2)" "$XY" "$(kc_fmid 3)" "$XY"
    kc_key ctrl+c
    [[ "$CB_N" == 1 && "$CB_W" == 2 && "$CB_LAST" == 1 && "$CB_K" == "1=0:2,1:4" ]] \
        && pass "Ctrl+C on frames 2-3 of X: keys baked at both ends (2, 4)" || fail "copy: $(kc_s)"
    [[ "$LLN" == "1=0:0:0,3:6:0 2=0:0:0,2:0:0" ]] && pass "copying changed no key" || fail "copy changed keys: $(kc_s)"

    # -- paste at frame 5 --
    kc_hclick "$(kc_fmid 5)" "$YY"; kc_read # (empty Y space: frame 5 current, the selection cleared)
    [[ "$A_CUR" == 5 && "$S_ON" == 0 && "$CB_N" == 1 ]] && pass "a click on frame 5: frame 5 current, the selection gone, the clipboard kept" || fail "to frame 5: $(kc_s)"
    kc_key ctrl+v
    [[ "$LLN" == "1=0:0:0,3:6:0,4:2:0,5:4:0 2=0:0:0,2:0:0" ]] && pass "Ctrl+V at frame 5: X keys on 5 (2) and 6 (4)" || fail "paste: $(kc_s)"
    [[ "$S_ON" == 1 && "$S_F1" == 5 && "$S_F2" == 6 && "$S_LANES" == "1:1" ]] && pass "the pasted span is selected (frames 5-6 of X)" || fail "paste selection: $(kc_s)"
    kc_key ctrl+z
    [[ "$LLN" == "1=0:0:0,3:6:0 2=0:0:0,2:0:0" ]] && pass "Ctrl+Z: the paste gone" || fail "undo paste: $(kc_s)"

    # -- Delete on frames 3-4 of X + Y --
    kc_key Escape
    kc_drag "$(kc_fmid 3)" "$XY" "$(kc_fmid 4)" "$YY"
    kc_key Delete
    [[ "$LLN" == "1=0:0:0 2=0:0:0" && "$S_ON" == 1 ]] && pass "Delete: X's key on 4 and Y's on 3 gone (the selection stays)" || fail "delete: $(kc_s)"
    kc_key ctrl+z
    [[ "$LLN" == "1=0:0:0,3:6:0 2=0:0:0,2:0:0" ]] && pass "one Ctrl+Z puts both back" || fail "undo delete: $(kc_s)"

    # -- Ctrl+X on frames 3-4 of X (a box starts on empty lane space: a press on a key drags the key) --
    kc_key Escape
    kc_drag "$(kc_fmid 3)" "$XY" "$(kc_fmid 4)" $(( XY + 3 ))
    kc_key ctrl+x
    [[ "$LLN" == "1=0:0:0 2=0:0:0,2:0:0" && "$CB_K" == "1=0:4,1:6" ]] && pass "Ctrl+X on frames 3-4 of X: copied (4 baked, 6) and the key on 4 gone" || fail "cut: $(kc_s)"
    kc_key ctrl+z
    [[ "$LLN" == "1=0:0:0,3:6:0 2=0:0:0,2:0:0" ]] && pass "Ctrl+Z: the cut key back" || fail "undo cut: $(kc_s)"

    # -- onto another layer: frames 1-5 of X + Y copied, a new layer, Ctrl+V at frame 1 --
    kc_key Escape
    kc_drag "$(kc_fmid 5)" "$XY" "$(kc_fmid 1)" "$YY"
    kc_key ctrl+c
    [[ "$CB_N" == 2 && "$CB_W" == 5 && "$CB_K" == "1=0:0,3:6,4:6 2=0:0,2:0,4:0" ]] && pass "Ctrl+C on frames 1-5 of X + Y (frame 5 baked)" || fail "copy 1-5: $(kc_s)"
    kc_hclick "$(kc_fmid 1)" $(( YY + 4 )); kc_read
    kc_key Escape
    kc_key ctrl+shift+n
    kc_key ctrl+v
    [[ "$LLNS" == *"1=0:0:0,3:6:0 2=0:0:0,2:0:0|"* && "$(echo "$LLNS" | tr '|' '\n' | grep -c '^[0-9]* 1=0:0:0,3:6:0,4:6:0 2=0:0:0,2:0:0,4:0:0$')" == 1 ]] \
        && pass "a new layer, Ctrl+V at frame 1: its X and Y lanes get the keys, layer 1 unchanged" || fail "paste to another layer: $(kc_s)"
    screenshot "lane-key-clipboard"
    kc_key ctrl+z
    [[ "$(echo "$LLNS" | grep -o '|' | wc -l)" == 1 ]] && pass "Ctrl+Z: the new layer's lane gone" || fail "undo paste on the new layer: $(kc_s)"

    # -- a pixel copy takes Ctrl+V back --
    kc_key Escape
    kc_key ctrl+c
    [[ "$CB_LAST" == 0 && "$CB_N" == 2 ]] && pass "Ctrl+C with no key selection copies pixels: they are the newest copy (keys kept)" || fail "pixel copy: $(kc_s)"
fi
assert_no_crash
rm -rf "$KC_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
