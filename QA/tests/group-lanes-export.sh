#!/bin/bash
# =============================================================================
# group-lanes-export.sh — QA test: keyframe lanes on a GROUP, and the exports
# (branch xsheet-holds-lanes, TOOLS/LAYER-LANES + TOOLS/ANIM-XLANE).
#
#   - group the layer (Ctrl+Shift+G): the group's X-sheet row has its own
#     lanes arrow
#   - + LANE > Y on the group; key frame 1 = 3, frame 6 = -3 (linear)
#   - the child's drawing moves by the group's Y in every frame (its display),
#     the group keeps no picture of its own, the pixels are untouched
#   - Ctrl+S, then a batch --export-anim to a PNG sequence and an animated GIF:
#     each exported frame has the drawing where the lanes put it
#
# Dump: LLN entry historyId slot lane=rel:value:ease,... ; LLD slot
# f:x0,y0,x1,y1 (what each frame cell shows); ANIMXSLO / ANIMXSLA / ANIMXLM.
# Fixture: a 96x16 sheet of 16x16 frames, frame k a 6x6 square at (5, 5) of
# its own colour; 6 frames, current 1. One layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Animation: keyframe lanes on a group + the exports ==="

GL_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
GL_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
GL_DIR="/tmp/draw-qa-glanes-$$"
mkdir -p "$GL_DIR/home" "$GL_DIR/o"
GL_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
GL_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 + 5 ))
    GL_DRAW+=(-fill "#${GL_COLORS[$n]}" -draw "rectangle $x,5 $(( x + 5 )),10")
done
magick -size 96x16 xc:none "${GL_DRAW[@]}" "PNG32:$GL_DIR/plain.png"
python3 "$GL_PY" put "$GL_DIR/plain.png" "$GL_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

gl_line() { grep -m1 "^$1 " "$GL_DUMPF" 2>/dev/null; }
gl_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(gl_line ANIM)"
    C=($(gl_line ANIMC))
    XF=($(gl_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(gl_line ANIMXS)"
    XM=($(gl_line ANIMXLM))
    read -r _ XA_SLOT XA_Y _ <<< "$(gl_line ANIMXSLA)"
    GRP=""; GRP_OPEN=""; GRP_X=""; GRP_Y=""
    while read -r _ s o x y _; do
        [[ "$s" != 1 ]] && { GRP=$s; GRP_OPEN=$o; GRP_X=$x; GRP_Y=$y; }
    done < <(grep "^ANIMXSLO " "$GL_DUMPF" 2>/dev/null)
    LLN_ALL="$(grep '^LLN ' "$GL_DUMPF" 2>/dev/null | cut -d' ' -f4- | tr '\n' '|')"
    LLD1="$(grep -m1 '^LLD 1 ' "$GL_DUMPF" 2>/dev/null | cut -d' ' -f3-)"
    LLD_N=$(grep -c '^LLD ' "$GL_DUMPF" 2>/dev/null)
}
gl_cells() { echo "${C[*]:1}"; }
gl_s() { echo "frame ${A_CUR:-?}/${A_COUNT:-?} group '${GRP}' open ${GRP_OPEN:-?} lanes [${LLN_ALL}] child shows [${LLD1}] displays ${LLD_N:-?}"; }
gl_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
gl_hclick() { mouse_down "$1" "$2"; sleep 0.15; mouse_up; wait_for 0.5 "click"; }
gl_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
gl_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
gl_pick() {
    local iy; iy=$(gl_item "$1")
    [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; return 1; }
    gl_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); gl_read
}
gl_lane_y() { grep -m1 "^ANIMXSLN $1 $2 " "$GL_DUMPF" 2>/dev/null | cut -d' ' -f4; } # SLOT LANE
gl_type_at() { # X Y TEXT - double-click a key, type its value
    double_click "$1" "$2"; wait_for 0.9 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $3"; gl_read
}
gl_batch() { # IN ARGS... - a fresh DRAW (throwaway HOME, no window)
    local in=$1; shift
    ( cd "$DRAW_ROOT" && HOME="$GL_DIR/home" XDG_CONFIG_HOME="$GL_DIR/home/.config" XDG_DATA_HOME="$GL_DIR/home/.local/share" \
      XDG_CACHE_HOME="$GL_DIR/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$in" "$@" </dev/null >>"$GL_DIR/batch.txt" 2>&1 )
}
gl_trim() { magick "$1" -format "%@" info: 2>/dev/null; } # the drawing's box: WxH+X+Y

