#!/bin/bash
# =============================================================================
# anim-selection-follow.sh — QA test: a selection stays put in its cell across
# frame changes (Animation 2.9, Q-18; TOOLS/ANIM-OPS ANIM_SELBOX_watch).
#
# A selection inside the current frame's cell moves with the current frame -
# frame keys, strip clicks, playback - to the same place in the new frame's
# cell, so Delete / effects then work on that frame. A rectangle and a magic
# wand mask both follow; so does Select All, which in the lightbox is the current
# frame (2026-11-09). A selection over several cells stays.
#
# Dump: ANIMSEL active boxX boxY boxW boxH wand minX minY maxX maxY (canvas
# px), ANIMC (a CRC per frame cell), ANIMLB / ANIMLBP (strip, panes).
# Fixture: a 64x16 sheet of 16x16 frames in one row, transparent, frame k a
# 6x6 square of its own colour at (5, 5). Current 1.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: a selection stays put in its cell ==="

SF_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
SF_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
SF_DIR="/tmp/draw-qa-selfollow-$$"
mkdir -p "$SF_DIR"
SF_DRAW=()
SF_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 5 ))
    SF_DRAW+=(-fill "#${SF_COLORS[$n]}" -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 64x16 xc:none "${SF_DRAW[@]}" "PNG32:$SF_DIR/plain.png"
SF_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
python3 "$SF_PY" put "$SF_DIR/plain.png" "$SF_DIR/sheet.png" drAn "$SF_BLOB"

sf_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
sf_line() { grep -m1 "^$1 " "$SF_DUMP" 2>/dev/null; }
sf_read() { # A_CUR, T[1..4], S_* (ANIMSEL), LB_* (strip), the current pane PX PY PW PH
    sf_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(sf_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(sf_line ANIMC)"; T=(x $A_T)
    read -r _ S_ON S_X S_Y S_W S_H S_WAND S_X1 S_Y1 S_X2 S_Y2 _ <<< "$(sf_line ANIMSEL)"
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(sf_line ANIMLB)"
    local p k; p=($(sf_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
sf_s() { echo "frame ${A_CUR:-?}: sel ${S_ON:-?} box ${S_X:-?},${S_Y:-?} ${S_W:-?}x${S_H:-?} wand ${S_WAND:-?} ${S_X1:-?},${S_Y1:-?}-${S_X2:-?},${S_Y2:-?}"; }
sf_cx() { echo $(( LB_X1 + LB_PAD + ($1 - LB_SF) * (LB_CW + LB_PAD) + LB_CW / 2 )); } # strip cell centre of frame F
sf_cy() { echo $(( LB_SY + LB_PAD + LB_CH / 2 )); }
sf_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); } # screen x / y of cell pixel (CX, CY) in the current pane
sf_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
sf_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
sf_off() { echo $(( S_X - (A_CUR - 1) * 16 )); } # the box's x inside its frame's cell

info "Launching DRAW with a 64x16 sheet of 16x16 frames (4, current 1)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$SF_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
sf_key KP_0
sf_read
T0=(x $A_T)
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 4 || -z "${PX:-}" || -z "${S_ON:-}" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames, current pane '${PX:-}', ANIMSEL '${S_ON:-}'"
else
    pass "lightbox shown, 4 frames, current 1"

    # -- a rectangle in frame 1 --
    sf_key m
    mouse_down "$(sf_px 3)" "$(sf_py 3)"
    hover "$(sf_px 7)" "$(sf_py 7)"; sleep 0.2
    hover "$(sf_px 11)" "$(sf_py 11)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    sf_read
    SF_X0=$S_X; SF_Y0=$S_Y; SF_W0=$S_W; SF_H0=$S_H
    if [[ "$S_ON" != -1 || "$S_X" -lt 0 || $(( S_X + S_W )) -gt 16 || "$S_W" -lt 4 ]]; then
        fail "marquee in frame 1's pane: $(sf_s)"
    else
        pass "a marquee inside frame 1's cell: $(sf_s)"

        sf_key KP_5; sf_read
        [[ "$A_CUR" == 2 && "$S_X" == $(( SF_X0 + 16 )) && "$S_Y" == "$SF_Y0" && "$S_W" == "$SF_W0" && "$S_H" == "$SF_H0" ]] \
            && pass "Num 5: frame 2, the box 16 px right - the same place in frame 2's cell" || fail "next frame: $(sf_s), wanted box at $(( SF_X0 + 16 )),$SF_Y0"
        read -r _ LB_SHOWN _ <<< "$(sf_line ANIMLB)"
        click "$(sf_cx 4)" "$(sf_cy)"; wait_for 0.5 "strip frame 4"; sf_read
        [[ "$A_CUR" == 4 && "$S_X" == $(( SF_X0 + 48 )) && "$S_Y" == "$SF_Y0" ]] && pass "strip click on frame 4: the box follows to frame 4's cell" || fail "strip click 4: $(sf_s)"
        sf_key KP_1; sf_read
        [[ "$A_CUR" == 1 && "$S_X" == "$SF_X0" ]] && pass "Num 1: back in frame 1's cell" || fail "first frame: $(sf_s)"

        # -- what the followed selection works on: Delete in frame 3 --
        sf_key KP_5; sf_key KP_5; sf_read
        sf_key Delete; sf_read
        [[ "$A_CUR" == 3 && "${T[3]}" != "${T0[3]}" && "${T[1]}" == "${T0[1]}" && "${T[2]}" == "${T0[2]}" && "${T[4]}" == "${T0[4]}" ]] \
            && pass "Delete in frame 3: only frame 3's drawing loses the selected part" || fail "delete in frame 3: $(sf_s), cells ${T[*]:1}"
        sf_key ctrl+z; sf_read
        [[ "$A_T" == "${T0[*]:1}" ]] || fail "undo the delete: cells ${T[*]:1}"

        # -- playback: stopped on some frame, the box is in that frame's cell --
        sf_key KP_Enter; sleep 0.8; sf_key KP_Enter; sf_read
        [[ "$(sf_off)" == "$SF_X0" && "$S_Y" == "$SF_Y0" && "$S_ON" == -1 ]] && pass "play + stop on frame $A_CUR: the box is at the same place in its cell" || fail "after playback: $(sf_s), wanted x $SF_X0 inside the cell"
    fi

    # -- Select All spans the cells: it stays --
    sf_key KP_1; sf_key ctrl+a; sf_read
    SF_AX=$S_X; SF_AW=$S_W
    sf_key KP_5; sf_read
    # (in the lightbox Select All is the current frame - 2026-11-09 - so it follows like any one-frame selection)
    [[ "$A_CUR" == 2 && "$S_ON" == -1 && "$SF_AX" == 0 && "$SF_AW" == 16 && "$S_X" == 16 && "$S_W" == 16 ]] && pass "Select All (= frame 1 in the lightbox), then Num 5: the selection moves to frame 2" || fail "select all + next: $(sf_s) (was x $SF_AX w $SF_AW)"
    sf_key ctrl+d

    # -- a magic wand mask follows too --
    sf_key KP_1; sf_read
    sf_key w
    click "$(sf_px 7)" "$(sf_py 7)"; wait_for 0.6 "wand"; sf_read
    SF_WX1=$S_X1; SF_WX2=$S_X2; SF_WY1=$S_Y1
    if [[ "$S_WAND" != -1 || "$S_X1" -lt 0 || "$S_X2" -gt 15 ]]; then
        fail "magic wand in frame 1: $(sf_s)"
    else
        sf_key KP_5; sf_read
        [[ "$A_CUR" == 2 && "$S_WAND" == -1 && "$S_X1" == $(( SF_WX1 + 16 )) && "$S_X2" == $(( SF_WX2 + 16 )) && "$S_Y1" == "$SF_WY1" ]] \
            && pass "a wand selection follows to frame 2 (its mask 16 px right)" || fail "wand + next: $(sf_s), wanted ${SF_WX1}+16..${SF_WX2}+16"
        sf_key Delete; sf_read
        [[ "${T[2]}" != "${T0[2]}" && "${T[1]}" == "${T0[1]}" && "${T[3]}" == "${T0[3]}" ]] && pass "Delete with the moved mask: frame 2 changes, frame 1 does not" || fail "delete with the wand mask: cells ${T[*]:1}"
        sf_key ctrl+z
    fi
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$SF_DIR"
assert_window_exists
