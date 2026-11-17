#!/bin/bash
# =============================================================================
# holds-and-lanes.sh — QA test: per-layer holds and keyframe lanes together on
# one pixel layer, the X-sheet cell menu, the lane menus, a lane key drag, and
# the lightbox showing the lanes (branch xsheet-holds-lanes).
#
#   - drag frame 1's right end to frame 3: held 1-3
#   - right-click frame 5's cell: the cell menu; Hold for N Frames... 2: 5-6
#   - right-click frame 2 (in the 1-3 run): Release Hold is offered
#   - + LANE > OPACITY; frame 3 keyed to 0: frames 3+ show nothing, the held
#     frame 2 still shows frame 1's drawing
#   - right-click frame 1's key > Ease In; drag frame 3's key to frame 5
#   - the lightbox's pane for frame 6 shows the lane (empty), and the drawing
#     once the lane edits are undone (the holds stay)
#
# Dump: ANIMLH (held runs), LLN / LLD (layer lanes, TOOLS/LAYER-LANES),
# ANIMXSLO / ANIMXSLN / ANIMXSLA / ANIMXLM (lane rows, menus incl. the cell
# menu), ANIMXSR / ANIMXSF (X-sheet geometry), ANIMLBP (lightbox panes).
# Fixture: a 96x16 sheet of 16x16 frames, frame k a 6x6 square at (5, 5) of
# its own colour; 6 frames, current 1. One layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Animation: holds and lanes together ==="

HL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
HL_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
HL_DIR="/tmp/draw-qa-holdlanes-$$"
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
if [[ "$A_COUNT" != 6 || -z "$XRY" || "$XO_SLOT" != 1 ]]; then
    fail "start: $(hl_s) row y '${XRY}' arrow '${XO_SLOT:-}'"
else
    pass "a sheet of 6 frames, the X-sheet on, the layer's lanes arrow"
    RY=$(( XRY + XLH / 2 ))

    # -- holds --
    hl_drag "$(hl_fend 1)" "$(hl_fmid 3)" "$RY"; hl_read
    [[ "$LH" == "1-3" ]] && pass "drag frame 1's right end to frame 3: held 1-3" || fail "stretch: $(hl_s)"
    right_click "$(hl_fmid 5)" "$RY"; wait_for 0.6 "cell menu"; hl_read
    [[ -n "$(hl_item 2610)" && -z "$(hl_item 2611)" && -n "$(hl_item 29000)" ]] \
        && pass "right-click frame 5's cell: the cell menu (Hold for N Frames..., Layer Menu...; no Release Hold off a hold)" || fail "cell menu: [${XM[*]}]"
    hl_pick 2610; wait_for 0.6 "input box"
    type_text "2"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed 2"; hl_read
    [[ "$LH" == "1-3 5-6" ]] && pass "Hold for N Frames... 2 from the cell menu: held 5-6" || fail "hold for n: $(hl_s)"
    right_click "$(hl_fmid 2)" "$RY"; wait_for 0.6 "cell menu"; hl_read
    [[ -n "$(hl_item 2611)" ]] && pass "right-click frame 2 (in the 1-3 run): Release Hold offered" || fail "release offered: [${XM[*]}]"
    hl_key Escape; hl_read

    # -- a lane on the held layer --
    hl_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); hl_read
    hl_hclick "$(hl_fmid 1)" $(( XA_Y + XLH / 2 )); hl_read
    hl_pick 31106
    LY=$(hl_lane_y 6); YM=$(( ${LY:-0} + XLH / 2 ))
    [[ -n "$LY" && "$LLN" == "6=0:100:0" ]] && pass "+ LANE > OPACITY: a key on frame 1 at 100" || fail "+ lane opacity: $(hl_s) menu [${XM[*]}]"
    double_click "$(hl_fmid 3)" "$YM"; wait_for 0.6 "add key"; hl_read
    double_click "$(hl_fmid 3)" "$YM"; wait_for 0.9 "input box"
    type_text "0"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed 0"; hl_read
    [[ "$LLN" == "6=0:100:0,2:0:0" && "$LLD" == "1:5,5,10,10 2:5,5,10,10 3:- 4:- 5:- 6:-" && "$LH" == "1-3 5-6" ]] \
        && pass "OPACITY 100 -> 0 by frame 3: frames 1-2 show the held drawing, 3-6 nothing; the holds kept" || fail "opacity: $(hl_s)"

    # -- the key menu: Ease In on frame 1's key --
    right_click "$(hl_fmid 1)" "$YM"; wait_for 0.6 "lane menu"; hl_read
    hl_pick 31002
    [[ "$LLN" == "6=0:100:1,2:0:0" ]] && pass "right-click frame 1's key > Ease In" || fail "ease: $(hl_s) menu [${XM[*]}]"

    # -- drag frame 3's key along to frame 5 --
    X3=$(hl_fmid 3); X5=$(hl_fmid 5)
    hl_drag "$X3" "$X5" "$YM"; hl_read
    [[ "$LLN" == "6=0:100:1,4:0:0" && "$LLD" == "1:5,5,10,10 2:5,5,10,10 3:5,5,10,10 4:5,5,10,10 5:- 6:-" ]] \
        && pass "drag frame 3's key to frame 5: the fade ends on frame 5 (3 + 4 show again)" || fail "key drag: $(hl_s)"

    # -- the lightbox shows the lane --
    hl_hclick "$(hl_fmid 6)" "$RY"; hl_read
    hl_key KP_0; hl_read
    if [[ "$A_CUR" == 6 && -n "$PX" ]]; then
        snap_region "$PX" "$PY" "$PW" "$PH" "hl-pane6-laned" >/dev/null; P_A="$SNAP_RESULT"
        hl_key ctrl+z; hl_key ctrl+z; hl_key ctrl+z; hl_key ctrl+z; hl_key ctrl+z; hl_read
        snap_region "$PX" "$PY" "$PW" "$PH" "hl-pane6-plain" >/dev/null; P_B="$SNAP_RESULT"
        [[ -z "$LLN" && "$LH" == "1-3 5-6" ]] && pass "5x Ctrl+Z: the lane edits gone, the holds kept" || fail "undo lanes: $(hl_s)"
        assert_regions_differ "$P_A" "$P_B" "the lightbox pane for frame 6: empty through the lane, the held drawing without it"
    else
        fail "lightbox: frame $A_CUR, no pane for it"
    fi
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$HL_DIR"
assert_window_exists
info "=== Animation: holds and lanes together: done ==="
