#!/bin/bash
# =============================================================================
# anim-lightbox-canvas-edit.sh — QA test: in the lightbox the current frame is
# the canvas for Select All, Cut / Copy / Paste and symmetry (Rick
# 2026-11-09: "anything that uses the canvas needs to consider lightbox
# mode, not just the drawing tools").
#
# Ctrl+A selects the current frame (Delete then clears only it); Ctrl+X with
# nothing selected cuts only the current frame (the old build cleared every
# frame); Ctrl+V centres the paste on the current frame; symmetry mirrors
# about the centre of the frame drawn in (the old build mirrored about the
# sheet's centre - into another frame).
#
# Dump: ANIMC (a CRC per frame cell), ANIMLB (the strip), ANIMLBP (panes).
# Fixture: a 64x16 sheet of 16x16 frames, transparent: frame 1 a shape A,
# frame 2 a shape B, frame 3 one red pixel at (2,10), frame 4 that pixel +
# red pixels at (2,5) and (14,5) - so a 1-px red dot at (2,5) in frame 3 with
# vertical symmetry (mirror x -> 16 - x about the frame's centre 8) is frame
# 4's picture.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: Select All, Cut / Copy / Paste, symmetry on the current frame ==="

LE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LE_DIR="/tmp/draw-qa-lbcvedit-$$"
mkdir -p "$LE_DIR"
magick -size 16x16 xc:none -fill '#c04040' -draw 'rectangle 2,2 3,9' -draw 'rectangle 2,8 9,9' \
    -fill '#40c040' -draw 'rectangle 6,3 7,4' "PNG32:$LE_DIR/a.png"
magick -size 16x16 xc:none -fill '#4040c0' -draw 'rectangle 5,5 11,11' "PNG32:$LE_DIR/b.png"
magick -size 16x16 xc:none -fill '#ff0000' -draw 'point 2,10' "PNG32:$LE_DIR/c.png"
magick -size 16x16 xc:none -fill '#ff0000' -draw 'point 2,10' -draw 'point 2,5' -draw 'point 14,5' "PNG32:$LE_DIR/d.png"
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

    # -- Select All = the current frame: Delete clears only it --
    le_pick 1
    le_key ctrl+a
    le_key Delete; le_read
    [[ "${T[1]}" != "${T0[1]}" ]] && le_others 1 && pass "Ctrl+A, Delete in frame 1: frame 1 cleared, frames 2-4 untouched" || fail "select all + delete: cells $(le_cells) (T0 ${T0[*]:1})"
    le_key ctrl+z; le_read
    le_is "1 2 3 4" || fail "undo the delete: cells $(le_cells)"
    le_palette "deselect"

    # -- Cut with nothing selected: only the current frame; Paste centres on it --
    le_key ctrl+x; le_read
    [[ "${T[1]}" != "${T0[1]}" ]] && le_others 1 && pass "Ctrl+X with no selection in frame 1: only frame 1 cut" || fail "cut frame 1: cells $(le_cells) (T0 ${T0[*]:1})"
    le_key ctrl+v
    le_key Return; le_palette "deselect"; le_read
    le_is "1 2 3 4" && pass "Ctrl+V: the cut frame pasted back centred on frame 1, exactly where it was" || fail "paste into frame 1: cells $(le_cells) (T0 ${T0[*]:1})"

    # -- symmetry about the frame's centre --
    le_pick 3
    le_key i
    click "$(le_px 2)" "$(le_py 10)"; wait_for 0.4 "pick the red"
    le_key b
    le_palette "cycle symmetry"
    le_read
    click "$(le_px 2)" "$(le_py 5)"; wait_for 0.5 "dot at 2,5"
    le_read
    le_is "1 2 4 4" && pass "vertical symmetry, a dot at (2,5) in frame 3: mirrored to (14,5) in frame 3 (= frame 4), the rest untouched" || fail "symmetry in frame 3: cells $(le_cells) (T0 ${T0[*]:1})"
    le_key ctrl+z; le_read
    le_is "1 2 3 4" || fail "undo the symmetric dot: cells $(le_cells)"
    le_palette "clear symmetry"
    screenshot "anim-lightbox-canvas-edit"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LE_DIR"
assert_window_exists
