#!/bin/bash
# =============================================================================
# layer-lanes.sh — QA test: keyframe lanes on a pixel layer (branch
# xsheet-holds-lanes, TOOLS/LAYER-LANES + TOOLS/ANIM-XLANE).
#
#   - a pixel layer's X-sheet row has the lanes arrow; it opens + LANE
#   - + LANE > X: an X row with a key on frame 1 (0)
#   - double-click frame 4 on the X row: a key there; double-click it: type 4
#   - the canvas shows each frame's drawing moved by X (linear 0 -> 4 over
#     frames 1-4, held after): the display, not the pixels (ANIMC unchanged)
#   - the canvas on screen changes in frame 4's cell, and back on undo
#   - Ctrl+Z steps the edits back one at a time; Ctrl+Y forward
#   - Ctrl+S, reopen: the lanes are back (a drLL chunk in the PNG)
#
# Dump: LLN entry historyId slot lane=rel:value:ease,... ; LLD slot f:x0,y0,x1,y1
# (what each frame cell shows); ANIMXSLO / ANIMXSLN / ANIMXSLA / ANIMXLM (the
# lane rows, TOOLS/ANIM-XLANE); ANIMC (each cell's pixels, CRC).
# Fixture: a 96x16 sheet of 16x16 frames, frame k a 6x6 square at (5, 5) of
# its own colour; 6 frames, current 1. One layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Animation: keyframe lanes on a pixel layer ==="

