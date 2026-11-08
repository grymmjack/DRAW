#!/bin/bash
# =============================================================================
# anim-lightbox-zoom.sh — QA test: zooming in the lightbox and in the Preview's
# frame view.
#
# Rick, 2026-11-08 (field kit T-9): "Zoom doesn't work on the lightbox", and
# the Preview window didn't zoom while it showed the frame. Every lightbox pane
# shows its frame at one shared zoom (0 = fitted): Ctrl+wheel zooms about the
# pointer (the frame pixel under it stays there), Shift+wheel pans, Ctrl+= /
# Ctrl+- zoom, Ctrl+0 fits again; the plain wheel steps through the frames
# (Rick: "mousewheel could do the scrubber over the lightbox, ctrl+mousewheel =
# zoom"). A frame bigger than its pane stops at the
# pane's edge. A click in a zoomed pane paints the pixel under the pointer.
# The Preview's frame view has its own wheel zoom.
#
# Dump: ANIMLBP (per pane: frame dx dy dw dh - the whole picture, which may be
# bigger than the pane), ANIMLBZ zoom% rx ry, ANIMPV zoom% rx ry, ANIMC (a CRC
# per frame cell), WIN preview x y w h.
# Fixture: a 256x128 sheet of 64x64 frames (7, current 3), each cell its own
# colour with a mark.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LIGHTBOX=1 XSHEET=0 LIGHTBOX_PANES=3 PREVIEW_SHOWS_FRAME=1
# =============================================================================
info "=== Animation: zoom in the lightbox and the Preview frame view ==="

LZ_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LZ_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LZ_DIR="/tmp/draw-qa-lbzoom-$$"
mkdir -p "$LZ_DIR"
LZ_DRAW=()
LZ_BG=(402020 204020 202040 404020 402040 204040 403020 303030)
LZ_FG=(e06060 60e060 6060e0 e0e060 e060e0 60e0e0 e0a040 c0c0c0)
for n in 0 1 2 3 4 5 6 7; do
    x=$(( (n % 4) * 64 )); y=$(( (n / 4) * 64 ))
    LZ_DRAW+=(-fill "#${LZ_BG[$n]}" -draw "rectangle $x,$y $(( x + 63 )),$(( y + 63 ))")
    LZ_DRAW+=(-fill "#${LZ_FG[$n]}" -draw "rectangle $(( x + 8 )),$(( y + 8 )) $(( x + 20 + n * 3 )),$(( y + 40 ))")
done
magick -size 256x128 xc:none "${LZ_DRAW[@]}" "$LZ_DIR/plain.png"
LZ_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,64,64,0,0,7,3,12,0,0).hex())")
python3 "$LZ_PY" put "$LZ_DIR/plain.png" "$LZ_DIR/sheet.png" drAn "$LZ_BLOB"

