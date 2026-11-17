#!/bin/bash
# =============================================================================
# rec-tools.sh — QA test: the existing tools record keys on an armed layer
# (TOOLS/ANIM-XLANE).
#
# Rick 2026-11-16: "yes existing tools should record too. yes flip can use
# negative, love it. we don't need a separate lane for flip."
#
#   - armed, Move tool drag on the canvas: X key at the current frame (Y 0),
#     the layer's pixels untouched
#   - Ctrl+Z / Ctrl+Y: the layer's first key (no lanes before) undone / back
#   - an arrow nudge (Move tool): X one more
#   - Ctrl+Z: the nudge undone (one undo step per gesture)
#   - Image > Flip Horizontal (Home): SCALE X -100 (a negated SCALE key), pixels kept
#   - the wheel on the Layers panel's opacity bar: an OPACITY key (~94%)
#   - disarmed: the layer's dot purple (keyed, not armed)
#   - not armed: Flip Horizontal flips the pixels as before
#   - armed again, Transform Scale: the bottom-right handle dragged 32 px
#     right, Enter: a SCALE X key (the box ~2.4x wider), SCALE Y 100, the overlay gone, pixels kept
#
# Dump: LLN (keys: lane=frame:value:ease), XLREC (slot:dot 1 ring 2 purple
# 3 red), ANIMC (pixels), VIEW (zoom), CVORG (canvas origin), HIST, XFQ (transform on, mode, quad), LPREC (dot x), LPGEO.
# Fixture: a 64x16 sheet of 16x16 frames, 4 frames, one layer; 4x10 blocks
# (tall enough that the transform's corner handles don't overlap).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 LAYER_THUMBNAILS=0
# =============================================================================
info "=== Animation: Move / nudge / flip / opacity record keys on an armed layer ==="

RT_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
RT_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
RT_DIR="/tmp/draw-qa-rectools-$$"
mkdir -p "$RT_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 2,3 5,12' -fill '#40c040' -draw 'rectangle 21,3 24,12' "PNG32:$RT_DIR/plain.png"
python3 "$RT_PY" put "$RT_DIR/plain.png" "$RT_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,10,0,0).hex())")"

