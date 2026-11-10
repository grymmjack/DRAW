#!/bin/bash
# =============================================================================
# anim-lightbox-select.sh — QA test: in the lightbox Select From Current Layer,
# a marquee drag and a moved paste stay inside the current frame (Rick
# 2026-11-09: "anything that uses the canvas needs to consider lightbox mode").
#
# Select From Current Layer selects only the current frame's pixels; a
# marquee dragged past the pane's edge stops at the frame's edge; a floating
# paste nudged half out of the frame is cut off at its edge when committed
# (clip to frame on, the default). The old build selected the layer across
# every frame, let the marquee run on into the next frame, and stamped the
# paste over the neighbour.
#
# Dump: ANIMC (a CRC per frame cell), ANIM (count, current), ANIMLBP (panes).
# Fixture: a 64x16 sheet of 16x16 frames: frame 1 solid red, frame 2 solid
# blue, frame 3 red in its left half (columns 0-7), frame 4 empty. So frame 1
# with its right half deleted is frame 3's picture.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: selections and pastes stay inside the current frame ==="

LE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LE_DIR="/tmp/draw-qa-lbsel-$$"
mkdir -p "$LE_DIR"
magick -size 16x16 xc:'#ff0000' "PNG32:$LE_DIR/a.png"
magick -size 16x16 xc:'#0000ff' "PNG32:$LE_DIR/b.png"
magick -size 16x16 xc:none -fill '#ff0000' -draw 'rectangle 0,0 7,15' "PNG32:$LE_DIR/c.png"
magick -size 16x16 xc:none "PNG32:$LE_DIR/d.png"
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

    # -- Select From Current Layer: frame 1's pixels only --
    le_pick 1
    le_palette "select from current layer"
    le_key Delete; le_read
    [[ "${T[1]}" != "${T0[1]}" ]] && le_others 1 && pass "Select From Current Layer in frame 1 + Delete: frame 1 cleared, frames 2-4 untouched" || fail "select from layer + delete: cells $(le_cells) (T0 ${T0[*]:1})"
    le_key ctrl+z; le_palette "deselect"; le_read
    le_is "1 2 3 4" || fail "undo: cells $(le_cells)"

    # -- a marquee from (8, 0) dragged out past the pane's right and bottom edges --
    le_key m
    LE_X=$(le_px 8); LE_Y=$(le_py 0)
    hover "$LE_X" "$LE_Y"; sleep 0.3
    mouse_down "$LE_X" "$LE_Y"
    hover "$(le_px 14)" "$(le_py 10)"; sleep 0.2
    hover "$(le_px 22)" "$(le_py 20)"; sleep 0.4
    mouse_up; wait_for 0.6 "marquee released"
    le_key Delete; le_read
    le_is "3 2 3 4" && pass "a marquee dragged past frame 1's edges + Delete: only frame 1's right half (= frame 3), frame 2 untouched" || fail "marquee past the edge + delete: cells $(le_cells), wanted T0 frames 3 2 3 4 (T0 ${T0[*]:1})"
    le_key ctrl+z; le_palette "deselect"; le_read
    le_is "1 2 3 4" || fail "undo the marquee delete: cells $(le_cells)"
    le_key b

    # -- a paste of frame 3 nudged 8 px left, half out of the frame, then committed --
    le_pick 3
    le_key ctrl+a; le_key ctrl+c
    le_key ctrl+v
    for i in 1 2 3 4 5 6 7 8; do key Left; wait_for 0.1 "nudge"; done
    le_key Return; le_palette "deselect"; le_read
    le_is "1 2 3 4" && pass "a paste in frame 3 nudged 8 px left and committed: cut off at frame 3's edge, frame 2 untouched" || fail "paste nudged out of frame 3: cells $(le_cells), wanted T0 frames 1 2 3 4 (T0 ${T0[*]:1})"
    screenshot "anim-lightbox-select"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LE_DIR"
assert_window_exists
