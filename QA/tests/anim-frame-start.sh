#!/bin/bash
# =============================================================================
# anim-frame-start.sh — QA test: starting frames on a picture, and changing the
# frame size of a drawn sheet (Animation 1.8, PLANS/ANIMATION.md R-07 / R-08).
#
# - Num + on a plain picture: it becomes frame 1 (frame size = the canvas) and
#   frame 2 (a copy; Shift: blank) goes beside it - the canvas doubles in
#   width. One undo step back to the plain picture.
# - The first frame size change on a drawn sheet asks RE-SLICE (the grid
#   moves, the pixels stay) or RESIZE (the frames resize, each drawing stays in
#   its frame, the canvas refits the same columns x rows); the answer holds for
#   the document. An empty sheet just re-slices. Every layout / timing change
#   in the panel is an undo step; a held stepper is one.
#
# Dump: ANIM (… canvasW canvasH at the end), ANIMC (a CRC per frame cell),
# ANIMP (… sizeMode pendRow), ANIMPL (… ops mode rows).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: starting frames, re-slice / resize ==="

FS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
FS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
FS_DIR="/tmp/draw-qa-framestart-$$"
mkdir -p "$FS_DIR"
FS_DRAW=()
FS_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0 e08020)
for n in 0 1 2 3 4 5 6; do # cell n+1 (16x16 grid): a mark of its own
    x=$(( (n % 4) * 16 + 2 )); y=$(( (n / 4) * 16 + 2 ))
    FS_DRAW+=(-fill "#${FS_COLORS[$n]}" -draw "rectangle $x,$y $(( x + 1 + n )),$(( y + 9 ))")
done
magick -size 64x32 xc:none "${FS_DRAW[@]}" "$FS_DIR/plain.png"
magick -size 64x32 xc:none "$FS_DIR/empty0.png"
FS_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$FS_PY" put "$FS_DIR/plain.png" "$FS_DIR/sheet.png" drAn "$FS_BLOB"
python3 "$FS_PY" put "$FS_DIR/empty0.png" "$FS_DIR/empty.png" drAn "$FS_BLOB"

fs_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
fs_line() { grep -m1 "^$1 " "$FS_DUMP" 2>/dev/null; }
fs_read() { # A_ON A_COUNT A_CUR A_FW A_FH A_COLS A_ROWS A_FPS A_CW A_CH, A_T (ANIMC tokens)
    fs_settle
    read -r _ A_ON A_COUNT A_CUR A_FW A_FH _ _ A_COLS A_ROWS A_FPS _ _ _ _ A_CW A_CH _ <<< "$(fs_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(fs_line ANIMC)"
}
fs_panel() {
    fs_settle
    read -r _ P_VIS _ P_X P_Y _ _ P_SC P_HOLD P_MODE P_PEND _ <<< "$(fs_line ANIMP)"
    read -r _ _ L_R1 L_R2 L_R3 L_R4 L_R5 L_R6 _ L_RH L_MX L_PX L_CW L_PAD L_PW _ L_MODE _ <<< "$(fs_line ANIMPL)"
}
fs_vx() { echo $(( P_X + $1 * P_SC / 100 )); }
fs_vy() { echo $(( P_Y + $1 * P_SC / 100 )); }
fs_step() { # ROW minus|plus [hold]
    fs_panel
    local v="L_R$1" nx; [[ "$2" == minus ]] && nx=$L_MX || nx=$L_PX
    local x y; x=$(fs_vx $(( nx + L_CW / 2 ))); y=$(fs_vy $(( ${!v} + L_RH / 2 )))
    if [[ "${3:-}" == hold ]]; then mouse_down "$x" "$y"; sleep 1.0; mouse_up; else click "$x" "$y"; fi
    wait_for 0.4 "stepper $1 $2"
}
fs_mode() { # 0 RE-SLICE | 1 RESIZE
    fs_panel
    local cw=$(( (L_PW - 2 * L_PAD - 2) / 2 ))
    click "$(fs_vx $(( L_PAD + $1 * (cw + 2) + cw / 2 )))" "$(fs_vy $(( L_MODE + L_RH / 2 )))"
    wait_for 0.4 "mode $1"
}
fs_cmd() { # NAME (command palette)
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 0.6 "$1"
}
fs_open_panel() {
    local try
    for try in 1 2; do
        fs_cmd "animation panel"; fs_panel
        [[ "$P_VIS" == -1 ]] && return 0
        key Escape; wait_for 0.3 "Escape"
    done
}
fs_launch() { # FILE
    draw_quit
    draw_settle # a small file loads fast enough to race the old window (see draw_settle)
    DRAW_EXTRA_ARGS="$1"
    draw_launch 15
    wait_for 2.5 "Loaded"
    assert_no_crash
    park_mouse
    key ctrl+0
    wait_for 0.5 "Zoom 100%"
}