rt_line() { grep -m1 "^$1 " "$RT_DUMPF" 2>/dev/null; }
rt_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(rt_line ANIM)"
    C="$(rt_line ANIMC | cut -d' ' -f2-)"
    LLN="$(rt_line LLN | cut -d' ' -f5-)"
    DOT=$(rt_line XLREC | tr ' ' '\n' | grep '^1:' | cut -d: -f2)
    read -r _ V_ZOOM V_OX V_OY V_TOOL _ <<< "$(rt_line VIEW)"
    read -r _ LPX _ <<< "$(rt_line LPREC)"
    read -r _ LPTOP LPRH _ <<< "$(rt_line LPGEO)"
    read -r _ CVX CVY _ <<< "$(rt_line CVORG)"
    read -r _ H_CUR H_N _ <<< "$(rt_line HIST)"
    read -r _ XF_ON XF_MODE XF_Q _ <<< "$(rt_line XFQ)"
    XQ=($(rt_line XFQ | cut -d' ' -f4-))
}
rt_lane() { # LANE -> "frame:value:ease,..." of that lane, or empty
    tr ' ' '\n' <<< "$LLN" | grep "^$1=" | cut -d= -f2
}
rt_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
rt_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
rt_s() { echo "lanes [${LLN}] dot ${DOT:-?} tool ${V_TOOL:-?}"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$RT_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
rt_key ctrl+0
rt_read
C0="$C"
if [[ "$A_COUNT" != 4 || "$A_CUR" != 1 ]]; then
    fail "start: $A_COUNT frames, current '${A_CUR:-}'"
else
    rt_cmd "arm layer for recording"; rt_read
    [[ "$DOT" == 3 ]] || fail "arming: dot '${DOT:-}'"

    # -- the Move tool drags: X / Y keys, no pixel change --
    rt_key v; rt_read
    Z=$(( V_ZOOM > 0 ? V_ZOOM : 100 ))
    MX=$(( CVX + 8 * Z / 100 )); MY=$(( CVY + 8 * Z / 100 ))
    DX=$(( 4 * Z / 100 ))
    drag "$MX" "$MY" $(( MX + DX )) "$MY"; wait_for 0.8 "move drag"
    rt_read
    LX="$(rt_lane 1)"; LY="$(rt_lane 2)"
    if [[ "$LX" == 0:4:* && ( -z "$LY" || "$LY" == 0:0:* ) && "$C" == "$C0" ]]; then
        pass "armed: a Move tool drag of 4 canvas px keys X = 4 on frame 1, the pixels stay"
    else
        fail "move drag (zoom $Z, $MX,$MY +$DX): X '$LX' Y '$LY', pixels $([[ "$C" == "$C0" ]] && echo same || echo CHANGED) - $(rt_s)"
    fi

    # -- the layer's first key: Ctrl+Z takes it away, Ctrl+Y puts it back --
    rt_key ctrl+z; rt_read
    [[ -z "$(rt_lane 1)" ]] && pass "Ctrl+Z: the layer's first recorded key undone (no lanes)" || fail "undo the first key: X '$(rt_lane 1)' - $(rt_s)"
    rt_key ctrl+y; rt_read
    [[ "$(rt_lane 1)" == 0:4:* ]] && pass "Ctrl+Y: back (X = 4)" || fail "redo the first key: X '$(rt_lane 1)' - $(rt_s)"

    # -- an arrow nudge --
    rt_key Right; rt_read
    H1="$H_CUR/$H_N"
    [[ "$(rt_lane 1)" == 0:5:* && "$C" == "$C0" ]] && pass "an arrow nudge (Move tool): X = 5" || fail "nudge: X '$(rt_lane 1)' - $(rt_s)"
    rt_key ctrl+z; rt_read
    [[ "$(rt_lane 1)" == 0:4:* ]] && pass "Ctrl+Z: the nudge alone undone (X = 4)" || fail "undo nudge: X '$(rt_lane 1)' history $H1 -> $H_CUR/$H_N - $(rt_s)"

    # -- flip: a negated SCALE X key --
    rt_key Home; rt_read
    [[ "$(rt_lane 3)" == 0:-100:* && "$C" == "$C0" ]] && pass "Flip Horizontal on an armed layer: SCALE X -100 on frame 1, the pixels stay" \
        || fail "flip: SCALE X '$(rt_lane 3)', pixels $([[ "$C" == "$C0" ]] && echo same || echo CHANGED) - $(rt_s)"
    screenshot "rec-tools-flipped"

    # -- opacity: the wheel on the Layers panel's opacity bar --
    if [[ "${LPX:-0}" -gt 0 ]]; then
        scroll_down $(( LPX + 8 )) $(( LPTOP + LPRH / 2 )); wait_for 0.6 "wheel on the opacity bar"
        rt_read
        OP="$(rt_lane 6)"
        [[ "$OP" == 0:9[0-9]* ]] && pass "the wheel on the opacity bar: an OPACITY key ($OP)" || fail "opacity wheel: OPACITY '$OP' - $(rt_s)"
    else
        fail "no Layers panel dot to find the opacity bar (LPREC '${LPX:-}')"
    fi

    # -- disarmed: purple --
    rt_cmd "disarm all layers"; rt_read
    [[ "$DOT" == 2 ]] && pass "disarmed with keys: the dot is purple" || fail "after disarm: dot '${DOT:-}'"

    # -- not armed: Flip flips the pixels as before --
    rt_key Home; rt_read
    [[ "$C" != "$C0" ]] && pass "not armed: Flip Horizontal flips the pixels as before" || fail "unarmed flip: pixels unchanged - $(rt_s)"

    # -- Transform (Scale) on an armed layer: SCALE keys, pixels kept --
    rt_key ctrl+z; rt_read # the unarmed flip undone: frame 1's block back in frame 1
    rt_cmd "arm layer for recording"; rt_read
    C1="$C"
    rt_cmd "transform scale"; rt_read
    if [[ "$XF_ON" == -1 && ${#XQ[@]} -ge 8 ]]; then
        XQ0="${XQ[*]}"
        BX=$(( CVX + XQ[4] * Z / 100 )); BY=$(( CVY + XQ[5] * Z / 100 ))
        drag "$BX" "$BY" $(( BX + 32 * Z / 100 )) "$BY"; wait_for 0.8 "drag the bottom-right handle"
        rt_read; XQD="${XQ[*]}"
        rt_key Return; rt_read
        SXK="$(rt_lane 3)"
        if [[ "$XF_ON" == 0 && "$C" == "$C1" && "$SXK" == 0:[1-3][0-9][0-9]* && ( -z "$(rt_lane 4)" || "$(rt_lane 4)" == 0:100:* ) ]]; then
            pass "Transform Scale committed on an armed layer: SCALE X $SXK (Y $(rt_lane 4)) on frame 1, the pixels stay"
        else
            fail "transform record (quad ${XQ0:-} -> $XQD, dragged from $BX,$BY zoom $Z): overlay on '$XF_ON', SCALE X '$SXK', pixels $([[ "$C" == "$C1" ]] && echo same || echo CHANGED) - $(rt_s)"
        fi
        screenshot "rec-tools-transform"
    else
        fail "Transform Scale did not start: XFQ '$(rt_line XFQ)'"
    fi
fi
assert_no_crash
rm -rf "$RT_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
