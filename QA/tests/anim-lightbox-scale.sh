#!/bin/bash
# =============================================================================
# anim-lightbox-scale.sh — QA test: in the lightbox Scale 2x / 2x H / 2x V /
# -50% scale the current frame about its own centre (Rick 2026-11-09:
# "anything that uses the canvas needs to consider lightbox mode").
#
# With no selection, no brush and no floating move, the four scale commands
# work on each selected frame's cell, about the cell's centre; what grows past
# the cell is cut off. One undo step each. The old build scaled the whole
# layer about the sheet's centre (every frame at once, spilling across them).
#
# Dump: ANIMC (a CRC per frame cell), ANIM (count, current).
# Fixture: a 64x16 sheet of 16x16 frames: frame 1 a shape inside the middle
# 8x8 (4,4 - 11,11), frames 2 / 3 / 4 = that shape pixel-doubled 2x / 2x H /
# 2x V about the cell's centre. So 2x / 2x H / 2x V of frame 1 is frame 2 / 3
# / 4's picture, and -50% of frame 2 is frame 1's (the checks compare cell
# CRCs).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: Scale 2x / 2x H / 2x V / -50% on the current frame ==="

LE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LE_DIR="/tmp/draw-qa-lbscale-$$"
mkdir -p "$LE_DIR"
magick -size 16x16 xc:none -fill '#c04040' -draw 'rectangle 4,4 5,11' -draw 'rectangle 4,10 10,11' \
    -fill '#40c040' -draw 'rectangle 8,5 9,6' -fill '#4040c0' -draw 'point 11,4' "PNG32:$LE_DIR/a.png"
magick "$LE_DIR/a.png" -sample 200%x200% -crop 16x16+8+8 +repage "PNG32:$LE_DIR/b.png"
magick "$LE_DIR/a.png" -sample 200%x100% -crop 16x16+8+0 +repage "PNG32:$LE_DIR/c.png"
magick "$LE_DIR/a.png" -sample 100%x200% -crop 16x16+0+8 +repage "PNG32:$LE_DIR/d.png"
magick "$LE_DIR/a.png" "$LE_DIR/b.png" "$LE_DIR/c.png" "$LE_DIR/d.png" +append "PNG32:$LE_DIR/plain.png"
LE_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
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

le_scale() { # KEY LABEL WANT - scale frame 1 with KEY, cells must be WANT; then undo
    le_key "$1"; le_read
    le_is "$3" && pass "$2 in frame 1: about the frame's centre (= frame ${3%% *}), the rest untouched" || fail "$2 in frame 1: cells $(le_cells), wanted T0 frames $3 (T0 ${T0[*]:1})"
    le_key ctrl+z; le_read
    le_is "1 2 3 4" || fail "undo $2: cells $(le_cells)"
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
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 4 ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames"
else
    pass "lightbox shown, 4 frames"
    le_pick 1
    le_scale Prior "Scale 2x (PgUp)" "2 2 3 4"
    le_scale ctrl+Home "Scale 2x H (Ctrl+Home)" "3 2 3 4"
    le_scale ctrl+End "Scale 2x V (Ctrl+End)" "4 2 3 4"
    le_pick 2
    le_key Next; le_read
    le_is "1 1 3 4" && pass "Scale -50% (PgDn) in frame 2: back to frame 1's picture, the rest untouched" || fail "scale -50% in frame 2: cells $(le_cells), wanted T0 frames 1 1 3 4 (T0 ${T0[*]:1})"
    le_key ctrl+z; le_read
    le_is "1 2 3 4" && pass "undo: one step" || fail "undo scale -50%: cells $(le_cells)"
    screenshot "anim-lightbox-scale"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LE_DIR"
assert_window_exists