# -- a plain picture: Num + makes it frame 1, frame 2 beside it --
info "Launching DRAW with a plain 64x32 picture"
fs_launch "$FS_DIR/plain.png"
fs_read
[[ "$A_ON" == 0 && "$A_CW" == 64 ]] && pass "a plain 64x32 picture, no frames" || fail "start: frames on=$A_ON canvas ${A_CW}x$A_CH"
park_mouse; key KP_Add; wait_for 0.6 "Num +"
fs_read
read -r FS_T1 FS_T2 _ <<< "$A_T"
[[ "$A_ON" == -1 && "$A_FW" == 64 && "$A_FH" == 32 && "$A_COUNT" == 2 && "$A_CUR" == 2 ]] \
    && pass "Num +: the picture is frame 1 (64x32), frame 2 added and current" \
    || fail "Num + on a plain picture: on=$A_ON ${A_FW}x$A_FH count $A_COUNT current $A_CUR"
[[ "$A_CW" == 128 && "$A_CH" == 32 && "$A_COLS" == 2 ]] && pass "the canvas doubled in width: frame 2 beside frame 1" \
    || fail "canvas ${A_CW}x$A_CH cols $A_COLS, wanted 128x32 / 2"
[[ -n "${FS_T1:-}" && "$FS_T1" != 0 && "$FS_T2" == "$FS_T1" ]] && pass "frame 2 is a copy of the picture" \
    || fail "frames [$A_T]: frame 2 not a copy of frame 1"
park_mouse; key ctrl+z; wait_for 0.6 "Undo"
fs_read
[[ "$A_ON" == 0 && "$A_CW" == 64 ]] && pass "one undo: the plain picture again" || fail "after undo: frames on=$A_ON canvas ${A_CW}x$A_CH"
park_mouse; key shift+KP_Add; wait_for 0.6 "Shift+Num +"
fs_read
read -r FS_T1 FS_T2 _ <<< "$A_T"
[[ "$A_COUNT" == 2 && "$FS_T1" != 0 && "$FS_T2" == 0 ]] && pass "Shift+Num +: frame 2 blank" || fail "Shift+Num + on a plain picture: count $A_COUNT frames [$A_T]"

# -- a drawn sheet: the first size change asks --
info "Relaunching with the drawn sheet (16x16 frames, 7)"
fs_launch "$FS_DIR/sheet.png"
fs_read; FS_BASE="$A_T"
fs_open_panel
fs_step 1 plus; fs_read; fs_panel
[[ "$A_FW" == 16 && "$P_PEND" == 1 && "$P_MODE" == 0 ]] && pass "W + on a drawn sheet waits: re-slice or resize?" \
    || fail "W + on a drawn sheet: W $A_FW waiting '$P_PEND' mode '$P_MODE' (wanted 16 / 1 / 0)"
screenshot "anim-frame-start-ask"
fs_mode 1; fs_read; fs_panel
[[ "$A_FW" == 17 && "$P_MODE" == 2 && "$P_PEND" == 0 ]] && pass "RESIZE: the waiting W + goes through, remembered" \
    || fail "after RESIZE: W $A_FW mode $P_MODE waiting $P_PEND (wanted 17 / 2 / 0)"
