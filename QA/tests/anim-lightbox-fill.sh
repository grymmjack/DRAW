#!/bin/bash
# =============================================================================
# anim-lightbox-fill.sh — QA test: in the lightbox a flood fill and the magic
# wand stop at the edges of the frame clicked in (Rick 2026-11-09: "anything
# that uses the canvas needs to consider lightbox mode").
#
# The flood is bounded by the frame's cell, so it can't run out through a
# neighbouring frame and back in somewhere else. The old build flooded the
# whole sheet: with clip-to-frame on the paint outside the frame was put back,
# but the region it found was wrong, and the wand's selection spanned frames.
#
# Dump: ANIMC (a CRC per frame cell), ANIM (count, current).
# Fixture: a 64x16 sheet of 16x16 frames: frame 1 a red line across (y 8),
# its top and bottom halves both open on the right; frame 2 empty (so the
# halves meet through it); frame 3 = frame 1 with the top half green; frame 4
# a green pixel (to pick the colour). So a fill of frame 1's top half is
# frame 3's picture - the old build filled the bottom half too (it reached
# it round through frame 2).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: flood fill and magic wand stop at the frame's edges ==="

LE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LE_DIR="/tmp/draw-qa-lbfill-$$"
mkdir -p "$LE_DIR"
magick -size 16x16 xc:none -fill '#ff0000' -draw 'rectangle 0,8 15,8' "PNG32:$LE_DIR/a.png"
magick -size 16x16 xc:none "PNG32:$LE_DIR/b.png"
magick -size 16x16 xc:none -fill '#00ff00' -draw 'rectangle 0,0 15,7' -fill '#ff0000' -draw 'rectangle 0,8 15,8' "PNG32:$LE_DIR/c.png"
magick -size 16x16 xc:none -fill '#00ff00' -draw 'point 4,4' "PNG32:$LE_DIR/d.png"
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
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 4 || -z "${PX:-}" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames, current pane '${PX:-}'"
else
    pass "lightbox shown, 4 frames"
    # the green from frame 4
    le_pick 4
    le_key i
    click "$(le_px 4)" "$(le_py 4)"; wait_for 0.4 "pick the green"

    # -- the Fill tool in frame 1's top half --
    le_pick 1
    le_key f
    click "$(le_px 3)" "$(le_py 3)"; wait_for 0.6 "fill the top half"
    le_read
    le_is "3 2 3 4" && pass "Fill in frame 1's top half: only that half (= frame 3), not round through frame 2 into the bottom half" || fail "fill in frame 1: cells $(le_cells), wanted T0 frames 3 2 3 4 (T0 ${T0[*]:1})"
    le_key ctrl+z; le_read
    le_is "1 2 3 4" || fail "undo the fill: cells $(le_cells)"

    # -- the Magic Wand there, then Fill with FG (Backspace) --
    le_key w
    click "$(le_px 3)" "$(le_py 3)"; wait_for 0.6 "wand the top half"
    le_key BackSpace; le_read
    le_is "3 2 3 4" && pass "Magic Wand in frame 1's top half + Backspace: the selection held only that half (= frame 3)" || fail "wand + fill in frame 1: cells $(le_cells), wanted T0 frames 3 2 3 4 (T0 ${T0[*]:1})"
    le_key ctrl+z; le_palette "deselect"; le_read
    le_is "1 2 3 4" || fail "undo the wand fill: cells $(le_cells)"
    le_key b
    screenshot "anim-lightbox-fill"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LE_DIR"
assert_window_exists
