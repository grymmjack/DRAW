#!/bin/bash
# =============================================================================
# anim-lightbox-canvas.sh — QA test: in the lightbox the current frame is the
# canvas (Rick 2026-11-09: "the align, distribute, and smart guides need to
# work on the current frame when in lightbox mode" / "same with any
# transforms like scale, rotate" / "anything that uses the canvas needs to
# consider lightbox mode").
#
# Align (Layer > Align) lines a drawing up with its frame's cell, in each
# selected frame; the Transform tool takes only the current frame's drawing
# and keeps the result in its cell; the pane Move tool snaps to the frame's
# edges with smart guides on. Each is one undo step. The old build aligned /
# transformed the whole layer (every frame at once, against the sheet's
# edges) and the pane Move tool had no smart guides.
#
# Dump: ANIMC (a CRC per frame cell), ANIMLB (the strip), ANIMLBP (panes).
# Fixture: an 80x16 sheet of 16x16 frames, transparent: frame 1 a shape A
# (bounds 2,2 - 9,9), frame 2 = A against the right edge (+6, 0), frame 3 =
# A centred across (+2, 0), frame 4 = A against the bottom (0, +6), frame 5
# = A against the right and top edges (+6, -2) - so a right / centre /
# bottom alignment of frame 1 is the very picture of frame 2 / 3 / 4, and a
# move 5 px right (the guides pull it 1 right and, 2 px from the top, 2 up)
# is frame 5's (the checks compare cell CRCs).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 SMART_GUIDES_ENABLED=TRUE SMART_GUIDES_SNAP=TRUE
# =============================================================================
info "=== Animation: the current frame is the canvas in the lightbox ==="

LC_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LC_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LC_DIR="/tmp/draw-qa-lbcanvas-$$"
mkdir -p "$LC_DIR"
magick -size 16x16 xc:none -fill '#c04040' -draw 'rectangle 2,2 3,9' -draw 'rectangle 2,8 9,9' \
    -fill '#40c040' -draw 'rectangle 6,3 7,4' "PNG32:$LC_DIR/a.png"
magick "$LC_DIR/a.png" -roll +6+0 "PNG32:$LC_DIR/b.png"
magick "$LC_DIR/a.png" -roll +2+0 "PNG32:$LC_DIR/c.png"
magick "$LC_DIR/a.png" -roll +0+6 "PNG32:$LC_DIR/d.png"
magick "$LC_DIR/a.png" -roll +6-2 "PNG32:$LC_DIR/e.png"
magick "$LC_DIR/a.png" "$LC_DIR/b.png" "$LC_DIR/c.png" "$LC_DIR/d.png" "$LC_DIR/e.png" +append "PNG32:$LC_DIR/plain.png"
LC_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,5,1,12,0,0).hex())")
python3 "$LC_PY" put "$LC_DIR/plain.png" "$LC_DIR/sheet.png" drAn "$LC_BLOB"