[[ "$A_CW" == 68 && "$A_CH" == 32 && "$A_COLS" == 4 && "$A_ROWS" == 2 && "$A_COUNT" == 7 ]] \
    && pass "resize: the canvas refits 4 x 2 frames of 17x16 (68x32), 7 frames" \
    || fail "resize: canvas ${A_CW}x$A_CH ${A_COLS}x$A_ROWS count $A_COUNT (wanted 68x32 4x2 7)"
FS_UNIQ=$(tr ' ' '\n' <<< "$A_T" | grep -v '^0$' | sort -u | wc -l)
[[ "$FS_UNIQ" == 7 ]] && pass "every frame kept its own drawing" || fail "after resize: $FS_UNIQ distinct drawn frames [$A_T]"
fs_step 1 minus; fs_read; fs_panel
[[ "$A_FW" == 16 && "$A_CW" == 64 && "$A_T" == "$FS_BASE" && "$P_PEND" == 0 ]] \
    && pass "W - (no question now): back to 16, every drawing where it was" \
    || fail "W - after resize: W $A_FW canvas $A_CW waiting $P_PEND frames [$A_T] vs [$FS_BASE]"
fs_step 2 plus hold; fs_read
FS_HELD=$A_FH
(( A_FH > 18 )) && pass "H + held repeats in resize mode ($A_FH)" || fail "holding H +: H $A_FH"
park_mouse; key ctrl+z; wait_for 0.6 "Undo"
fs_read
[[ "$A_FH" == 16 && "$A_CH" == 32 && "$A_T" == "$FS_BASE" ]] && pass "one undo takes the whole hold back (H $FS_HELD -> 16)" \
    || fail "undo after the held H +: H $A_FH canvas $A_CH frames [$A_T]"
park_mouse; key ctrl+z; wait_for 0.6 "Undo"
park_mouse; key ctrl+z; wait_for 0.6 "Undo"
fs_read
[[ "$A_FW" == 16 && "$A_CW" == 64 && "$A_T" == "$FS_BASE" ]] && pass "undo the two resizes: the sheet as loaded" \
    || fail "after undoing the resizes: W $A_FW canvas $A_CW frames [$A_T]"

# re-slice: the grid moves over the pixels
fs_mode 0
fs_step 1 plus; fs_read
[[ "$A_FW" == 17 && "$A_CW" == 64 && "$A_COLS" == 3 ]] && pass "RE-SLICE: W 17 over the same 64 px (3 columns)" \
    || fail "re-slice W +: W $A_FW canvas $A_CW cols $A_COLS (wanted 17 / 64 / 3)"
park_mouse; key ctrl+z; wait_for 0.6 "Undo"
fs_read
[[ "$A_FW" == 16 && "$A_COLS" == 4 && "$A_COUNT" == 7 ]] && pass "a re-slice is an undo step" || fail "undo re-slice: W $A_FW cols $A_COLS count $A_COUNT"

# timing is an undo step too
fs_step 5 plus; fs_read; FS_F1=$A_FPS
park_mouse; key ctrl+z; wait_for 0.6 "Undo"
fs_read
[[ "$FS_F1" == 13 && "$A_FPS" == 12 ]] && pass "FPS + and its undo (13 -> 12)" || fail "FPS: $FS_F1 after +, $A_FPS after undo (wanted 13 / 12)"

# -- an empty sheet just re-slices --
info "Relaunching with an empty sheet"
fs_launch "$FS_DIR/empty.png"
fs_open_panel
fs_step 1 plus; fs_read; fs_panel
[[ "$A_FW" == 17 && "$P_PEND" == 0 && "$A_CW" == 64 ]] && pass "an empty sheet: W + re-slices without asking" \
    || fail "empty sheet W +: W $A_FW waiting $P_PEND canvas $A_CW (wanted 17 / 0 / 64)"
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$FS_DIR"
assert_window_exists