LL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LL_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
LL_DIR="/tmp/draw-qa-lanes-$$"
mkdir -p "$LL_DIR"
LL_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
LL_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 + 5 ))
    LL_DRAW+=(-fill "#${LL_COLORS[$n]}" -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 96x16 xc:none "${LL_DRAW[@]}" "PNG32:$LL_DIR/plain.png"
python3 "$LL_PY" put "$LL_DIR/plain.png" "$LL_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

ll_line() { grep -m1 "^$1 " "$LL_DUMPF" 2>/dev/null; }
ll_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(ll_line ANIM)"
    C=($(ll_line ANIMC))
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(ll_line ANIMXSLO)"
    read -r _ XA_SLOT XA_Y _ <<< "$(ll_line ANIMXSLA)"
    XF=($(ll_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(ll_line ANIMXS)"
    XM=($(ll_line ANIMXLM))
    XRY=$(grep -m1 "^ANIMXSR 1 " "$LL_DUMPF" | cut -d' ' -f4)
    LLN="$(ll_line LLN | cut -d' ' -f5-)"
    LLD="$(ll_line LLD | cut -d' ' -f3-)"
}
ll_cells() { echo "${C[*]:1}"; }
ll_s() { echo "frame ${A_CUR:-?}/${A_COUNT:-?} open ${XO_OPEN:-?} lanes [${LLN}] shows [${LLD}]"; }
ll_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
ll_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
ll_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
ll_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
ll_pick() { # VALUE - click that item of the open lane menu
    local iy; iy=$(ll_item "$1")
    [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; return 1; }
    ll_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); ll_read
}
ll_lane_y() { grep -m1 "^ANIMXSLN [0-9]* $1 " "$LL_DUMPF" 2>/dev/null | cut -d' ' -f4; }
ll_cell_snap() { # F LABEL - frame F's cell on the canvas
    local dx dy z
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ dx dy _ <<< "$(ll_line ANIM)"
    read -r _ z _ <<< "$(ll_line VIEW)"
    snap_region $(( dx + ($1 - 1) * 16 * z / 100 )) "$dy" $(( 16 * z / 100 )) $(( 16 * z / 100 )) "$2" >/dev/null
    echo "$SNAP_RESULT"
}

# frames 1-6 through X = 0 -> 4 linear over 1-4, held after (whole pixels, half up)
LL_MOVED="1:5,5,10,10 2:6,5,11,10 3:8,5,13,10 4:9,5,14,10 5:9,5,14,10 6:9,5,14,10"
LL_FLAT="1:5,5,10,10 2:5,5,10,10 3:5,5,10,10 4:5,5,10,10 5:5,5,10,10 6:5,5,10,10"

info "Launching DRAW with a 96x16 sheet of 16x16 frames (6, current 1, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LL_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
ll_key ctrl+0
ll_key KP_8
ll_read
C0="$(ll_cells)"
if [[ "$A_COUNT" != 6 || "$XO_SLOT" != 1 || "$XO_OPEN" != 0 || -z "$XRY" ]]; then
    fail "start: $(ll_s) arrow '${XO_SLOT:-}' row y '${XRY}' (wanted 6 frames, the X-sheet on, the pixel layer's lanes arrow)"
else
    pass "a pixel layer's X-sheet row has the lanes arrow (closed)"
    SNAP4A=$(ll_cell_snap 4 "ll-f4-before")

    # -- open: + LANE --
    ll_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); ll_read
    [[ "$XO_OPEN" == -1 && "$XA_SLOT" == 1 && -z "$LLN" ]] && pass "the arrow opens the lanes: just + LANE (no lanes yet)" || fail "open: $(ll_s) add '${XA_SLOT:-}'"

    # -- + LANE > X --
    ll_hclick "$(ll_fmid 1)" $(( XA_Y + XLH / 2 )); ll_read  # (on frame 1: the press picks the frame, and the key goes on the current one)
    ll_pick 31101
    [[ "$LLN" == "1=0:0:0" && -n "$(ll_lane_y 1)" && "$LLD" == "$LL_FLAT" ]] \
        && pass "+ LANE > X: an X row, a key on frame 1 at 0, the drawings where they were" || fail "+ lane X: $(ll_s) menu [${XM[*]}]"

    # -- double-click frame 4: a key; again: type 4 --
    LY=$(ll_lane_y 1); YM=$(( LY + XLH / 2 )); X4=$(ll_fmid 4)
    double_click "$X4" "$YM"; wait_for 0.6 "double-click"; ll_read
    [[ "$LLN" == "1=0:0:0,3:0:0" ]] && pass "double-click frame 4 on the X row: a key there (0)" || fail "add key: $(ll_s)"
    double_click "$X4" "$YM"; wait_for 0.9 "input box"
    type_text "4"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed 4"; ll_read
    [[ "$LLN" == "1=0:0:0,3:4:0" ]] && pass "double-click the key: typed X = 4" || fail "type value: $(ll_s)"
    [[ "$LLD" == "$LL_MOVED" ]] && pass "each frame's drawing moves by X (0, 1, 3, 4, 4, 4 px)" || fail "display: [$LLD] want [$LL_MOVED]"
    [[ "$(ll_cells)" == "$C0" ]] && pass "the layer's pixels are untouched (non-destructive)" || fail "pixels changed: $(ll_cells) vs $C0"
    SNAP4B=$(ll_cell_snap 4 "ll-f4-after")
    assert_regions_differ "$SNAP4A" "$SNAP4B" "the canvas shows frame 4's drawing moved"
    screenshot "layer-lanes-x"

    # -- undo / redo, one step each --
    ll_key ctrl+z; ll_read
    [[ "$LLN" == "1=0:0:0,3:0:0" ]] && pass "Ctrl+Z: the typed value back to 0" || fail "undo 1: $(ll_s)"
    ll_key ctrl+z; ll_read
    [[ "$LLN" == "1=0:0:0" ]] && pass "Ctrl+Z: the frame 4 key gone" || fail "undo 2: $(ll_s)"
    ll_key ctrl+z; ll_read
    [[ -z "$LLN" && -z "$LLD" ]] && pass "Ctrl+Z: the X lane gone, no display copy" || fail "undo 3: $(ll_s)"
    SNAP4C=$(ll_cell_snap 4 "ll-f4-undone")
    assert_regions_same "$SNAP4A" "$SNAP4C" "undone: frame 4 on the canvas as it was"
    ll_key ctrl+y; ll_key ctrl+y; ll_key ctrl+y; ll_read
    [[ "$LLN" == "1=0:0:0,3:4:0" && "$LLD" == "$LL_MOVED" ]] && pass "Ctrl+Y x3: the lane and both keys back, the drawings moved again" || fail "redo: $(ll_s)"

    # -- saved and back --
    ll_key ctrl+s; wait_for 1.5 "saved"
    LL_CHUNK=$(python3 "$LL_PY" get "$LL_DIR/sheet.png" drLL 2>/dev/null | cut -c1-8)
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$LL_DIR/sheet.png"
    draw_launch 15
    wait_for 1.5 "Saved sheet loaded"
    assert_no_crash
    ll_read
    [[ -n "$LL_CHUNK" && "$LLN" == "1=0:0:0,3:4:0" && "$LLD" == "$LL_MOVED" && "$(ll_cells)" == "$C0" ]] \
        && pass "Ctrl+S, reopen: a drLL chunk, the X lane back, the drawings moved, the pixels as drawn" || fail "reopen: chunk '${LL_CHUNK}' $(ll_s)"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LL_DIR"
assert_window_exists
info "=== Animation: keyframe lanes on a pixel layer: done ==="
