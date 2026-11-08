#!/bin/bash
# =============================================================================
# anim-lightbox-draw.sh — QA test: drawing in the lightbox panes (Animation
# 2.2, TOOLS/ANIM-LB).
#
# Every tool draws in a pane's picture: the mouse handler runs in a view that
# puts that pane's frame cell under the pointer, so a click in a pane paints
# that frame's cell, at the same canvas pixel a click there in sheet view
# would. A stroke stays inside its frame (ANIM > Clip Strokes to the Frame in
# the Lightbox, on by default) and runs over the edge with the clip off. ANIM >
# Clip Strokes to the Frame in Sheet View does the same in sheet view. Each
# stroke is one undo step that puts the frame back exactly.
#
# Dump: ANIM / ANIMC (a CRC per frame cell) as in the other animation tests;
# ANIMLB (the lightbox layout); ANIMLBP clipLightbox clipSheet, then per pane
# frame dx dy dw dh (its picture, viewport px).
# Fixture: a 64x32 sheet of 16x16 frames, 7 frames, current 3, each cell with
# its own mark.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: drawing in the lightbox ==="

LD_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LD_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LD_DIR="/tmp/draw-qa-lbdraw-$$"
mkdir -p "$LD_DIR"
LD_DRAW=()
LD_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0 e08020)
for n in 0 1 2 3 4 5 6; do
    x=$(( (n % 4) * 16 + 2 )); y=$(( (n / 4) * 16 + 2 ))
    LD_DRAW+=(-fill "#${LD_COLORS[$n]}" -draw "rectangle $x,$y $(( x + 1 + n )),$(( y + 9 ))")
done
magick -size 64x32 xc:none "${LD_DRAW[@]}" "$LD_DIR/plain.png"
LD_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$LD_PY" put "$LD_DIR/plain.png" "$LD_DIR/sheet.png" drAn "$LD_BLOB"

ld_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
ld_line() { grep -m1 "^$1 " "$LD_DUMP" 2>/dev/null; }
ld_read() { # A_CUR A_DX A_DY, A_T, T[1..7]; LB_SHOWN; P_CLIPL P_CLIPS; P_F[k] P_X[k] P_Y[k] P_W[k] P_H[k]; LB_*
    ld_settle
    read -r _ _ _ A_CUR _ _ _ _ _ _ _ _ _ A_DX A_DY _ <<< "$(ld_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(ld_line ANIMC)"
    T=(x $A_T)
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(ld_line ANIMLB)"
    local p k; p=($(ld_line ANIMLBP)); P_CLIPL=${p[1]:-}; P_CLIPS=${p[2]:-}
    P_F=(); P_X=(); P_Y=(); P_W=(); P_H=()
    for k in 0 1 2 3 4 5 6; do
        P_F[$k]=${p[$((3 + 5 * k))]:-0}; P_X[$k]=${p[$((4 + 5 * k))]:-0}; P_Y[$k]=${p[$((5 + 5 * k))]:-0}
        P_W[$k]=${p[$((6 + 5 * k))]:-0}; P_H[$k]=${p[$((7 + 5 * k))]:-0}
    done
}
ld_key() { park_mouse; key "$1"; wait_for 0.4 "$1"; }
ld_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 0.6 "$1"
}
ld_changed() { # BEFORE-TOKENS -> the frame numbers whose CRC differs now
    local b=(x $1) out="" n
    for n in 1 2 3 4 5 6 7; do [[ "${b[$n]}" != "${T[$n]}" ]] && out+=" $n"; done
    echo "${out# }"
}
ld_px() { # K U V -> the viewport point over pixel (U, V) of pane K's frame cell
    local z=$(( P_W[$1] / 16 ))
    echo "$(( P_X[$1] + $2 * z + z / 2 )) $(( P_Y[$1] + $3 * z + z / 2 ))"
}

info "Launching DRAW with a 64x32 sheet of 16x16 frames (7, current 3)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LD_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key ctrl+0
wait_for 0.5 "Zoom 100%"
key b
wait_for 0.3 "Brush"

