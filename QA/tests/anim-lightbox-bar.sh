#!/bin/bash
# =============================================================================
# anim-lightbox-bar.sh — QA test: the lightbox transport bar (Animation 2.4,
# TOOLS/ANIM-LB).
#
# LOOP opens a menu of the four loop modes. The FPS spinner steps on a click
# at its - / + ends (Shift: 10) and with the wheel; each change is an undo
# step. Pressing / dragging on the seek bar scrubs the current frame. The
# count box takes typing: "5" goes to frame 5, "5/9" makes 9 frames, "/5"
# drops the last frames - and when they hold drawings it asks first (Enter =
# drop them, Esc = keep them; R-16). While typing, keys reach nothing else.
#
# Dump: ANIM (fps, loop mode); ANIMC (a CRC per frame cell); ANIMLB /
# ANIMLBC (layout, control x / w); ANIMLBE editing confirmTo menuOpen
# menuHover seekHeld menuX menuY menuW text.
# Fixture: a 64x32 sheet of 16x16 frames, 7 frames (each with a mark),
# current 3, 12 fps.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: the lightbox transport bar ==="

LT_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LT_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LT_DIR="/tmp/draw-qa-lbbar-$$"
mkdir -p "$LT_DIR"
LT_DRAW=()
LT_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0 e08020)
for n in 0 1 2 3 4 5 6; do
    x=$(( (n % 4) * 16 + 2 )); y=$(( (n / 4) * 16 + 2 ))
    LT_DRAW+=(-fill "#${LT_COLORS[$n]}" -draw "rectangle $x,$y $(( x + 1 + n )),$(( y + 9 ))")
done
magick -size 64x32 xc:none "${LT_DRAW[@]}" "$LT_DIR/plain.png"
LT_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$LT_PY" put "$LT_DIR/plain.png" "$LT_DIR/sheet.png" drAn "$LT_BLOB"

lt_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
lt_line() { grep -m1 "^$1 " "$LT_DUMP" 2>/dev/null; }
lt_read() { # A_COUNT A_CUR A_FPS A_LOOP, A_T; LB_*; C_X[k] C_W[k]; E_*
    lt_settle
    read -r _ _ A_COUNT A_CUR _ _ _ _ _ _ A_FPS A_LOOP _ <<< "$(lt_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(lt_line ANIMC)"
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH _ <<< "$(lt_line ANIMLB)"
    local c k; c=($(lt_line ANIMLBC)); C_X=(); C_W=()
    for k in $(seq 1 14); do C_X[$k]=${c[$((2 * k - 1))]:-0}; C_W[$k]=${c[$((2 * k))]:-0}; done
    read -r _ E_EDIT E_CONF E_MENU E_HOVER E_SEEK E_MX E_MY E_MW E_TEXT _ <<< "$(lt_line ANIMLBE)"
}
lt_raw() { # the dump's ANIM current / ANIMLBE without moving the pointer (mid-gesture)
    read -r _ _ _ R_CUR _ <<< "$(lt_line ANIM)"
    read -r _ R_EDIT R_CONF R_MENU _ R_SEEK _ <<< "$(lt_line ANIMLBE)"
}
lt_ctl() { click $(( C_X[$1] + C_W[$1] / 2 )) $(( LB_BY + LB_BH / 2 )); wait_for 0.4 "control $1"; }
lt_key() { park_mouse; key "$1"; wait_for 0.4 "$1"; }
LT_BAR_Y() { echo $(( LB_BY + LB_BH / 2 )); }

