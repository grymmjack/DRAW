#!/bin/bash
# =============================================================================
# lanes-smooth.sh — QA test: lane curves are anti-aliased.
#
# Rick 2026-11-16: "also is it possible to have antialiased/smooth looking
# automation lanes? ... not as pixelated?"
#
#   - an armed layer: X = 1 on frame 1 (a nudge), X = 21 on frame 4
#     (Shift+nudges): a sloped X lane between them
#   - the X row between frames 1 and 4 has blended pixels along the curve:
#     many shades (a hard 1 px line would show 2-3), checked with
#     magick -unique-colors; a zoomed screenshot to judge by eye
#
# Dump: ANIMXSF (frames: f x w), ANIMXSLN slot lane y, ANIMXS (layH), LLN, ANIM.
# Fixture: a 64x16 sheet of 16x16 frames, 4 frames, one layer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LAYER_THUMBNAILS=0 XSHEET_FIT_ALL=TRUE NUDGE_N=10
# =============================================================================
info "=== Animation: smooth (anti-aliased) lane curves ==="

LS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LS_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
LS_DIR="/tmp/draw-qa-lsmooth-$$"
mkdir -p "$LS_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$LS_DIR/plain.png"
python3 "$LS_PY" put "$LS_DIR/plain.png" "$LS_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

ls_line() { grep -m1 "^$1 " "$LS_DUMPF" 2>/dev/null; }
ls_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(ls_line ANIM)"
    LLN="$(ls_line LLN | cut -d' ' -f5-)"
    XF=($(ls_line ANIMXSF))
    XLY=$(grep -m1 "^ANIMXSLN [0-9]* 1 " "$LS_DUMPF" | cut -d' ' -f4)
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(ls_line ANIMXS)"
    read -r _ XRX _ <<< "$(ls_line ANIMXSRC)"
    XRY=$(grep -m1 "^ANIMXSR 1 " "$LS_DUMPF" | cut -d' ' -f4)
}
ls_fx() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
ls_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
ls_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
ls_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LS_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
ls_key ctrl+0
ls_key KP_8
ls_read
if [[ "$A_COUNT" != 4 || -z "$XRX" ]]; then
    fail "start: $A_COUNT frames, X-sheet dot '${XRX:-}'"
else
    ls_cmd "arm layer for recording"
    ls_key v
    ls_key Right                                   # frame 1: X = 1
    for _ in 1 2 3; do ls_key KP_5; done           # frame 4
    ls_key shift+Right; ls_key shift+Right         # X = 21
    ls_read
    [[ -n "$XLY" ]] || { ls_hclick $(( XRX + 10 )) $(( XRY + XLH / 2 )); ls_read; }
    if [[ "$LLN" != *"1=0:1:0,3:21:"* || -z "$XLY" ]]; then
        fail "the sloped X lane: frame $A_CUR keys [$LLN] lane row '${XLY:-}'"
    else
        X1=$(ls_fx 1); X4=$(ls_fx 4)
        # the slope between the keys, clear of the key diamonds
        SX=$(( X1 + 6 )); SW=$(( X4 - X1 - 12 ))
        snap_region "$SX" "$XLY" "$SW" "$XLH" "lsmooth-row"; ROW=$SNAP_RESULT
        NC=$(magick "$ROW" -unique-colors -format '%w' info: 2>/dev/null)
        screenshot "lanes-smooth"
        [[ "${NC:-0}" -ge 10 ]] && pass "the sloped X curve is blended: $NC shades along it (frames 1-4, ${SW} px)" \
            || fail "the X curve: only ${NC:-?} colours along it - not anti-aliased? ($ROW)"
    fi
fi
assert_no_crash
rm -rf "$LS_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