ld_read
LD_SHEET_DX=$A_DX; LD_SHEET_DY=$A_DY
LD_T0="$A_T"
ld_key KP_0
ld_read
if [[ "${LB_SHOWN:-}" != -1 || "${P_F[1]:-}" != 3 || "${P_CLIPL:-}" != -1 || "${P_CLIPS:-}" != 0 ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', middle pane frame '${P_F[1]:-}', clip lightbox '${P_CLIPL:-}' sheet '${P_CLIPS:-}' (wanted -1 / 3 / -1 / 0)"
else
    pass "lightbox: panes 2 3 4, clip on in the lightbox and off in sheet view"
    info "panes: frame ${P_F[0]} at ${P_X[0]},${P_Y[0]} ${P_W[0]}x${P_H[0]}; frame 3 at ${P_X[1]},${P_Y[1]}; frame 4 at ${P_X[2]},${P_Y[2]}"

    # -- a click in a pane paints its frame, at the pixel sheet view would --
    read -r LX LY <<< "$(ld_px 1 5 12)"
    click "$LX" "$LY"; wait_for 0.4 "click in the middle pane"
    ld_read
    LD_CH=$(ld_changed "$LD_T0")
    [[ "$LD_CH" == 3 ]] && pass "a click in the middle pane paints frame 3 only" || fail "middle-pane click changed frames [$LD_CH] (wanted 3)"
    LD_LB_DOT="${T[3]}"
    ld_key ctrl+z; ld_read
    [[ "$A_T" == "$LD_T0" ]] && pass "undo: frame 3 back exactly" || fail "undo of the pane click: [$LD_T0] -> [$A_T]"

    read -r LX LY <<< "$(ld_px 0 5 12)"
    click "$LX" "$LY"; wait_for 0.4 "click in the left pane"
    ld_read
    LD_CH=$(ld_changed "$LD_T0")
    [[ "$LD_CH" == 2 ]] && pass "a click in the left pane paints frame 2 only" || fail "left-pane click changed frames [$LD_CH] (wanted 2)"
    ld_key ctrl+z; ld_read

    # -- clip on: a stroke dragged out of the pane stays in its frame --
    read -r SX SY <<< "$(ld_px 1 8 8)"
    read -r EX EY <<< "$(ld_px 2 8 8)"
    drag "$SX" "$SY" "$EX" "$EY"; wait_for 0.5 "stroke from pane 3 into pane 4"
    ld_read
    LD_CH=$(ld_changed "$LD_T0")
    [[ "$LD_CH" == 3 ]] && pass "clip on: a stroke dragged into the next pane stays in frame 3" || fail "clipped stroke changed frames [$LD_CH] (wanted 3)"
    ld_key ctrl+z; ld_read
    [[ "$A_T" == "$LD_T0" ]] && pass "undo the clipped stroke: one step, frames back exactly" || fail "undo clipped stroke: [$LD_T0] -> [$A_T]"

    # -- clip off: the same stroke runs into frame 4 --
    ld_cmd "clip strokes to the frame in the lightbox"
    ld_read
    [[ "$P_CLIPL" == 0 ]] && pass "Clip Strokes to the Frame in the Lightbox: off" || fail "clip toggle: '$P_CLIPL'"
    drag "$SX" "$SY" "$EX" "$EY"; wait_for 0.5 "stroke, clip off"
    ld_read
    LD_CH=$(ld_changed "$LD_T0")
    [[ "$LD_CH" == "3 4" ]] && pass "clip off: the stroke runs on into frame 4" || fail "unclipped stroke changed frames [$LD_CH] (wanted 3 4)"
    ld_key ctrl+z; ld_read
    [[ "$A_T" == "$LD_T0" ]] && pass "undo the unclipped stroke" || fail "undo unclipped stroke: [$LD_T0] -> [$A_T]"
    ld_cmd "clip strokes to the frame in the lightbox"

    # -- the rectangle tool: its drag lands in the pane's frame --
    park_mouse; key r; wait_for 0.3 "Rectangle"
    read -r SX SY <<< "$(ld_px 0 3 3)"
    read -r EX EY <<< "$(ld_px 0 12 13)"
    drag "$SX" "$SY" "$EX" "$EY"; wait_for 0.5 "rectangle in pane 2"
    ld_read
    LD_CH=$(ld_changed "$LD_T0")
    [[ "$LD_CH" == 2 ]] && pass "a rectangle dragged in the left pane draws in frame 2 only" || fail "rectangle changed frames [$LD_CH] (wanted 2)"
    ld_key ctrl+z
    # its preview while dragging shows in the pane (drawn through the pane's view)
    LD_PV_X=${P_X[0]}; LD_PV_Y=${P_Y[0]}; LD_PV_W=${P_W[0]}; LD_PV_H=${P_H[0]}
    park_mouse
    snap_region "$LD_PV_X" "$LD_PV_Y" "$LD_PV_W" "$LD_PV_H" "pane2-before"; LD_PV0="$SNAP_RESULT"
    mouse_down "$SX" "$SY"
    hover "$EX" "$EY"; sleep 0.3; hover $(( EX + 1 )) "$EY"; sleep 0.3
    snap_region "$LD_PV_X" "$LD_PV_Y" "$LD_PV_W" "$LD_PV_H" "pane2-dragging"; LD_PV1="$SNAP_RESULT"
    mouse_up; wait_for 0.4 "rectangle released"
    assert_regions_differ "$LD_PV0" "$LD_PV1" "the rectangle's preview shows in the pane while dragging"
    ld_key ctrl+z
    park_mouse; key b; wait_for 0.3 "Brush"

    # -- a press outside the pictures draws nothing --
    ld_read
    click $(( P_X[1] + P_W[1] / 2 )) $(( P_Y[1] + P_H[1] + 2 )); wait_for 0.4 "click under the middle picture"
    click $(( LB_X1 + LB_PAD + LB_CW / 2 )) $(( LB_SY + LB_PAD + LB_CH / 2 )); wait_for 0.4 "click in the strip"
    ld_read
    [[ "$A_T" == "$LD_T0" ]] && pass "presses outside the pane pictures draw nothing" || fail "outside presses drew: [$LD_T0] -> [$A_T]"

    # -- sheet view: the same dot at the same canvas pixel --
    ld_key KP_0
    click $(( LD_SHEET_DX + 32 + 5 )) $(( LD_SHEET_DY + 12 )); wait_for 0.4 "click in sheet view"
    ld_read
    [[ "${T[3]}" == "$LD_LB_DOT" && "$(ld_changed "$LD_T0")" == 3 ]] && pass "the pane click painted the very pixel a sheet-view click does" \
        || fail "sheet-view dot: frame 3 ${T[3]}, pane dot $LD_LB_DOT (changed [$(ld_changed "$LD_T0")])"
    ld_key ctrl+z; ld_read

    # -- sheet view: clip off by default, on with the menu item --
    drag $(( LD_SHEET_DX + 40 )) $(( LD_SHEET_DY + 8 )) $(( LD_SHEET_DX + 56 )) $(( LD_SHEET_DY + 8 )); wait_for 0.5 "sheet stroke"
    ld_read
    LD_CH=$(ld_changed "$LD_T0")
    [[ "$LD_CH" == "3 4" ]] && pass "sheet view: a stroke runs across frames (clip off)" || fail "sheet stroke changed frames [$LD_CH] (wanted 3 4)"
    ld_key ctrl+z; ld_read
    ld_cmd "clip strokes to the frame in sheet view"
    drag $(( LD_SHEET_DX + 40 )) $(( LD_SHEET_DY + 8 )) $(( LD_SHEET_DX + 56 )) $(( LD_SHEET_DY + 8 )); wait_for 0.5 "sheet stroke, clipped"
    ld_read
    LD_CH=$(ld_changed "$LD_T0")
    [[ "$P_CLIPS" == -1 && "$LD_CH" == 3 ]] && pass "Clip Strokes to the Frame in Sheet View: the stroke stays in frame 3" \
        || fail "sheet clip '$P_CLIPS': stroke changed frames [$LD_CH] (wanted 3)"
    ld_key ctrl+z; ld_read
    [[ "$A_T" == "$LD_T0" ]] && pass "undo the clipped sheet stroke" || fail "undo clipped sheet stroke: [$LD_T0] -> [$A_T]"
    ld_cmd "clip strokes to the frame in sheet view"
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LD_DIR"
assert_window_exists