# Y = 3 -> -3 linear over frames 1-6 (whole pixels, half up): 3, 2, 1, -1, -2, -3
GL_Y=(3 2 1 -1 -2 -3)
GL_WANT=""; for f in 1 2 3 4 5 6; do y=${GL_Y[$((f - 1))]}; GL_WANT+=" $f:5,$(( 5 + y )),10,$(( 10 + y ))"; done; GL_WANT="${GL_WANT# }"

info "Launching DRAW with a 96x16 sheet of 16x16 frames (6, current 1, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$GL_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
gl_key ctrl+0
gl_key ctrl+shift+g
gl_key KP_8
gl_read
C0="$(gl_cells)"
if [[ "$A_COUNT" != 6 || -z "$GRP" || "$GRP_OPEN" != 0 ]]; then
    fail "start: $(gl_s) (wanted 6 frames, the X-sheet on, a group row with its lanes arrow)"
else
    pass "Group from the layer: the group's X-sheet row has its own lanes arrow (slot $GRP)"

    # -- open the group's lanes, + LANE > Y --
    gl_hclick $(( GRP_X + 4 )) $(( GRP_Y + XLH / 2 )); gl_read
    [[ "$GRP_OPEN" == -1 && "$XA_SLOT" == "$GRP" ]] && pass "the arrow opens the group's lanes: + LANE" || fail "open: $(gl_s) add '${XA_SLOT:-}'"
    gl_hclick "$(gl_fmid 1)" $(( XA_Y + XLH / 2 )); gl_read
    gl_pick 31102
    LY=$(gl_lane_y "$GRP" 2); YM=$(( ${LY:-0} + XLH / 2 ))
    [[ -n "$LY" && "$LLN_ALL" == "$GRP 2=0:0:0|" ]] && pass "+ LANE > Y on the group: a Y row, a key on frame 1" || fail "+ lane Y: $(gl_s) menu [${XM[*]}]"

    # -- frame 1 = 3, frame 6 = -3 --
    gl_type_at "$(gl_fmid 1)" "$YM" 3
    double_click "$(gl_fmid 6)" "$YM"; wait_for 0.6 "add key"; gl_read
    gl_type_at "$(gl_fmid 6)" "$YM" -3
    [[ "$LLN_ALL" == "$GRP 2=0:3:0,5:-3:0|" ]] && pass "the group's Y: 3 on frame 1, -3 on frame 6" || fail "keys: $(gl_s)"
    [[ "$LLD1" == "$GL_WANT" && "$LLD_N" == 1 ]] && pass "the child shows its drawing moved by the group's Y (3 2 1 -1 -2 -3); the group has no display of its own" || fail "child display: [$LLD1] want [$GL_WANT] ($LLD_N displays)"
    [[ "$(gl_cells)" == "$C0" ]] && pass "the child's pixels are untouched" || fail "pixels changed"
    screenshot "group-lanes"

    # -- saved, then exported in batch --
    gl_key ctrl+s; wait_for 1.5 "saved"
    gl_batch "$GL_DIR/sheet.png" --export-anim "$GL_DIR/o/seq.png" --export-anim "$GL_DIR/o/anim.gif"
    GOT=""; for f in 1 2 3 4 5 6; do GOT+=" $(gl_trim "$(printf "$GL_DIR/o/seq_%04d.png" "$f")")"; done; GOT="${GOT# }"
    WANT=""; for f in 1 2 3 4 5 6; do WANT+=" 6x6+5+$(( 5 + GL_Y[f - 1] ))"; done; WANT="${WANT# }"
    [[ "$GOT" == "$WANT" ]] && pass "--export-anim seq.png: each PNG has the drawing where the group's Y puts it" || fail "PNG sequence: [$GOT] want [$WANT] ($(ls "$GL_DIR/o" | tr '\n' ' ') | $(tail -2 "$GL_DIR/batch.txt" | tr '\n' ' '))"
    GIFT=$(magick "$GL_DIR/o/anim.gif" -coalesce -format "%@ " info: 2>/dev/null | sed 's/ $//')
    [[ "$GIFT" == "$WANT" ]] && pass "--export-anim anim.gif: each GIF frame likewise" || fail "GIF: [$GIFT] want [$WANT]"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$GL_DIR"
assert_window_exists
info "=== Animation: keyframe lanes on a group + the exports: done ==="