lc_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
lc_line() { grep -m1 "^$1 " "$LC_DUMP" 2>/dev/null; }
lc_read() { # A_COUNT A_CUR, T[1..4], LB_* (strip), the current pane PX PY PW PH
    lc_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(lc_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(lc_line ANIMC)"; T=(x $A_T)
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(lc_line ANIMLB)"
    local p k; p=($(lc_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
lc_cells() { echo "${T[*]:1}"; }
lc_is() { # "a b c d": cell k must hold frame (a b c d)'s original picture
    local want=($1) k
    for k in 1 2 3 4; do [[ "${T[$k]}" == "${T0[${want[$((k - 1))]}]}" ]] || return 1; done
}
lc_cx() { echo $(( LB_X1 + LB_PAD + ($1 - LB_SF) * (LB_CW + LB_PAD) + LB_CW / 2 )); }
lc_cy() { echo $(( LB_SY + LB_PAD + LB_CH / 2 )); }
lc_pick() { # F [ctrl] - click frame F in the strip
    lc_read
    if [[ "${2:-}" == ctrl ]]; then with_mods ctrl click "$(lc_cx "$1")" "$(lc_cy)"; else click "$(lc_cx "$1")" "$(lc_cy)"; fi
    wait_for 0.4 "strip frame $1"; lc_read
}
lc_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); } # screen x / y of cell pixel (CX, CY) in the current pane
lc_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
lc_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
lc_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}

info "Launching DRAW with the 5-frame sheet"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LC_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
lc_read
[[ "${LB_SHOWN:-}" == -1 ]] || { lc_key KP_0; lc_read; } # (a profile may have it on already)
T0=(x $A_T)
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 5 || -z "${PX:-}" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames, current pane '${PX:-}'"
else
    pass "lightbox shown, 5 frames"

    # -- align: inside frame 1's cell, the other frames untouched --
    lc_pick 1
    lc_palette "align right"; lc_read
    lc_is "2 2 3 4" && pass "Align Right in frame 1: against the frame's right edge (= frame 2), the rest unchanged" || fail "align right: cells $(lc_cells), wanted T0 frames 2 2 3 4"
    lc_key ctrl+z; lc_read
    lc_is "1 2 3 4" && pass "undo: one step" || fail "undo align right: cells $(lc_cells)"
    lc_palette "align center h"; lc_read
    lc_is "3 2 3 4" && pass "Align Center H in frame 1: centred across the frame (= frame 3)" || fail "align center h: cells $(lc_cells), wanted T0 frames 3 2 3 4"
    lc_key ctrl+z; lc_read
    lc_pick 4 ctrl
    lc_palette "align bottom"; lc_read
    lc_is "4 2 3 4" && pass "frames 1 + 4 selected, Align Bottom: each against its own frame's bottom" || fail "align bottom 1 + 4: cells $(lc_cells), wanted T0 frames 4 2 3 4"
    lc_key ctrl+z; lc_read
    lc_is "1 2 3 4" || fail "undo align bottom: cells $(lc_cells)"

    # -- the Transform tool: frame 1's drawing only, kept in its cell --
    lc_pick 1
    lc_palette "transform rotate"; lc_read
    lc_key greater
    lc_key Return; lc_read
    [[ "${T[1]}" != "${T0[1]}" && "${T[2]}" == "${T0[2]}" && "${T[3]}" == "${T0[3]}" && "${T[4]}" == "${T0[4]}" ]] \
        && pass "Transform Rotate, > (90), Enter in frame 1: frame 1 turns, frames 2-4 untouched" || fail "transform frame 1: cells $(lc_cells) (T0 ${T0[*]:1})"
    lc_key ctrl+z; lc_read
    lc_is "1 2 3 4" && pass "undo the transform" || fail "undo the transform: cells $(lc_cells)"

    # -- the pane Move tool with smart guides: 5 px right snaps onto the frame's right edge (6) and top (-2) --
    lc_pick 1
    lc_key v
    LC_X=$(lc_px 5); LC_Y=$(lc_py 6)
    hover "$LC_X" "$LC_Y"; sleep 0.3
    mouse_down "$LC_X" "$LC_Y"
    hover $(( LC_X + 2 * PW / 16 )) "$LC_Y"; sleep 0.2
    hover $(( LC_X + 4 * PW / 16 )) "$LC_Y"; sleep 0.2
    hover $(( LC_X + 5 * PW / 16 )) "$LC_Y"; sleep 0.4
    mouse_up; wait_for 0.6 "move released"
    lc_read
    [[ "${T[1]}" == "${T0[5]}" && "${T[2]}" == "${T0[2]}" && "${T[3]}" == "${T0[3]}" && "${T[4]}" == "${T0[4]}" ]] \
        && pass "Move tool, 5 px right in frame 1's pane: the smart guides pull it onto the frame's right and top edges (= frame 5)" \
        || fail "move with smart guides: cells $(lc_cells), wanted frame 1 = T0 frame 5 (T0 ${T0[*]:1}; $(lc_line ANIMCV))"
    lc_key ctrl+z; lc_read
    lc_is "1 2 3 4" || fail "undo the move: cells $(lc_cells)"
    screenshot "anim-lightbox-canvas"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LC_DIR"
assert_window_exists
