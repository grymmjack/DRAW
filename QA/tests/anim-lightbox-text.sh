#!/bin/bash
# =============================================================================
# anim-lightbox-text.sh — QA test: in the lightbox New Text Layer starts at the
# current frame's centre and the text wraps at that frame's right edge (Rick
# 2026-11-09: "anything that uses the canvas needs to consider lightbox mode").
#
# The old build started the text at the sheet's centre (another frame) and
# wrapped it at the sheet's right edge, running across the frames.
#
# Dump: ANIMTX startX startY x y w h (the current text layer: its start, then
# its pixels' bounds), ANIM (count, current).
# Fixture: a 128x32 sheet of 32x32 frames, empty; frame 2's cell is x 32-63.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: a new text layer starts and wraps in the current frame ==="

LE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LE_DIR="/tmp/draw-qa-lbtext-$$"
mkdir -p "$LE_DIR"
magick -size 128x32 xc:none -fill '#ff0000' -draw 'point 0,0' "PNG32:$LE_DIR/plain.png"
LE_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,32,32,0,0,4,1,12,0,0).hex())")
python3 "$LE_PY" put "$LE_DIR/plain.png" "$LE_DIR/sheet.png" drAn "$LE_BLOB"

le_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
le_line() { grep -m1 "^$1 " "$LE_DUMP" 2>/dev/null; }
le_read() {
    le_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(le_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(le_line ANIMC)"; T=(x $A_T)
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(le_line ANIMLB)"
    local p k; p=($(le_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
le_cells() { echo "${T[*]:1}"; }
le_is() { local want=($1) k; for k in 1 2 3 4; do [[ "${T[$k]}" == "${T0[${want[$((k - 1))]}]}" ]] || return 1; done; }
le_others() { # FRAME: every other frame still holds its own picture
    local k; for k in 1 2 3 4; do [[ $k == "$1" ]] && continue; [[ "${T[$k]}" == "${T0[$k]}" ]] || return 1; done
}
le_pick() { # FRAME - Num 5 (next frame) until it is current (the strip may be hidden behind the X-sheet)
    local n; le_read
    for (( n = 0; n < 5 && A_CUR != $1; n++ )); do le_key KP_5; le_read; done
}
le_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); }
le_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
le_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
le_palette() { park_mouse; key question; wait_for 1.0 "Command palette"; type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"; }


info "Launching DRAW with the 4-frame sheet"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LE_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
le_read
[[ "${LB_SHOWN:-}" == -1 ]] || { le_key KP_0; le_read; }
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 4 ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames"
else
    pass "lightbox shown, 4 frames"
    le_pick 2
    le_palette "new text layer"
    type_text "WWWWWWWWWWWW"
    wait_for 0.6 "typed"
    le_key Escape; le_read
    read -r _ TX_SX TX_SY TX_X TX_Y TX_W TX_H _ <<< "$(le_line ANIMTX)"
    if [[ -z "${TX_SX:-}" ]]; then
        fail "no text layer after New Text Layer + typing (ANIMTX '$(le_line ANIMTX)')"
    else
        [[ "$TX_SX" == 48 && "$TX_SY" == 16 ]] && pass "New Text Layer in frame 2: starts at the frame's centre (48, 16)" || fail "text start ($TX_SX, $TX_SY), wanted frame 2's centre (48, 16)"
        [[ "$TX_W" -gt 0 && "$TX_X" -ge 32 && $(( TX_X + TX_W )) -le 64 ]] && pass "12 Ws wrap at frame 2's right edge: the text stays in x 32-63 (x $TX_X w $TX_W)" || fail "text pixels x $TX_X w $TX_W, wanted inside frame 2 (x 32-63)"
    fi
    screenshot "anim-lightbox-text"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LE_DIR"
assert_window_exists