lz_settle() { { hover 5 300; wait_for 0.15 "render"; hover 6 302; wait_for 0.25 "render"; } >&2; }
lz_line() { grep -m1 "^$1 " "$LZ_DUMP" 2>/dev/null; }
lz_read() { # [NOSETTLE] -> Z RX RY, P_X/Y/W/H for the middle pane, LB_*, T[1..7], PVZ
    [[ "${1:-}" == nosettle ]] || lz_settle
    read -r _ _ _ A_CUR _ <<< "$(lz_line ANIM)"
    read -r _ Z RX RY _ <<< "$(lz_line ANIMLBZ)"
    read -r _ PVZ _ <<< "$(lz_line ANIMPV)"
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(lz_line ANIMLB)"
    local p; p=($(lz_line ANIMLBP))
    P_F=${p[8]:-0}; P_X=${p[9]:-0}; P_Y=${p[10]:-0}; P_W=${p[11]:-0}; P_H=${p[12]:-0}
    local t; t=""; read -r _ t <<< "$(lz_line ANIMC)"; T=(x $t)
    info "  lightbox area x ${LB_X1:-}..${LB_X2:-}, pane ${LB_PW:-}x${LB_PH:-}, frame $A_CUR, zoom ${Z:-}%"
}
lz_at() { # U V -> the viewport point over pixel (U, V) of the middle pane's frame
    echo "$(( P_X + ($1 * P_W) / 64 + P_W / 128 )) $(( P_Y + ($2 * P_H) / 64 + P_H / 128 ))"
}
lz_uv() { # X Y -> the frame pixel under that viewport point in the middle pane
    echo "$(( (($1 - P_X) * 64) / P_W )) $(( (($2 - P_Y) * 64) / P_H ))"
}
lz_bands() { # LABEL: the strip band + transport bar (never drawn on by a pane)
    snap_region "$LB_X1" "$LB_SY" $(( LB_X2 - LB_X1 + 1 )) $(( LB_SH + LB_BH )) "$1"
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LZ_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"

lz_read
if [[ "${LB_SHOWN:-}" != -1 || "$P_F" != 3 ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', middle pane frame '$P_F' (wanted -1 / 3)"
else
    Z0=$(( (P_W * 100) / 64 ))
    info "fitted: middle pane picture ${P_W}x${P_H} at $P_X,$P_Y (zoom ${Z0}%), pane ${LB_PW}x${LB_PH}; lightbox zoom '${Z:-}'"
    [[ "${Z:-}" == 0 ]] && pass "the panes start fitted (ANIMLBZ 0)" || fail "start: ANIMLBZ '${Z:-}', wanted 0"

    # The first press can change the layout (user profile: a panel docks at the
    # right), so one warm-up click + undo first, then the layout is read again.
    read -r AX AY <<< "$(lz_at 20 30)"
    click "$AX" "$AY"; wait_for 0.4 "warm-up click"
    key ctrl+z; wait_for 0.5 "undo"
    lz_read

    # -- a click at the fitted size paints frame pixel (20, 30): the reference --
    Z0=$(( (P_W * 100) / 64 ))
    read -r AX AY <<< "$(lz_at 20 30)"
    T0=("${T[@]}")
    click "$AX" "$AY"; wait_for 0.4 "click at (20, 30), fitted"
    lz_read; CRC_FIT=${T[3]}
    [[ "$CRC_FIT" != "${T0[3]}" ]] && pass "fitted click painted frame 3" || fail "fitted click: frame 3 CRC unchanged"
    key ctrl+z; wait_for 0.5 "undo"
    lz_read

    lz_bands "lbzoom-bands-before"; cp "$SNAP_RESULT" "$LZ_DIR/bands0.png"
    snap_region $(( LB_X1 + LB_PAD + LB_PW + LB_PAD )) $(( LB_EY + LB_PAD )) "$LB_PW" "$LB_PH" "lbzoom-pane-before"; cp "$SNAP_RESULT" "$LZ_DIR/pane0.png"

    # -- the plain wheel steps through the frames --
    scroll_down "$AX" "$AY"; wait_for 0.4 "wheel down"
    lz_read nosettle
    [[ "$A_CUR" == 4 ]] && pass "wheel down over the panes: frame 4" || fail "wheel down over the panes: current frame '$A_CUR', wanted 4"
    scroll_up "$AX" "$AY"; wait_for 0.4 "wheel up"
    lz_read nosettle
    [[ "$A_CUR" == 3 && "${Z:-}" == 0 ]] && pass "wheel up: back to frame 3, still fitted" || fail "wheel up: frame '$A_CUR' zoom '${Z:-}', wanted 3 / 0"

    # -- Ctrl+wheel zooms the panes about the pointer --
    with_mods ctrl scroll_up "$AX" "$AY"; wait_for 0.4 "Ctrl+wheel up"
    with_mods ctrl scroll_up "$AX" "$AY"; wait_for 0.4 "Ctrl+wheel up"
    with_mods ctrl scroll_up "$AX" "$AY"; wait_for 0.4 "Ctrl+wheel up"
    lz_read nosettle
    if [[ "${Z:-0}" =~ ^[0-9]+$ ]] && (( Z > Z0 )); then
        pass "Ctrl+wheel zooms the panes: ${Z0}% -> ${Z}%"
    else
        fail "Ctrl+wheel over a pane did not zoom it: ANIMLBZ '${Z:-}' (fitted ${Z0}%)"
    fi
    [[ "$A_CUR" == 3 ]] && pass "Ctrl+wheel leaves the frame (3)" || fail "Ctrl+wheel moved to frame '$A_CUR'"
    read -r U V <<< "$(lz_uv "$AX" "$AY")"
    [[ "$U" == 20 && "$V" == 30 ]] && pass "the frame pixel under the pointer stays there (20, 30)" \
        || fail "after zooming the pointer is over frame pixel ($U, $V), wanted (20, 30)"
    (( P_W > LB_PW || P_H > LB_PH )) && pass "zoomed past the pane: picture ${P_W}x${P_H} in a ${LB_PW}x${LB_PH} pane" \
        || fail "picture ${P_W}x${P_H} still fits the ${LB_PW}x${LB_PH} pane - the clip test is not exercised"
    snap_region $(( LB_X1 + LB_PAD + LB_PW + LB_PAD )) $(( LB_EY + LB_PAD )) "$LB_PW" "$LB_PH" "lbzoom-pane-zoomed"
    assert_regions_differ "$LZ_DIR/pane0.png" "$SNAP_RESULT" "the middle pane shows the frame bigger"
    lz_bands "lbzoom-bands-zoomed"
    assert_regions_same "$LZ_DIR/bands0.png" "$SNAP_RESULT" "a zoomed pane stops at its edge (strip + bar untouched)" 0

    # -- a click in the zoomed pane paints the pixel under the pointer --
    click "$AX" "$AY"; wait_for 0.4 "click at (20, 30), zoomed"
    lz_read
    [[ "${T[3]}" == "$CRC_FIT" ]] && pass "zoomed click paints frame 3 exactly as the fitted click did" \
        || fail "zoomed click: frame 3 CRC '${T[3]}', the fitted click gave '$CRC_FIT'"
    LZ_OTHER=""
    for n in 1 2 4 5 6 7; do [[ "${T[$n]}" != "${T0[$n]}" ]] && LZ_OTHER+=" $n"; done
    [[ -z "$LZ_OTHER" ]] && pass "no other frame changed" || fail "frames [$LZ_OTHER ] changed too"
    key ctrl+z; wait_for 0.5 "undo"

    # -- Shift+wheel pans it --
    RY0=$RY
    with_mods shift scroll_down "$AX" "$AY"; wait_for 0.4 "Shift+wheel"
    with_mods shift scroll_down "$AX" "$AY"; wait_for 0.4 "Shift+wheel"
    lz_read
    if (( P_H > LB_PH )); then
        [[ "$RY" != "$RY0" ]] && pass "Shift+wheel pans the zoomed panes (ry $RY0 -> $RY)" || fail "Shift+wheel: ry stayed $RY0"
    else
        info "picture not taller than the pane - Shift+wheel pan not checked"
    fi

    # -- Ctrl+- zooms out, Ctrl+0 fits --
    ZB=$Z
    park_mouse; key ctrl+minus; wait_for 0.4 "Ctrl+-"
    lz_read
    [[ "${Z:-0}" =~ ^[0-9]+$ ]] && (( Z < ZB )) && pass "Ctrl+- zooms the panes out (${ZB}% -> ${Z}%)" || fail "Ctrl+-: ANIMLBZ '${Z:-}' (was $ZB)"
    park_mouse; key ctrl+0; wait_for 0.4 "Ctrl+0"
    lz_read
    [[ "${Z:-}" == 0 && "$P_W" == $(( Z0 * 64 / 100 )) ]] && pass "Ctrl+0: the panes are fitted again" || fail "Ctrl+0: ANIMLBZ '${Z:-}', picture width $P_W"
fi

# -- the Preview's frame view zooms with the wheel --
read -r _ _ PV_X PV_Y PV_W PV_H _ <<< "$(lz_line 'WIN preview')"
if [[ -z "${PV_W:-}" ]]; then
    park_mouse; key F4; wait_for 0.6 "F4 (Preview)"
    lz_settle
    read -r _ _ PV_X PV_Y PV_W PV_H _ <<< "$(lz_line 'WIN preview')"
fi
if [[ -z "${PV_W:-}" ]]; then
    fail "no Preview window (WIN preview) to check"
else
    lz_read
    [[ "${PVZ:-}" == 0 ]] && pass "the Preview frame view starts fitted (ANIMPV 0)" || fail "Preview start: ANIMPV '${PVZ:-}'"
    PCX=$(( PV_X + PV_W / 2 )); PCY=$(( PV_Y + PV_H / 2 + 6 ))
    snap_region $(( PV_X + 4 )) $(( PV_Y + 16 )) $(( PV_W - 8 )) $(( PV_H - 22 )) "lbzoom-pv-fit"; cp "$SNAP_RESULT" "$LZ_DIR/pv0.png"
    scroll_up "$PCX" "$PCY"; wait_for 0.4 "wheel up over the Preview"
    scroll_up "$PCX" "$PCY"; wait_for 0.4 "wheel up over the Preview"
    lz_read nosettle
    [[ "${PVZ:-0}" =~ ^[0-9]+$ ]] && (( PVZ > 0 )) && pass "the wheel zooms the Preview's frame view (${PVZ}%)" || fail "Preview wheel: ANIMPV '${PVZ:-}'"
    snap_region $(( PV_X + 4 )) $(( PV_Y + 16 )) $(( PV_W - 8 )) $(( PV_H - 22 )) "lbzoom-pv-zoomed"
    assert_regions_differ "$LZ_DIR/pv0.png" "$SNAP_RESULT" "the Preview shows the frame bigger"
    for i in 1 2 3 4 5 6 7 8; do scroll_down "$PCX" "$PCY"; sleep 0.15; done
    wait_for 0.3 "wheel down over the Preview"
    lz_read nosettle
    [[ "${PVZ:-}" == 0 ]] && pass "wheel down: the Preview frame view is fitted again" || fail "Preview wheel down: ANIMPV '${PVZ:-}'"
fi

DRAW_EXTRA_ARGS=""
rm -rf "$LZ_DIR"
assert_no_crash
