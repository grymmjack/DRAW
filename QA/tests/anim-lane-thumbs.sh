#!/bin/bash
# =============================================================================
# anim-lane-thumbs.sh — QA test: lane thumbnails on the X-sheet's main layer row
# (Rick 2026-11-16: "create thumbnail frames where a keyframe change is made in
# the main layer row. for example ball layer is only shown thumbnail in cell 1
# - but when a keyframe changes it's state, there are no thumbnails").
#   - frame 1's drawing held 1-6: one thumbnail, then the hold line
#   - + LANE > X, a key on frame 4 at 6: ANIMXSLT says frames 1 and 4, and frame
#   - the header's right-click menu: Lane Thumbnails: Every Frame -> 1,2,3,4
#     (the X ramp moves the layer on 2, 3, 4; 5 and 6 stay put); saved as EVERY
#   - Off: no ANIMXSLT, frame 4's cell just the hold line; Keyframes: back
# Dump: ANIMXSLT (TOOLS/ANIM-XS), ANIMLH, LLN, ANIMXLM (the header menu, kind 4).
# Fixture: holds-and-lanes.sh's 96x16 sheet of 16x16 frames, 6 frames.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 XSHEET_ROWS=SMALL
# =============================================================================
info "=== Animation: lane thumbnails on the main row ==="

