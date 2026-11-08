#!/bin/bash
# =============================================================================
# anim-lightbox-onion.sh — QA test: onion skin in the lightbox (Animation 2.6,
# TOOLS/ANIM-LB ANIM_LB_onion; R-09: the lightbox only).
#
# The current pane shows the frames before (red) / after (blue) it over its
# picture, faded. Only pixels that differ from the current frame and from the
# frame's own background show, so the solid background stays clear. Num / and
# ANIM > Onion Skin toggle it, ANIM > Onion Skin Red / Blue Tint the tint; the
# Animation panel's BEFORE / AFTER / OPACITY steppers set it. Hidden while
# playing; frame 1 has nothing before it (no wrap).
#
# Dump: ANIMLBO on before after opacity tint prevPx nextPx; ANIMLBP (per pane
# f dx dy dw dh); ANIMP / ANIMPL (the panel, its rows - the onion rows last).
# Fixture: a 64x32 sheet of 16x16 frames on an opaque #202020 background,
# 5 frames, frame k a 4x4 square at x = 1 + 2(k-1), y 4, each its own colour.
# Current 3. Without the background rule the frame before would show 24
# pixels (its background over frame 3's square), not 16.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: onion skin ==="

LO_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LO_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LO_DIR="/tmp/draw-qa-lbonion-$$"
mkdir -p "$LO_DIR"
LO_DRAW=()
LO_COLORS=(c04040 40c040 4040c0 c0c040 c040c0)
for n in 0 1 2 3 4; do
    x=$(( (n % 4) * 16 + 1 + 2 * n )); y=$(( (n / 4) * 16 + 4 ))
    LO_DRAW+=(-fill "#${LO_COLORS[$n]}" -draw "rectangle $x,$y $(( x + 3 )),$(( y + 3 ))")
done
magick -size 64x32 xc:'#202020' "${LO_DRAW[@]}" "PNG32:$LO_DIR/plain.png"
LO_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,5,3,12,0,0).hex())")
python3 "$LO_PY" put "$LO_DIR/plain.png" "$LO_DIR/sheet.png" drAn "$LO_BLOB"

