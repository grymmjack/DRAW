#!/bin/bash
# =============================================================================
# anim-mod-keys.sh — QA test: the modulator per key + its envelope (round 2:
# "Modulator one-shot toggle per keyframe", "Modulator ADSR envelope").
#   - + LANE > X, LFO Sine, period 4 (amount 2): 0 2 0 -2 ... on the lane's clock;
#     the X row's pixels change (the real wave drawn over the flat key line)
#   - a key on frame 4 (rel 3); its menu: From This Key: Modulator On off -> flat
#     from frame 4; on again + One Cycle (One-Shot) -> one wave from frame 4,
#     then flat; one-shot off + Restart the Wave -> the wave from frame 4 on
#   - Modulator Envelope... "2 0 100 0": a 2-frame attack from each key
#   - Ctrl+Z: the envelope gone
#   - Add Amplitude Lane: an "X ~AMP" row under X (key at the modulator's
#     amount); a key on frame 10 at 6 -> the wave grows 2 -> 6 over the frames
#   - Add Frequency Lane: an "X ~FREQ" row; Ctrl+Z takes it away
# Dump: LLN entry id slot lane=rel:value:ease(raw: + 16 off / 32 one-shot /
# 64 restart)[~]; LLV slot lane env v,v,... (the lane's value per frame).
# Fixture: a 160x16 sheet of 16x16 frames, 10 frames, one layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=75 XSHEET_ROWS=SMALL
# =============================================================================
info "=== Animation: the modulator per key + its envelope ==="

MK_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
MK_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
MK_DIR="/tmp/draw-qa-modkeys-$$"
mkdir -p "$MK_DIR"
MK_DRAW=()
for n in 0 1 2 3 4 5 6 7 8 9; do
    x=$(( n * 16 + 5 ))
    MK_DRAW+=(-fill '#c04040' -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 160x16 xc:none "${MK_DRAW[@]}" "PNG32:$MK_DIR/plain.png"
python3 "$MK_PY" put "$MK_DIR/plain.png" "$MK_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,10,1,10,0,0).hex())")"

mk_line() { grep -m1 "^$1 " "$MK_DUMPF" 2>/dev/null; }
mk_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(mk_line ANIM)"
    XF=($(mk_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(mk_line ANIMXS)"
    XM=($(mk_line ANIMXLM))
    read -r _ XA_SLOT XA_Y _ <<< "$(mk_line ANIMXSLA)"
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(mk_line ANIMXSLO)"
    LLN="$(grep -m1 '^LLN [0-9]* [0-9]* 1 ' "$MK_DUMPF" 2>/dev/null | cut -d' ' -f5-)"
    read -r _ _ _ LLV_ENV LLV <<< "$(grep -m1 '^LLV 1 1 ' "$MK_DUMPF" 2>/dev/null)"
}
mk_s() { echo "lanes [${LLN}] values [${LLV:-}] env '${LLV_ENV:-}'"; }
mk_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
mk_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
mk_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
mk_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
mk_pick() {
    local iy; iy=$(mk_item "$1")
    [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; key Escape; return 1; }
    mk_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); mk_read
}
mk_fspan() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo "${XF[i + 1]} ${XF[i + 2]}"; return; }; done; echo "0 0"; }
mk_row_snap() { # LABEL - the X lane row across all 10 frames
    local a b x1 w1 x2 w2
    read -r x1 w1 <<< "$(mk_fspan 1)"; read -r x2 w2 <<< "$(mk_fspan 10)"
    park_mouse; wait_for 0.3 "render"
    snap_region "$x1" "${LY:-0}" $(( x2 + w2 - x1 )) "$XLH" "$1"
}
mk_lane_y() { grep -m1 "^ANIMXSLN 1 ${1:-1} " "$MK_DUMPF" 2>/dev/null | cut -d' ' -f4; }
mk_menu() { # F VALUE - right-click the X row on frame F, pick VALUE
    right_click "$(mk_fmid "$1")" "$YM"; wait_for 0.6 "lane menu"; mk_read
    mk_pick "$2"
}
mk_type() { # TEXT into the input box that just opened
    wait_for 0.9 "input box"; type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $1"; mk_read
}

info "Launching DRAW with a 160x16 sheet of 16x16 frames (10, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$MK_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
mk_key ctrl+0
mk_key KP_8
mk_read
if [[ "$A_COUNT" != 10 || -z "$XO_X" ]]; then
    fail "start: $A_COUNT frames, arrow '${XO_X:-}'"