HL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
HL_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
HL_DIR="/tmp/draw-qa-lanethumbs-$$"
mkdir -p "$HL_DIR"
HL_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
HL_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 + 5 ))
    HL_DRAW+=(-fill "#${HL_COLORS[$n]}" -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 96x16 xc:none "${HL_DRAW[@]}" "PNG32:$HL_DIR/plain.png"
python3 "$HL_PY" put "$HL_DIR/plain.png" "$HL_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

hl_line() { grep -m1 "^$1 " "$HL_DUMPF" 2>/dev/null; }
hl_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(hl_line ANIM)"
    LH="$(hl_line ANIMLH | sed 's/^ANIMLH//; s/ _$//; s/^ //')"
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(hl_line ANIMXSLO)"
    read -r _ XA_SLOT XA_Y _ <<< "$(hl_line ANIMXSLA)"
    XF=($(hl_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(hl_line ANIMXS)"
    XM=($(hl_line ANIMXLM))
    XRY=$(grep -m1 "^ANIMXSR 1 " "$HL_DUMPF" | cut -d' ' -f4)
    LLN="$(hl_line LLN | cut -d' ' -f5-)"
    LLD="$(hl_line LLD | cut -d' ' -f3-)"
    local p k; p=($(hl_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
hl_s() { echo "frame ${A_CUR:-?}/${A_COUNT:-?} holds '${LH}' lanes [${LLN}] shows [${LLD}]"; }
hl_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
hl_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
hl_fx() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo "${XF[i + 1]} ${XF[i + 2]}"; return; }; done; echo "0 0"; }
hl_fmid() { local x w; read -r x w <<< "$(hl_fx "$1")"; echo $(( x + w / 2 )); }
hl_fend() { local x w; read -r x w <<< "$(hl_fx "$1")"; echo $(( x + w - 2 )); }
hl_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
hl_pick() {
    local iy; iy=$(hl_item "$1")
    [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; return 1; }
    hl_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); hl_read
}
hl_lane_y() { grep -m1 "^ANIMXSLN 1 $1 " "$HL_DUMPF" 2>/dev/null | cut -d' ' -f4; }
hl_drag() { # X0 X1 Y
    mouse_down "$1" "$3"; hover $(( ($1 + $2) / 2 )) "$3"; sleep 0.15; hover "$2" "$3"; sleep 0.3
    mouse_up; wait_for 0.6 "drop"
}

lt_line() { grep -m1 "^ANIMXSLT 1 " "$HL_DUMPF" 2>/dev/null | cut -d' ' -f4; }
lt_has() { grep -q "^ANIMXSLT " "$HL_DUMPF" 2>/dev/null; }
# (not pinned in QA-OPTIONS: a --option override is never saved, so the cfg would never change)
cfg_has() { local i; for i in 1 2 3 4 5 6 7 8 9 10; do grep -q "$1" "$QA_CFG" && return 0; sleep 0.2; done; return 1; }
lt_snap() { local x w; read -r x w <<< "$(hl_fx "$1")"; snap_region $(( x + 1 )) $(( XRY + 1 )) $(( w - 2 )) $(( XLH - 2 )) "$2" >/dev/null; }
lt_menu() { # pick the header menu's item VALUE
    local hy; read -r _ _ _ _ HY1 _ <<< "$(hl_line ANIMXS)"; hy=$(( HY1 + 1 + XF_ROWH / 2 ))
    right_click "$(hl_fmid 3)" "$hy"; wait_for 0.6 "header menu"; hl_read
    hl_pick "$1"
}

info "Launching DRAW with a 96x16 sheet of 16x16 frames (6, current 1, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$HL_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
hl_key ctrl+0
hl_key KP_8
hl_read
read -r _ _ _ _ _ _ _ _ XF_ROWH _ <<< "$(hl_line ANIMXS)"
if [[ "$A_COUNT" != 6 || -z "$XRY" || "$XO_SLOT" != 1 ]]; then
    fail "start: $(hl_s) row y '${XRY}' arrow '${XO_SLOT:-}'"
else
    pass "a sheet of 6 frames, the X-sheet on, the layer's lanes arrow"
    RY=$(( XRY + XLH / 2 ))
    hl_drag "$(hl_fend 1)" "$(hl_fmid 6)" "$RY"; hl_read
    [[ "$LH" == "1-6" ]] && pass "frame 1's drawing held 1-6" || fail "hold: $(hl_s)"
    lt_has && fail "no lanes yet, but an ANIMXSLT line" || pass "no lanes: no lane thumbnails"

    # -- + LANE > X, a key on frame 4 at 6 --
    hl_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); hl_read
    hl_hclick "$(hl_fmid 1)" $(( XA_Y + XLH / 2 )); hl_read
    hl_pick 31101
    LY=$(hl_lane_y 1); YM=$(( ${LY:-0} + XLH / 2 ))
    double_click "$(hl_fmid 4)" "$YM"; wait_for 0.6 "add key"; hl_read
    double_click "$(hl_fmid 4)" "$YM"; wait_for 0.9 "input box"
    type_text "6"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed 6"; hl_read
    [[ "$LLN" == "1=0:0:0,3:6:0" ]] && pass "+ LANE > X, keys on frames 1 (0) and 4 (6)" || fail "x lane: $(hl_s)"
    [[ "$(lt_line)" == "1,4" ]] && pass "Keyframes: lane thumbnails on frames 1 and 4" || fail "ANIMXSLT '$(lt_line)' ($(grep '^ANIMXSLT' "$HL_DUMPF"))"
    lt_snap 4 "lt-keyed"; KEYED="$SNAP_RESULT"
    screenshot "lane-thumbs-keyframes"

    # -- the header menu: Every Frame / Off / Keyframes --
    lt_menu 222
    [[ "$(lt_line)" == "1,2,3,4" ]] && pass "Every Frame: thumbnails on 1-4 (the frames the X ramp moves it)" || fail "every: ANIMXSLT '$(lt_line)' menu [${XM[*]}]"
    cfg_has '^XSHEET_LANE_THUMBS=EVERY' && pass "saved: XSHEET_LANE_THUMBS=EVERY" || fail "saved: $(grep '^XSHEET_LANE_THUMBS' "$QA_CFG")"
    screenshot "lane-thumbs-every"
    lt_menu 220
    lt_has && fail "Off: still an ANIMXSLT line ($(grep '^ANIMXSLT' "$HL_DUMPF"))" || pass "Off: no lane thumbnails"
    lt_snap 4 "lt-off"
    assert_regions_differ "$KEYED" "$SNAP_RESULT" "frame 4's cell on the main row: a thumbnail (Keyframes) over the hold line (Off)"
    lt_menu 221
    [[ "$(lt_line)" == "1,4" ]] && pass "Keyframes again: 1 and 4" || fail "keyframes: ANIMXSLT '$(lt_line)'"
    cfg_has '^XSHEET_LANE_THUMBS=KEYFRAMES' && pass "saved: XSHEET_LANE_THUMBS=KEYFRAMES" || fail "saved: $(grep '^XSHEET_LANE_THUMBS' "$QA_CFG")"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$HL_DIR"
assert_window_exists
info "=== Animation: lane thumbnails on the main row: done ==="
