#!/bin/bash
# =============================================================================
# anim-effect-lanes.sh — QA test: the effect lanes (TASKS-LANES-NEXT round 2:
# "Blur lane", "Pixelate lane", "Invert lane", "Noise lane") - baked into the
# layer's display per frame (LL_build -> LL_fx).
#   - + LANE lists BLUR / PIXELATE / INVERT / NOISE after a divider
#   - INVERT: a key on frame 1 (0), frame 3 at 100 -> the square c04040 on
#     frame 1, half way (807f7f) on 2, inverted (3fbfbf) on 3 and 4
#   - BLUR: frame 1 at 0, frame 4 at 2 -> frame 4's square spreads past its
#     edge (alpha left of it), frame 1's doesn't; the middle stays solid
#   - PIXELATE: + LANE keys the default 1 (no change)
#   - NOISE: + LANE; the key's menu: From This Key: Frozen Grain -> flag 128
#   - Ctrl+Z / Ctrl+Y; saved, exported in batch (--export-anim): the pixels
# Dump: LLN entry id slot lane=rel:value:ease(raw),...; ANIMXLM; ANIMPL rows.
# Fixture: a 64x16 sheet of 16x16 frames, each a 6x6 square c04040 at (5,5).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=75 XSHEET_ROWS=SMALL
# =============================================================================
info "=== Animation: the effect lanes ==="

