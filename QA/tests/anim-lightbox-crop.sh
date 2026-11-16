#!/bin/bash
# =============================================================================
# anim-lightbox-crop.sh — QA test: Crop Canvas is refused in the lightbox
# (Rick 2026-11-09: "anything that uses the canvas needs to consider lightbox
# mode"). A crop cuts the whole sheet - every frame - to one box, so in the
# lightbox it says so instead (frames change size with ANIM > Resize). The old
# build cropped the sheet to a marquee drawn in a pane.
#
# Dump: ANIMC (a CRC per frame cell), ANIM (count, current).
# Fixture: a 64x16 sheet of 16x16 frames, each with a shape.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: no Crop Canvas in the lightbox ==="

LE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LE_DIR="/tmp/draw-qa-lbcrop-$$"
mkdir -p "$LE_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,2 9,9' -fill '#40c040' -draw 'rectangle 20,4 27,11' \
    -fill '#4040c0' -draw 'rectangle 36,6 43,13' -fill '#c0c040' -draw 'rectangle 52,2 59,9' "PNG32:$LE_DIR/plain.png"
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
    le_pick 1
    le_key m
    LE_X=$(le_px 1); LE_Y=$(le_py 1)
    hover "$LE_X" "$LE_Y"; sleep 0.3
    mouse_down "$LE_X" "$LE_Y"
    hover "$(le_px 6)" "$(le_py 6)"; sleep 0.2
    hover "$(le_px 11)" "$(le_py 11)"; sleep 0.4
    mouse_up; wait_for 0.6 "marquee released"
    le_palette "crop canvas"
    key Return; wait_for 0.6 "(Enter, in case a crop box opened)"
    le_read
    [[ "$A_COUNT" == 4 ]] && le_is "1 2 3 4" && pass "a marquee in frame 1, Crop Canvas: refused - the sheet and its 4 frames untouched" || fail "crop in the lightbox: $A_COUNT frames, cells $(le_cells) (T0 ${T0[*]:1})"
    le_palette "deselect"
    le_key b
    screenshot "anim-lightbox-crop"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LE_DIR"
assert_window_exists