lo_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
lo_line() { grep -m1 "^$1 " "$LO_DUMP" 2>/dev/null; }
lo_read() { # A_COUNT A_CUR A_PLAY, A_T, O_*, the current pane PX PY PW PH
    lo_settle
    read -r _ _ A_COUNT A_CUR _ _ _ _ _ _ _ _ _ _ _ _ _ A_PLAY _ <<< "$(lo_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(lo_line ANIMC)"
    read -r _ O_ON O_B O_A O_OP O_TINT O_PREV O_NEXT _ <<< "$(lo_line ANIMLBO)"
    local p k; p=($(lo_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
lo_o() { echo "on $O_ON before $O_B after $O_A opacity $O_OP tint $O_TINT shows $O_PREV / $O_NEXT"; }
lo_rgb() { # CX CY - the screen colour "R G B" at cell pixel (CX, CY) of the current pane
    local x y
    x=$(( PX + (2 * $1 + 1) * PW / 32 )); y=$(( PY + (2 * $2 + 1) * PH / 32 ))
    snap_region "$x" "$y" 1 1 "onion_$1_$2" >/dev/null 2>&1
    if [[ -n "${SNAP_RESULT:-}" && -s "$SNAP_RESULT" ]]; then
        magick "$SNAP_RESULT" -scale '1x1!' -format '%[fx:int(255*r+.5)] %[fx:int(255*g+.5)] %[fx:int(255*b+.5)]' info: 2>/dev/null
    else
        echo "0 0 0"
    fi
}
lo_key() { park_mouse; key "$1"; wait_for 0.5 "$1"; }
lo_palette() { # run a command by name through the command palette
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 0.8 "$1"
}

info "Launching DRAW with a 64x32 sheet of 16x16 frames (5, current 3, opaque background)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LO_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
lo_key KP_0
lo_read
LO_T0="$A_T"
if [[ -z "${PX:-}" || -z "${O_ON:-}" ]]; then
    fail "lightbox: no current pane in the dump ('$(lo_line ANIMLBP)') or no onion line"
else
    pass "lightbox shown, current pane at $PX,$PY ${PW}x$PH"

    # -- on by default: 1 before (red), 1 after (blue) --
    [[ "$O_ON" == -1 && "$O_B" == 1 && "$O_A" == 1 && "$O_OP" == 40 && "$O_TINT" == -1 ]] && pass "on by default: 1 before, 1 after, 40%, tinted" || fail "defaults: $(lo_o)"
    [[ "$O_PREV" == 16 && "$O_NEXT" == 16 ]] && pass "frame 3 shows frames 2 and 4: 16 pixels each (their backgrounds left out)" || fail "onion pixels: $(lo_o) (wanted 16 / 16)"
    read -r R G B <<< "$(lo_rgb 3 5)"
    (( R - B > 30 && R - G > 20 )) && pass "where only frame 2 has its square: red ($R $G $B)" || fail "frame 2's ghost: $R $G $B (wanted red)"
    read -r R G B <<< "$(lo_rgb 10 5)"
    (( B - R > 30 )) && pass "where only frame 4 has its square: blue ($R $G $B)" || fail "frame 4's ghost: $R $G $B (wanted blue)"
    read -r R G B <<< "$(lo_rgb 12 12)"
    (( R - B < 10 && B - R < 10 && R < 60 )) && pass "the background stays clear ($R $G $B)" || fail "background under the onion skin: $R $G $B (wanted dark grey)"

    # -- Num / off and on --
    lo_key KP_Divide; lo_read
    read -r R G B <<< "$(lo_rgb 3 5)"
    [[ "$O_ON" == 0 && "$O_PREV" == 0 && "$O_NEXT" == 0 ]] && (( R < 60 && G < 60 && B < 60 )) && pass "Num / turns it off: the ghosts are gone ($R $G $B)" || fail "Num / off: $(lo_o), frame 2's spot $R $G $B"
    [[ "$A_T" == "$LO_T0" && "$A_CUR" == 3 ]] && pass "Num / draws nothing and keeps the frame" || fail "Num / changed frame $A_CUR or the drawings"
    lo_key KP_Divide; lo_read
    [[ "$O_ON" == -1 && "$O_PREV" == 16 ]] && pass "Num / again: back on" || fail "Num / on: $(lo_o)"

    # -- the tint off: frames in their own colours --
    lo_palette "onion skin red"; lo_read
    read -r R G B <<< "$(lo_rgb 3 5)"
    [[ "$O_TINT" == 0 ]] && (( G - R > 30 && G - B > 30 )) && pass "Red / Blue Tint off: frame 2's ghost is its own green ($R $G $B)" || fail "tint off: $(lo_o), frame 2's spot $R $G $B"
    lo_palette "onion skin red"; lo_read
    [[ "$O_TINT" == -1 ]] && pass "and back on" || fail "tint on again: $(lo_o)"

    # -- frame 1: nothing before it; playing: hidden --
    lo_key KP_1; lo_read
    [[ "$A_CUR" == 1 && "$O_PREV" == 0 && "$O_NEXT" == 16 ]] && pass "frame 1: nothing before it (no wrap), frame 2 after" || fail "frame 1: current $A_CUR, $(lo_o)"
    lo_key KP_Enter; lo_read
    LO_PLAYP=$O_PREV; LO_PLAYN=$O_NEXT; LO_PLAY=$A_PLAY
    lo_key KP_Enter; lo_read
    [[ "$LO_PLAY" == -1 && "$LO_PLAYP" == 0 && "$LO_PLAYN" == 0 ]] && pass "hidden while playing" || fail "while playing ($LO_PLAY): shows $LO_PLAYP / $LO_PLAYN"
    lo_key KP_9; lo_key KP_4; lo_key KP_4; lo_read
    [[ "$A_CUR" == 3 ]] || info "back to frame 3: on $A_CUR"

    # -- the Animation panel's steppers --
    lo_palette "animation panel"
    lo_settle
    read -r _ P_VIS _ P_X P_Y _ _ P_SC _ <<< "$(lo_line ANIMP)"
    read -r _ _ _ _ _ _ _ _ _ L_RH L_MX L_PX L_CW _ _ _ _ L_ON L_OB L_OA L_OO _ <<< "$(lo_line ANIMPL)"
    if [[ "$P_VIS" != -1 || -z "${L_OO:-}" ]]; then
        fail "Animation panel: visible '$P_VIS', onion rows '${L_OB:-} ${L_OA:-} ${L_OO:-}'"
    else
        lo_step() { # ROW_Y minus|plus
            local nx=$L_PX; [[ "$2" == minus ]] && nx=$L_MX
            click $(( P_X + (nx + L_CW / 2) * P_SC / 100 )) $(( P_Y + ($1 + L_RH / 2) * P_SC / 100 )); wait_for 0.4 "stepper"
        }
        lo_step "$L_OB" plus; lo_read
        [[ "$O_B" == 2 && "$O_PREV" == 32 ]] && pass "BEFORE +: 2 frames before (frames 1 and 2: 32 pixels)" || fail "BEFORE +: $(lo_o)"
        lo_step "$L_OA" minus; lo_read
        [[ "$O_A" == 0 && "$O_NEXT" == 0 ]] && pass "AFTER -: none after" || fail "AFTER -: $(lo_o)"
        lo_step "$L_OO" plus; lo_read
        [[ "$O_OP" == 45 ]] && pass "OPACITY +: 45%" || fail "OPACITY +: $(lo_o)"
        lo_step "$L_OB" minus; lo_step "$L_OA" plus; lo_step "$L_OO" minus; lo_read
        [[ "$O_B" == 1 && "$O_A" == 1 && "$O_OP" == 40 && "$A_T" == "$LO_T0" ]] && pass "back to 1 / 1 / 40%; the steppers drew nothing" || fail "steppers back: $(lo_o)"
        lo_key ctrl+z; lo_read
        [[ "$O_B" == 1 && "$O_A" == 1 && "$O_OP" == 40 && "$A_T" == "$LO_T0" ]] && pass "onion settings are not undo steps" || fail "ctrl+z after the steppers: $(lo_o)"
    fi
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LO_DIR"
assert_window_exists
