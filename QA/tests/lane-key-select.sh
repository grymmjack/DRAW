#!/bin/bash
# =============================================================================
# lane-key-select.sh — QA test: selecting keys on the X-sheet's lane rows with a
# rect (TOOLS/ANIM-XLANE ANIM_XL_sel_*, XS_DRAG_LSEL).
#
# Rick 2026-11-16: "a cursor that's a crosshair when we are on a lane we could
# drag to select the cells across lanes ... just one solid rect".
#
#   - a pixel layer, lanes X (keys frames 1, 4) and Y (keys frames 1, 3)
#   - drag from frame 2 on the X row to frame 4 on the Y row: frames 2-4 of
#     both lanes selected, the keys inside = 2 (X on 4, Y on 3); the rows shaded
#   - a click on empty lane space clears it; so does Esc
#   - a selection is not an edit: no undo step (the lanes stay as they were)
#
# Dump: XLSEL on f1 f2 keys slot:lane...; ANIMXSLN / ANIMXSLA (lane rows),
# LLN (the lanes), ANIMXSF (frame xs).
# Fixture: a 96x16 sheet of 16x16 frames, 6 frames, one layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Animation: a rect selection of lane keys ==="

KS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
KS_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
KS_DIR="/tmp/draw-qa-keysel-$$"
mkdir -p "$KS_DIR"
KS_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
KS_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 + 5 ))
    KS_DRAW+=(-fill "#${KS_COLORS[$n]}" -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 96x16 xc:none "${KS_DRAW[@]}" "PNG32:$KS_DIR/plain.png"
python3 "$KS_PY" put "$KS_DIR/plain.png" "$KS_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

ks_line() { grep -m1 "^$1 " "$KS_DUMPF" 2>/dev/null; }
ks_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(ks_line ANIMXSLO)"
    read -r _ XA_SLOT XA_Y _ <<< "$(ks_line ANIMXSLA)"
    XF=($(ks_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(ks_line ANIMXS)"
    XM=($(ks_line ANIMXLM))
    LLN="$(ks_line LLN | cut -d' ' -f5-)"
    read -r _ S_ON S_F1 S_F2 S_N S_LANES <<< "$(ks_line XLSEL)"
}
ks_s() { echo "sel on '${S_ON:-}' frames ${S_F1:-?}-${S_F2:-?} keys ${S_N:-?} lanes [${S_LANES:-}] lanes now [$LLN]"; }
ks_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
ks_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
ks_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
ks_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
ks_pick() { local iy; iy=$(ks_item "$1"); [[ -z "$iy" ]] && return 1; ks_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); ks_read; }
ks_lane_y() { grep -m1 "^ANIMXSLN [0-9]* $1 " "$KS_DUMPF" 2>/dev/null | cut -d' ' -f4; }
ks_add_lane() { # LANE VALUE: + LANE on frame 1, pick it
    ks_hclick "$(ks_fmid 1)" $(( XA_Y + XLH / 2 )); ks_read
    ks_pick "$2"
}
ks_drag() { # X0 Y0 X1 Y1
    mouse_down "$1" "$2"; hover $(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 )); sleep 0.15; hover "$3" "$4"; sleep 0.3
    mouse_up; wait_for 0.6 "drop"
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$KS_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
ks_key ctrl+0
ks_key KP_8
ks_read
if [[ "$XO_SLOT" != 1 || -z "$(ks_fmid 4)" || "$(ks_fmid 4)" == 0 ]]; then
    fail "start: no lanes arrow / frames (arrow '${XO_SLOT:-}' frames '${XF[*]}')"
else
    ks_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); ks_read
    ks_add_lane X 31101
    ks_add_lane Y 31102
    XY=$(( $(ks_lane_y 1) + XLH / 2 )); YY=$(( $(ks_lane_y 2) + XLH / 2 ))
    double_click "$(ks_fmid 4)" "$XY"; wait_for 0.6 "a key on X"
    double_click "$(ks_fmid 3)" "$YY"; wait_for 0.6 "a key on Y"
    ks_read
    LLN0="$LLN"
    [[ "$S_ON" == 0 && "$LLN" == *"1=0:0:0,3:0:0"* && "$LLN" == *"2=0:0:0,2:0:0"* ]] \
        && pass "lanes X (keys 1, 4) and Y (keys 1, 3), nothing selected" || fail "setup: $(ks_s)"

    # -- the rect: frame 2 on X to frame 4 on Y --
    snap_region "$(ks_fmid 2)" "$(ks_lane_y 1)" 24 $(( XLH * 2 )) ks-before >/dev/null; KS_A="$SNAP_RESULT"
    ks_drag "$(ks_fmid 2)" "$XY" "$(ks_fmid 4)" "$YY"; ks_read
    [[ "$S_ON" == 1 && "$S_F1" == 2 && "$S_F2" == 4 && "$S_N" == 2 && "$S_LANES" == "1:1 1:2" ]] \
        && pass "drag frame 2 / X to frame 4 / Y: frames 2-4 of X and Y, 2 keys inside" || fail "rect: $(ks_s)"
    [[ "$LLN" == "$LLN0" ]] && pass "selecting changed no key" || fail "the keys changed: [$LLN] was [$LLN0]"
    snap_region "$(ks_fmid 2)" "$(ks_lane_y 1)" 24 $(( XLH * 2 )) ks-after >/dev/null; KS_B="$SNAP_RESULT"
    assert_regions_differ "$KS_A" "$KS_B" "the selected frames are shaded on both lane rows"
    screenshot "lane-key-select"

    # -- dragged backwards (right to left, bottom to top): the same rect --
    ks_hclick "$(ks_fmid 6)" "$XY"; ks_read
    [[ "$S_ON" == 0 ]] && pass "a click on empty lane space clears it" || fail "click clear: $(ks_s)"
    ks_drag "$(ks_fmid 4)" "$YY" "$(ks_fmid 2)" "$XY"; ks_read
    [[ "$S_ON" == 1 && "$S_F1" == 2 && "$S_F2" == 4 && "$S_N" == 2 ]] && pass "dragged the other way: the same selection" || fail "backwards: $(ks_s)"

    # -- one lane only, a single frame wide --
    ks_key Escape; ks_read
    [[ "$S_ON" == 0 ]] && pass "Esc clears it" || fail "Esc: $(ks_s)"
    ks_drag "$(ks_fmid 5)" "$XY" "$(ks_fmid 3)" "$XY"; ks_read
    [[ "$S_ON" == 1 && "$S_F1" == 3 && "$S_F2" == 5 && "$S_N" == 1 && "$S_LANES" == "1:1" ]] && pass "frames 3-5 on X only: 1 key" || fail "one lane: $(ks_s)"

    # -- drag inside the selection: its keys along (Rick: "move selected automation with drag on the box") --
    ks_drag "$(ks_fmid 4)" "$XY" "$(ks_fmid 5)" "$XY"; ks_read
    [[ "$LLN" == *"1=0:0:0,4:0:0"* && "$S_F1" == 4 && "$S_F2" == 6 ]] && pass "drag inside it, frame 4 -> 5: X's key on frame 5, the rect now frames 4-6" || fail "move: $(ks_s)"
    ks_key ctrl+z; ks_read
    [[ "$LLN" == *"1=0:0:0,3:0:0"* ]] && pass "Ctrl+Z: the key back on frame 4 (one step)" || fail "undo move: $(ks_s)"
    # Alt+drag: a copy (the rect is on 4-6, the key on 4)
    # (under Xvfb a press made with Alt already held never reaches DRAW: Alt goes down
    #  during the drag and is held through the release - the copy flag is read live)
    mouse_down "$(ks_fmid 5)" "$XY"; hover $(( $(ks_fmid 5) + 6 )) "$XY"; sleep 0.15; hover "$(ks_fmid 6)" "$XY"; sleep 0.2
    raw_key down alt; sleep 0.25; hover $(( $(ks_fmid 6) + 1 )) "$XY"; sleep 0.25
    mouse_up; sleep 0.2; raw_key up alt; wait_for 0.6 "alt+drag copy"; ks_read
    [[ "$LLN" == *"1=0:0:0,3:0:0,4:0:0"* ]] && pass "Alt+drag inside it: a copy on frame 5, frame 4's key stays" || fail "alt copy: $(ks_s)"
    ks_key ctrl+z; ks_read
    [[ "$LLN" == *"1=0:0:0,3:0:0"* && "$LLN" != *"4:0:0"* ]] && pass "Ctrl+Z: the copy gone" || fail "undo copy: $(ks_s)"
    # both lanes at once, back a frame: one undo step for both
    ks_key Escape
    ks_drag "$(ks_fmid 2)" "$XY" "$(ks_fmid 4)" "$YY"; ks_read
    ks_drag "$(ks_fmid 3)" "$YY" "$(ks_fmid 2)" "$YY"; ks_read
    [[ "$LLN" == *"1=0:0:0,2:0:0"* && "$LLN" == *"2=0:0:0,1:0:0"* && "$S_F1" == 1 && "$S_F2" == 3 ]] \
        && pass "X + Y selected, dragged back a frame: X's key on 3, Y's on 2" || fail "two lanes: $(ks_s)"
    ks_key ctrl+z; ks_read
    [[ "$LLN" == *"1=0:0:0,3:0:0"* && "$LLN" == *"2=0:0:0,2:0:0"* ]] && pass "one Ctrl+Z puts both lanes back" || fail "undo two lanes: $(ks_s)"
    # dragged past frame 1: stops where the first selected key reaches frame 1 (frames 2-4 again;
    # from frame 4 to 1 = -3, but Y's key on 3 can only go back 2: it lands on frame 1's key)
    ks_key Escape
    ks_drag "$(ks_fmid 2)" "$XY" "$(ks_fmid 4)" "$YY"; ks_read
    ks_drag "$(ks_fmid 4)" "$XY" "$(ks_fmid 1)" "$XY"; ks_read
    [[ " $LLN " == *" 1=0:0:0,1:0:0 "* && " $LLN " == *" 2=0:0:0 "* ]] && pass "dragged 3 back: only 2 (X's key on 2, Y's on 1 - frame 1's key replaced)" || fail "clamp: $(ks_s)"
    ks_key ctrl+z; ks_read
    [[ "$LLN" == *"1=0:0:0,3:0:0"* && "$LLN" == *"2=0:0:0,2:0:0"* ]] && pass "Ctrl+Z: both lanes as they were" || fail "undo clamp: $(ks_s)"

    # -- no undo step for selecting --
    ks_key Escape
    ks_key ctrl+z; ks_read
    [[ "$LLN" == *"1=0:0:0,3:0:0"* && "$LLN" != *"2=0:0:0,2:0:0"* ]] && pass "Ctrl+Z undoes the last key (Y on 3), not a selection" || fail "undo: $(ks_s)"
fi
assert_no_crash
rm -rf "$KS_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
