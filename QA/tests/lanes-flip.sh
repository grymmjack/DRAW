#!/bin/bash
# =============================================================================
# lanes-flip.sh — QA test: a negative SCALE key mirrors the layer (Rick
# 2026-11-16: "yes flip can use negative, love it. we don't need a separate
# lane for flip").
#
#   - + LANE > SCALE X, frame 1's key typed -100: frame 1's drawing mirrored
#     about the pivot (the frame's middle); the pixels untouched
#   - + LANE > SCALE Y, -100: mirrored up / down too
#   - Ctrl+Z: back the other way up
# The old build clamped SCALE to 0..1000 (a typed -100 became 0: nothing drawn).
#
# Dump: LLN (keys), LLD slot f:x0,y0,x1,y1 (what each frame cell shows),
# ANIMXSLO / ANIMXSLN / ANIMXSLA / ANIMXLM (the lane rows), ANIMC (pixels, CRC).
# Fixture: a 64x16 sheet of 16x16 frames; frame 1 a 4x3 block at (2, 3) -
# off the middle both ways. 4 frames, one layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Animation: a negative SCALE key flips the layer ==="

LF_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LF_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
LF_DIR="/tmp/draw-qa-lflip-$$"
mkdir -p "$LF_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,5' -fill '#40c040' -draw 'rectangle 21,3 24,5' "PNG32:$LF_DIR/plain.png"
python3 "$LF_PY" put "$LF_DIR/plain.png" "$LF_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

lf_line() { grep -m1 "^$1 " "$LF_DUMPF" 2>/dev/null; }
lf_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(lf_line ANIM)"
    C=($(lf_line ANIMC))
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(lf_line ANIMXSLO)"
    read -r _ XA_SLOT XA_Y _ <<< "$(lf_line ANIMXSLA)"
    XF=($(lf_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(lf_line ANIMXS)"
    XM=($(lf_line ANIMXLM))
    LLN="$(lf_line LLN | cut -d' ' -f5-)"
    LLD="$(lf_line LLD | cut -d' ' -f3-)"
}
lf_cells() { echo "${C[*]:1}"; }
lf_s() { echo "lanes [${LLN}] shows [${LLD}]"; }
lf_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
lf_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
lf_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
lf_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
lf_pick() { local iy; iy=$(lf_item "$1"); [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; return 1; }; lf_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); lf_read; }
lf_lane_y() { grep -m1 "^ANIMXSLN [0-9]* $1 " "$LF_DUMPF" 2>/dev/null | cut -d' ' -f4; }
lf_add() { # LANE VALUE - + LANE > LANE, then frame 1's key typed VALUE
    local y
    lf_read; lf_hclick "$(lf_fmid 1)" $(( XA_Y + XLH / 2 )); lf_read
    lf_pick $(( 31100 + $1 )) || return 1
    y=$(lf_lane_y "$1"); [[ -z "$y" ]] && return 1
    double_click "$(lf_fmid 1)" $(( y + XLH / 2 )); wait_for 0.9 "input box"
    type_text "$2"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $2"; lf_read
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LF_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
lf_key ctrl+0
lf_key KP_8
lf_read
C0="$(lf_cells)"
if [[ "$A_COUNT" != 4 || "$XO_SLOT" != 1 ]]; then
    fail "start: $A_COUNT frames, arrow '${XO_SLOT:-}'"
else
    lf_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); lf_read
    # frame 1: the block x 2-5, y 3-5; mirrored about x 8: 10-13
    lf_add 3 -100
    [[ "$LLN" == "3=0:-100:0" && "$LLD" == "1:10,3,13,5 "* ]] && pass "SCALE X -100: frame 1's block mirrored left to right (x 2-5 -> 10-13)" || fail "scale x -100: $(lf_s)"
    [[ "$(lf_cells)" == "$C0" ]] && pass "the pixels are untouched" || fail "pixels changed"
    screenshot "lanes-flip-x"
    # mirrored about y 8 too: y 3-5 -> 10-12
    lf_add 4 -100
    [[ "$LLN" == "3=0:-100:0 4=0:-100:0" && "$LLD" == "1:10,10,13,12 "* ]] && pass "SCALE Y -100 as well: upside down too (y 3-5 -> 10-12)" || fail "scale y -100: $(lf_s)"
    lf_key ctrl+z; lf_read
    [[ "$LLD" == "1:10,3,13,5 "* ]] && pass "Ctrl+Z: the right way up again (still mirrored across)" || fail "undo: $(lf_s)"
fi
assert_no_crash
rm -rf "$LF_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