else
    pass "a sheet of 10 frames, the X-sheet on"
    mk_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); mk_read
    mk_hclick "$(mk_fmid 1)" $(( XA_Y + XLH / 2 )); mk_read
    mk_pick 31101
    LY=$(mk_lane_y); YM=$(( ${LY:-0} + XLH / 2 ))
    [[ "$LLN" == "1=0:0:0" ]] && pass "+ LANE > X: a key on frame 1" || fail "+ lane X: $(mk_s)"
    mk_row_snap "x-row-bare"; ROW_BARE=$SNAP_RESULT

    # -- LFO Sine, period 4 --
    mk_menu 1 31021
    mk_menu 1 31041; mk_type 4
    [[ "$LLN" == "1=0:0:0~" && "$LLV" == "0,2,0,-2,0,2,0,-2,0,2" && "$LLV_ENV" == "-" ]] && pass "LFO Sine, period 4: 0 2 0 -2 ... on the lane's clock" || fail "sine: $(mk_s)"
    # the lane row draws the modulator's real wave over the flat key line (+ its glyph)
    mk_row_snap "x-row-sine"
    assert_regions_differ "$ROW_BARE" "$SNAP_RESULT" "the X row draws the sine wave (not the flat key line)"
    screenshot "mod-keys-sine-row"

    # -- a key on frame 4 --
    double_click "$(mk_fmid 4)" "$YM"; wait_for 0.6 "add key"; mk_read
    [[ "$LLN" == "1=0:0:0,3:0:0~" && "$LLV" == "0,2,0,-2,0,2,0,-2,0,2" ]] && pass "a plain key on frame 4 changes nothing" || fail "key 4: $(mk_s)"
    mk_menu 4 31050
    [[ "$LLN" == "1=0:0:0,3:0:16~" && "$LLV" == "0,2,0,0,0,0,0,0,0,0" ]] && pass "From This Key: Modulator On unchecked - flat from frame 4" || fail "mod off: $(mk_s)"
    mk_menu 4 31050
    mk_menu 4 31051
    [[ "$LLN" == "1=0:0:0,3:0:32~" && "$LLV" == "0,2,0,0,2,0,-2,0,0,0" ]] && pass "One Cycle (One-Shot): one wave from frame 4, then flat" || fail "one-shot: $(mk_s)"
    screenshot "mod-keys-oneshot"
    mk_menu 4 31051
    mk_menu 4 31052
    [[ "$LLN" == "1=0:0:0,3:0:64~" && "$LLV" == "0,2,0,0,2,0,-2,0,2,0" ]] && pass "Restart the Wave: the wave starts over at frame 4" || fail "restart: $(mk_s)"

    # -- the envelope --
    mk_menu 1 31042; mk_type "2 0 100 0"
    [[ "$LLV_ENV" == "2,0,100,0" && "$LLV" == "0,1,0,0,1,0,-2,0,2,0" ]] && pass "Envelope 2 0 100 0: a 2-frame attack from each key" || fail "envelope: $(mk_s)"
    screenshot "mod-keys-envelope"
    mk_key ctrl+z; mk_read
    [[ "$LLV_ENV" == "-" && "$LLV" == "0,2,0,0,2,0,-2,0,2,0" ]] && pass "Ctrl+Z: the envelope gone" || fail "undo: $(mk_s)"

    # -- the AMPLITUDE sub-lane: the amount over time --
    mk_menu 1 31044
    AY=$(mk_lane_y 201)
    [[ -n "$AY" && "$LLV" == "0,2,0,0,2,0,-2,0,2,0" ]] && pass "Add Amplitude Lane: an X ~AMP row (y $AY), the wave as it was" || fail "amp lane: row '${AY:-}' $(mk_s) rows: $(grep '^ANIMXSLN' "$MK_DUMPF" | cut -d' ' -f2-4 | tr '\n' '|')"
    AM=$(( ${AY:-0} + XLH / 2 ))
    double_click "$(mk_fmid 10)" "$AM"; wait_for 0.6 "add key"; mk_read
    double_click "$(mk_fmid 10)" "$AM"; mk_type 6
    [[ "$LLV" == "0,2.4,0,0,3.8,0,-4.7,0,5.6,0" ]] && pass "X ~AMP 2 -> 6 over frames 1-10: the wave grows" || fail "amp ramp: $(mk_s) amp row: $(grep '^ANIMXSLN 1 201 ' "$MK_DUMPF")"
    screenshot "mod-keys-amp"

    # -- the FREQUENCY sub-lane --
    mk_menu 1 31043
    FY=$(mk_lane_y 101)
    [[ -n "$FY" ]] && pass "Add Frequency Lane: an X ~FREQ row (y $FY)" || fail "freq lane: no row ($(grep '^ANIMXSLN' "$MK_DUMPF" | cut -d' ' -f2-4 | tr '\n' '|'))"
    mk_key ctrl+z; mk_read
    [[ -z "$(mk_lane_y 101)" && -n "$(mk_lane_y 201)" ]] && pass "Ctrl+Z: the FREQ row gone, ~AMP kept" || fail "undo freq: rows $(grep '^ANIMXSLN' "$MK_DUMPF" | cut -d' ' -f2-4 | tr '\n' '|')"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$MK_DIR"
assert_window_exists
info "=== Animation: the modulator per key + its envelope: done ==="
