#!/bin/bash
# =============================================================================
# anim-blend-lane.sh — QA test: the BLEND lane (TASKS-LANES-NEXT "blend mode
# lane"): a pixel layer's blend mode keyed per frame, held until the next key.
#   - duplicate the layer (Ctrl+Shift+D): the copy sits on the original
#   - the copy's lanes, + LANE > BLEND: a key on frame 1 at its own mode
#     (Normal), held (HOLD ease)
#   - right-click the BLEND row on frame 3: the modes listed, Normal checked;
#     Difference -> a key there, held
#   - + LANE offers no VOLUME / PAN on a layer
#   - Ctrl+Z takes the Difference key back, Ctrl+Y puts it again
#   - saved (Ctrl+S) and exported in batch (--export-anim): frames 1-2 the
#     square's colour (Normal over itself), frames 3-4 black (Difference of a
#     colour with itself)
# Dump: LLN entry id slot lane=rel:value:ease,...; LPANEL (current slot);
# ANIMXSLO / ANIMXSLA / ANIMXSLN / ANIMXLM.
# Fixture: a 64x16 sheet of 16x16 frames, frame k a 6x6 square at (5, 5).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 XSHEET_ROWS=SMALL
# =============================================================================
info "=== Animation: the BLEND lane ==="

BL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
BL_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
BL_DIR="/tmp/draw-qa-blendlane-$$"
mkdir -p "$BL_DIR/home" "$BL_DIR/o"
BL_COLORS=(c04040 40c040 4040c0 c0c040)
BL_DRAW=()
for n in 0 1 2 3; do
    x=$(( n * 16 + 5 ))
    BL_DRAW+=(-fill "#${BL_COLORS[$n]}" -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 64x16 xc:none "${BL_DRAW[@]}" "PNG32:$BL_DIR/plain.png"
python3 "$BL_PY" put "$BL_DIR/plain.png" "$BL_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

bl_line() { grep -m1 "^$1 " "$BL_DUMPF" 2>/dev/null; }
bl_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(bl_line ANIM)"
    read -r _ _ CUR _ <<< "$(bl_line LPANEL)"
    XF=($(bl_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(bl_line ANIMXS)"
    XM=($(bl_line ANIMXLM))
    read -r _ XA_SLOT XA_Y _ <<< "$(bl_line ANIMXSLA)"
    XO_X=""; XO_Y=""; XO_OPEN=""
    read -r _ _ XO_OPEN XO_X XO_Y _ <<< "$(grep -m1 "^ANIMXSLO ${CUR:-x} " "$BL_DUMPF" 2>/dev/null)"
    LLN="$(grep -m1 "^LLN [0-9]* [0-9]* ${CUR:-x} " "$BL_DUMPF" 2>/dev/null | cut -d' ' -f5-)"
}
bl_s() { echo "frame ${A_CUR:-?}/${A_COUNT:-?} layer ${CUR:-?} lanes [${LLN}]"; }
bl_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
bl_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
bl_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
bl_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
bl_pick() {
    local iy; iy=$(bl_item "$1")
    [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; return 1; }
    bl_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); bl_read
}
bl_lane_y() { grep -m1 "^ANIMXSLN $1 $2 " "$BL_DUMPF" 2>/dev/null | cut -d' ' -f4; } # SLOT LANE
bl_batch() { # IN ARGS... - a fresh DRAW (throwaway HOME, no window)
    local in=$1; shift
    ( cd "$DRAW_ROOT" && HOME="$BL_DIR/home" XDG_CONFIG_HOME="$BL_DIR/home/.config" XDG_DATA_HOME="$BL_DIR/home/.local/share" \
      XDG_CACHE_HOME="$BL_DIR/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$in" "$@" </dev/null >>"$BL_DIR/batch.txt" 2>&1 )
}
bl_px() { magick "$1" -format '%[hex:p{8,8}]' info: 2>/dev/null | cut -c1-6 | tr 'A-F' 'a-f'; }

info "Launching DRAW with a 64x16 sheet of 16x16 frames (4, current 1, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$BL_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
bl_key ctrl+0
bl_key ctrl+shift+d
bl_key KP_8
bl_read
if [[ "$A_COUNT" != 4 || -z "$XO_X" || "${CUR:-1}" == 1 ]]; then
    fail "start: $(bl_s) arrow '${XO_X:-}' (wanted 4 frames, the X-sheet on, the copy current)"
else
    pass "a sheet of 4 frames, the layer duplicated (slot $CUR), the X-sheet on"
    # -- open the copy's lanes; + LANE offers BLEND, no VOLUME / PAN --
    bl_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); bl_read
    bl_hclick "$(bl_fmid 1)" $(( XA_Y + XLH / 2 )); bl_read
    [[ -n "$(bl_item 31112)" ]] && pass "+ LANE offers BLEND on a pixel layer" || fail "+ LANE: no BLEND in [${XM[*]}]"
    [[ -z "$(bl_item 31110)" && -z "$(bl_item 31111)" ]] && pass "+ LANE: no VOLUME / PAN on a layer" || fail "+ LANE lists VOLUME / PAN: [${XM[*]}]"
    bl_pick 31112
    [[ "$LLN" == "12=0:0:4" ]] && pass "+ LANE > BLEND: a held key on frame 1 at the layer's own mode (Normal)" || fail "+ lane BLEND: $(bl_s)"
    LY=$(bl_lane_y "$CUR" 12); YM=$(( ${LY:-0} + XLH / 2 ))

    # -- frame 3: Difference from the menu --
    right_click "$(bl_fmid 3)" "$YM"; wait_for 0.6 "lane menu"; bl_read
    if [[ -n "$(bl_item 31200)" && -n "$(bl_item 31206)" && -n "$(bl_item 31218)" ]]; then pass "the BLEND row's menu lists the modes (Normal .. Luminosity)"; else fail "BLEND menu: [${XM[*]}]"; fi
    bl_pick 31206
    [[ "$LLN" == "12=0:0:4,2:6:4" ]] && pass "Difference keyed on frame 3, held" || fail "difference key: $(bl_s)"
    screenshot "blend-lane"

    # -- undo / redo --
    bl_key ctrl+z; bl_read
    [[ "$LLN" == "12=0:0:4" ]] && pass "Ctrl+Z takes the Difference key back" || fail "undo: $(bl_s)"
    bl_key ctrl+y; bl_read
    [[ "$LLN" == "12=0:0:4,2:6:4" ]] && pass "Ctrl+Y puts it again" || fail "redo: $(bl_s)"

    # -- saved, then exported in batch --
    bl_key ctrl+s; wait_for 1.5 "saved"
    bl_batch "$BL_DIR/sheet.png" --export-anim "$BL_DIR/o/seq.png"
    GOT=""; for f in 1 2 3 4; do GOT+=" $(bl_px "$(printf "$BL_DIR/o/seq_%04d.png" "$f")")"; done; GOT="${GOT# }"
    WANT="${BL_COLORS[0]} ${BL_COLORS[1]} 000000 000000"
    [[ "$GOT" == "$WANT" ]] && pass "--export-anim: frames 1-2 Normal (the colour), 3-4 Difference (black)" || fail "exported square centres: [$GOT] want [$WANT] ($(ls "$BL_DIR/o" | tr '\n' ' ') | $(tail -2 "$BL_DIR/batch.txt" | tr '\n' ' '))"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$BL_DIR"
assert_window_exists
info "=== Animation: the BLEND lane: done ==="
