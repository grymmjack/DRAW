#!/bin/bash
# =============================================================================
# anim-lightbox-effect-centre.sh — QA test: in the lightbox a centred effect
# (Twirl, Pinch ...) is centred on the frame it is applied to (Rick
# 2026-11-09: "anything that uses the canvas needs to consider lightbox mode").
#
# Frames 1 and 3 hold the same picture, so the effect applied to frame 1 and
# (separately) to frame 3 must give the same result when each frame is its
# own canvas. The old build centred every effect on the sheet's middle, so
# frame 1 and frame 3 turned out differently.
#
# Dump: ANIMC (a CRC per frame cell), ANIM (count, current).
# Fixture: a 128x32 sheet of 32x32 frames: frames 1 and 3 an L shape + a dot,
# frames 2 and 4 a square.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: centred effects centre on the frame ==="

LE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LE_DIR="/tmp/draw-qa-lbfx-$$"
mkdir -p "$LE_DIR"
magick -size 32x32 xc:none -fill '#c04040' -draw 'rectangle 4,4 9,27' -draw 'rectangle 4,22 27,27' \
    -fill '#40c040' -draw 'rectangle 18,6 25,13' "PNG32:$LE_DIR/a.png"
magick -size 32x32 xc:none -fill '#4040c0' -draw 'rectangle 8,8 23,23' "PNG32:$LE_DIR/b.png"
magick "$LE_DIR/a.png" "$LE_DIR/b.png" "$LE_DIR/a.png" "$LE_DIR/b.png" +append "PNG32:$LE_DIR/plain.png"
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

le_fx() { # NAME - apply the effect NAME (palette, then OK) to frame 1, then to frame 3: the same result
    local c1
    le_pick 1
    le_palette "$1"; wait_for 0.6 "$1 dialog"
    key Return; wait_for 1.0 "$1 applied"; le_read
    c1=${T[1]}
    if [[ "$c1" == "${T0[1]}" ]] || ! le_others 1; then
        fail "$1 in frame 1: cells $(le_cells) (T0 ${T0[*]:1})"; le_key ctrl+z; return
    fi
    le_key ctrl+z; le_read
    le_is "1 2 3 4" || fail "undo $1 in frame 1: cells $(le_cells)"
    le_pick 3
    le_palette "$1"; wait_for 0.6 "$1 dialog"
    key Return; wait_for 1.0 "$1 applied"; le_read
    [[ "${T[3]}" == "$c1" ]] && le_others 3 && pass "$1 on frame 1 and on frame 3 (the same picture): the same result - each centred on its own frame" || fail "$1 in frame 3: ${T[3]}, frame 1 gave $c1 (cells $(le_cells), T0 ${T0[*]:1})"
    le_key ctrl+z; le_read
    le_is "1 2 3 4" || fail "undo $1 in frame 3: cells $(le_cells)"
}

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
T0=(x $A_T)
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 4 || "${T0[1]}" != "${T0[3]}" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames, T0 ${T0[*]:1}"
else
    pass "lightbox shown, 4 frames"
    le_fx "twirl"
    le_fx "pinch / bulge"
    screenshot "anim-lightbox-effect-centre"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LE_DIR"
assert_window_exists