info "Launching DRAW with a 64x32 sheet of 16x16 frames (7, current 3, 12 fps)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LT_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
lt_key KP_0
lt_read
LT_T0="$A_T"
if [[ "${LB_SHOWN:-}" != -1 || -z "${E_EDIT:-}" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', bar state line '${E_EDIT:-}'"
else
    pass "lightbox shown; loop $A_LOOP, $A_FPS fps, frame $A_CUR of $A_COUNT"
    for k in 6 8 9 10; do (( C_W[$k] > 0 )) || info "control $k is dropped at this width"; done

    # -- LOOP: a menu of the loop modes --
    if (( C_W[6] > 0 )); then
        lt_ctl 6; lt_read
        [[ "$E_MENU" == -1 ]] && pass "LOOP opens the loop mode menu" || fail "LOOP click: menu '$E_MENU'"
        click $(( E_MX + E_MW / 2 )) $(( E_MY + 2 + 2 * 12 + 6 )); wait_for 0.4 "pick Ping-pong"
        lt_read
        [[ "$E_MENU" == 0 && "$A_LOOP" == 2 ]] && pass "picking Ping-pong sets it and closes the menu" || fail "menu pick: menu '$E_MENU' loop '$A_LOOP' (wanted 0 / 2)"
        lt_ctl 6; lt_read
        click $(( LB_X1 + 4 )) $(( LB_Y2 - 4 )); wait_for 0.4 "click away"
        lt_read
        [[ "$E_MENU" == 0 && "$A_LOOP" == 2 && "$A_T" == "$LT_T0" ]] && pass "a click away closes it: nothing changes, nothing drawn" \
            || fail "click away: menu '$E_MENU' loop '$A_LOOP', frames changed: $([[ "$A_T" == "$LT_T0" ]] && echo no || echo yes)"
    fi

    # -- the FPS spinner --
    if (( C_W[8] > 0 )); then
        LT_FL=$(( C_X[8] + 3 )); LT_FR=$(( C_X[8] + C_W[8] - 4 ))
        click "$LT_FR" "$(LT_BAR_Y)"; wait_for 0.3 "fps +"; lt_read
        [[ "$A_FPS" == 13 ]] && pass "FPS +: 13" || fail "FPS + from 12: $A_FPS"
        click "$LT_FL" "$(LT_BAR_Y)"; wait_for 0.3 "fps -"; click "$LT_FL" "$(LT_BAR_Y)"; wait_for 0.3 "fps -"; lt_read
        [[ "$A_FPS" == 11 ]] && pass "FPS - twice: 11" || fail "FPS - - from 13: $A_FPS"
        with_mods shift click "$LT_FR" "$(LT_BAR_Y)"; wait_for 0.3 "shift fps +"; lt_read
        [[ "$A_FPS" == 21 ]] && pass "Shift+click FPS +: 21" || fail "Shift FPS + from 11: $A_FPS"
        scroll_up $(( C_X[8] + C_W[8] / 2 )) "$(LT_BAR_Y)"; wait_for 0.4 "wheel up"; lt_read
        [[ "$A_FPS" == 22 ]] && pass "wheel up over FPS: 22" || fail "wheel over FPS from 21: $A_FPS"
        lt_key ctrl+z; lt_read
        [[ "$A_FPS" == 21 ]] && pass "undo: 21 (each change one step)" || fail "undo FPS: $A_FPS"
        lt_key ctrl+z; lt_key ctrl+z; lt_key ctrl+z; lt_key ctrl+z; lt_read
        [[ "$A_FPS" == 12 ]] && pass "undo all the way: 12" || fail "undo FPS to the start: $A_FPS"
    fi

    # -- scrubbing the seek bar --
    LT_SX=${C_X[9]}; LT_SW=${C_W[9]}
    click $(( LT_SX + LT_SW / 2 )) "$(LT_BAR_Y)"; wait_for 0.4 "seek middle"; lt_read
    [[ "$A_CUR" == 4 ]] && pass "a click mid seek bar: frame 4" || fail "seek click mid: frame $A_CUR"
    mouse_down $(( LT_SX + 1 )) "$(LT_BAR_Y)"
    hover $(( LT_SX + 2 )) "$(LT_BAR_Y)"; sleep 0.3; lt_raw; LT_C1=$R_CUR; LT_H1=$R_SEEK
    hover $(( LT_SX + LT_SW - 2 )) "$(LT_BAR_Y)"; sleep 0.3; hover $(( LT_SX + LT_SW - 3 )) "$(LT_BAR_Y)"; sleep 0.3; lt_raw; LT_C2=$R_CUR
    mouse_up; wait_for 0.4 "seek released"
    lt_read
    [[ "$LT_C1" == 1 && "$LT_H1" == -1 && "$LT_C2" == 7 && "$E_SEEK" == 0 ]] && pass "dragging along the seek bar scrubs frame 1 -> 7, released after" \
        || fail "seek scrub: start $LT_C1 (held $LT_H1), end $LT_C2, after release held '$E_SEEK'"
    [[ "$A_T" == "$LT_T0" ]] && pass "scrubbing draws nothing" || fail "scrubbing drew on the frames"

    # -- the count box --
    if (( C_W[10] > 0 )); then
        lt_ctl 10; lt_read
        [[ "$E_EDIT" == -1 && "$E_TEXT" == "7/7" ]] && pass "click the count box: typing, shows 7/7" || fail "count click: editing '$E_EDIT' text '$E_TEXT'"
        park_mouse; key KP_4; wait_for 0.3 "numpad 4 while typing"; lt_read
        [[ "$A_CUR" == 7 && "$E_TEXT" == 4 ]] && pass "while typing, Num 4 types a 4 (no frame step)" || fail "Num 4 while typing: frame $A_CUR, text '$E_TEXT'"
        key BackSpace; wait_for 0.2 "BackSpace"; lt_read
        [[ "$E_TEXT" == "-" && "$E_EDIT" == -1 ]] && pass "BackSpace deletes it (and reaches nothing else)" || fail "BackSpace while typing: text '$E_TEXT' editing '$E_EDIT'"
        type_text "2"; wait_for 0.2 "2"; key Return; wait_for 0.4 "Enter"; lt_read
        [[ "$A_CUR" == 2 && "$A_COUNT" == 7 && "$E_EDIT" == 0 ]] && pass "typed 2 + Enter: frame 2" || fail "typed 2: frame $A_CUR of $A_COUNT, editing '$E_EDIT'"

        lt_ctl 10; type_text "3/9"; wait_for 0.2 "3/9"; key Return; wait_for 0.6 "Enter"; lt_read
        [[ "$A_COUNT" == 9 && "$A_CUR" == 3 ]] && pass "typed 3/9: 9 frames, on frame 3" || fail "typed 3/9: frame $A_CUR of $A_COUNT"
        lt_key ctrl+z; lt_read
        [[ "$A_COUNT" == 7 && "$A_T" == "$LT_T0" ]] && pass "undo: 7 frames again" || fail "undo 3/9: $A_COUNT frames"

        lt_ctl 10; type_text "/5"; key Return; wait_for 0.5 "Enter"; lt_read
        [[ "$E_CONF" == 5 && "$A_COUNT" == 7 ]] && pass "typed /5: frames 6-7 hold drawings, so it asks first" || fail "typed /5: confirm '$E_CONF', $A_COUNT frames"
        park_mouse; key Escape; wait_for 0.4 "Esc"; lt_read
        [[ "$A_COUNT" == 7 && "$E_EDIT" == 0 && "$A_T" == "$LT_T0" ]] && pass "Esc keeps the frames" || fail "Esc on the question: $A_COUNT frames, editing '$E_EDIT'"
        lt_ctl 10; type_text "/5"; key Return; wait_for 0.4 "Enter"; key Return; wait_for 0.6 "Enter again"; lt_read
        [[ "$A_COUNT" == 5 ]] && pass "Enter on the question drops them: 5 frames" || fail "Enter on the question: $A_COUNT frames"
        lt_key ctrl+z; lt_read
        [[ "$A_COUNT" == 7 && "$A_T" == "$LT_T0" ]] && pass "undo brings frames 6-7 back, drawings and all" || fail "undo /5: $A_COUNT frames, drawings back: $([[ "$A_T" == "$LT_T0" ]] && echo yes || echo no)"

        lt_ctl 10; type_text "6"; park_mouse; key Escape; wait_for 0.4 "Esc"; lt_read
        [[ "$E_EDIT" == 0 && "$A_CUR" != 6 ]] && pass "Esc while typing changes nothing" || fail "Esc while typing: editing '$E_EDIT' frame $A_CUR"
        lt_ctl 10; click $(( LB_X1 + 4 )) $(( LB_Y2 - 4 )); wait_for 0.4 "click away"; lt_read
        [[ "$E_EDIT" == 0 ]] && pass "a click elsewhere ends typing" || fail "click away while typing: editing '$E_EDIT'"
    fi
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LT_DIR"
assert_window_exists