EF_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
EF_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
EF_DIR="/tmp/draw-qa-effectlanes-$$"
mkdir -p "$EF_DIR/home" "$EF_DIR/o"
EF_DRAW=()
for n in 0 1 2 3; do
    x=$(( n * 16 + 5 ))
    EF_DRAW+=(-fill '#c04040' -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 64x16 xc:none "${EF_DRAW[@]}" "PNG32:$EF_DIR/plain.png"
python3 "$EF_PY" put "$EF_DIR/plain.png" "$EF_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

ef_line() { grep -m1 "^$1 " "$EF_DUMPF" 2>/dev/null; }
ef_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(ef_line ANIM)"
    XF=($(ef_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(ef_line ANIMXS)"
    XM=($(ef_line ANIMXLM))
    read -r _ XA_SLOT XA_Y _ <<< "$(ef_line ANIMXSLA)"
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(ef_line ANIMXSLO)"
    LLN="$(grep -m1 '^LLN [0-9]* [0-9]* 1 ' "$EF_DUMPF" 2>/dev/null | cut -d' ' -f5-)"
}
ef_s() { echo "lanes [${LLN}]"; }
ef_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
ef_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
ef_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
ef_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
ef_pick() {
    local iy; iy=$(ef_item "$1")
    [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; key Escape; return 1; }
    ef_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); ef_read
}
ef_lane_y() { grep -m1 "^ANIMXSLN 1 $1 " "$EF_DUMPF" 2>/dev/null | cut -d' ' -f4; }
ef_add() { # LANE - + LANE > LANE
    ef_hclick "$(ef_fmid 1)" $(( XA_Y + XLH / 2 )); ef_read
    ef_pick $(( 31100 + $1 ))
}
ef_type() { wait_for 0.9 "input box"; type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $1"; ef_read; }
ef_keyval() { # LANE FRAME VALUE - a key there, then its value typed
    local y; y=$(( $(ef_lane_y "$1") + XLH / 2 ))
    double_click "$(ef_fmid "$2")" "$y"; wait_for 0.6 "add key"; ef_read
    double_click "$(ef_fmid "$2")" "$y"; ef_type "$3"
}
ef_batch() {
    ( cd "$DRAW_ROOT" && HOME="$EF_DIR/home" XDG_CONFIG_HOME="$EF_DIR/home/.config" XDG_DATA_HOME="$EF_DIR/home/.local/share" \
      XDG_CACHE_HOME="$EF_DIR/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$@" </dev/null >>"$EF_DIR/batch.txt" 2>&1 )
}
ef_px() { magick "$1" -format "%[hex:p{$2,$3}]" info: 2>/dev/null | tr 'A-F' 'a-f'; } # RRGGBBAA

info "Launching DRAW with a 64x16 sheet of 16x16 frames (4, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$EF_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
ef_key ctrl+0
ef_key KP_8
ef_read
if [[ "$A_COUNT" != 4 || -z "$XO_X" ]]; then
    fail "start: $A_COUNT frames, arrow '${XO_X:-}'"
else
    pass "a sheet of 4 frames, the X-sheet on"
    ef_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); ef_read
    # -- + LANE: the effects, after a divider --
    ef_hclick "$(ef_fmid 1)" $(( XA_Y + XLH / 2 )); ef_read
    if [[ -n "$(ef_item 31113)" && -n "$(ef_item 31114)" && -n "$(ef_item 31115)" && -n "$(ef_item 31116)" ]]; then
        pass "+ LANE lists BLUR / PIXELATE / INVERT / NOISE"
    else fail "+ LANE: [${XM[*]}]"; fi
    BL=$(ef_item 31112); BU=$(ef_item 31113)
    (( BU > BL + 12 )) && pass "a divider before the effects (BLEND y $BL, BLUR y $BU)" || fail "no gap before BLUR: BLEND y $BL BLUR y $BU"
    ef_pick 31115
    [[ "$LLN" == "15=0:0:0" ]] && pass "+ LANE > INVERT: a key on frame 1 at 0" || fail "+ invert: $(ef_s)"
    ef_keyval 15 3 100
    [[ "$LLN" == "15=0:0:0,2:100:0" ]] && pass "INVERT 100 on frame 3" || fail "invert key: $(ef_s)"
    ef_add 13
    ef_keyval 13 4 2
    # (+ LANE keys the current frame - wherever the double-clicks left it)
    [[ "$LLN" =~ ^13=[0-2]:0:0,3:2:0\ 15=0:0:0,2:100:0$ ]] && pass "BLUR 0 -> 2, frame 4 at 2" || fail "blur keys: $(ef_s)"
    ef_add 14
    [[ "$LLN" =~ 14=[0-3]:1:0 ]] && pass "+ LANE > PIXELATE: keyed at 1 (no change)" || fail "+ pixelate: $(ef_s)"
    ef_add 16
    NY=$(( $(ef_lane_y 16) + XLH / 2 )); NR=$(sed -n 's/.*16=\([0-9]*\):.*/\1/p' <<< "$LLN")
    right_click "$(ef_fmid $(( ${NR:-0} + 1 )))" "$NY"; wait_for 0.6 "noise key menu"; ef_read
    ef_pick 31053
    [[ "$LLN" =~ 16=[0-3]:0:128 ]] && pass "NOISE key: From This Key: Frozen Grain (flag 128)" || fail "frozen grain: $(ef_s)"
    screenshot "effect-lanes"
    ef_key ctrl+z; ef_read
    [[ "$LLN" =~ 16=[0-3]:0:0 ]] && pass "Ctrl+Z: the grain re-rolls again" || fail "undo frozen: $(ef_s)"
    ef_key ctrl+y; ef_read
    [[ "$LLN" =~ 16=[0-3]:0:128 ]] && pass "Ctrl+Y: frozen again" || fail "redo frozen: $(ef_s)"

    # -- saved, exported in batch --
    ef_key ctrl+s; wait_for 1.5 "saved"
    ef_batch "$EF_DIR/sheet.png" --export-anim "$EF_DIR/o/seq.png"
    F=(); for f in 1 2 3 4; do F+=("$(printf "$EF_DIR/o/seq_%04d.png" "$f")"); done
    GOT="$(ef_px "${F[0]}" 8 8 | cut -c1-6) $(ef_px "${F[1]}" 8 8 | cut -c1-6) $(ef_px "${F[2]}" 8 8 | cut -c1-6) $(ef_px "${F[3]}" 8 8 | cut -c1-6)"
    [[ "$GOT" == "c04040 807f7f 3fbfbf 3fbfbf" ]] && pass "INVERT 0 / 50 / 100 / 100 %: the square's middle $GOT" || fail "invert pixels [$GOT] ($(ls "$EF_DIR/o" | tr '\n' ' ') | $(tail -2 "$EF_DIR/batch.txt" | tr '\n' ' '))"
    A1=$(ef_px "${F[0]}" 3 8 | cut -c7-8); A4=$(ef_px "${F[3]}" 3 8 | cut -c7-8)
    [[ "$A1" == "00" && -n "$A4" && "$A4" != "00" ]] && pass "BLUR 2 on frame 4 spreads past the edge (alpha $A4 at x 3; frame 1: $A1)" || fail "blur: frame 1 alpha '$A1', frame 4 '$A4' at (3,8)"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$EF_DIR"
assert_window_exists
info "=== Animation: the effect lanes: done ==="
