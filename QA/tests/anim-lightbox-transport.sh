#!/bin/bash
# =============================================================================
# anim-lightbox-transport.sh — QA test: the lightbox transport bar's sizes
# (field kit T-11, Rick 2026-11-08: Tiny5 16 for the number boxes - 5/8,
# 0:00.4 / 0:00.8, 10 FPS - taller buttons with padding, a taller seek bar,
# a seek handle of at least 8 px).
#
# Measured from snapshots in viewport px (snapshot px / the display scale):
# the bar >= 28 px tall; the count box's digits >= 9 px tall (Tiny5 at 8 is
# 5); the seek handle >= 8 px wide and >= 14 px tall. The old build: a 16 px
# bar, 5 px digits, a 3 px handle.
#
# Dump: ANIMLB (barY barH), ANIMLBC (x w per control: 9 seek, 10 count).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3
# =============================================================================
info "=== Animation: the lightbox transport bar's sizes ==="

LT_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LT_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LT_DIR="/tmp/draw-qa-lbtransport-$$"
mkdir -p "$LT_DIR"
magick -size 128x16 xc:'#303030' -fill '#c04040' -draw 'rectangle 2,2 5,5' "PNG32:$LT_DIR/plain.png"
LT_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,8,5,10,0,0).hex())")
python3 "$LT_PY" put "$LT_DIR/plain.png" "$LT_DIR/sheet.png" drAn "$LT_BLOB"

lt_read() {
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH _ <<< "$(grep -m1 '^ANIMLB ' "$LT_DUMP")"
    C=($(grep -m1 '^ANIMLBC ' "$LT_DUMP"))
}
lt_cx() { echo "${C[$(( 2 * $1 - 1 ))]}"; }
lt_cw() { echo "${C[$(( 2 * $1 ))]}"; }
lt_box() { # IMG THRESHOLD -> "w h" of the bounding box of pixels brighter than THRESHOLD %
    local b; b=$(magick "$1" -alpha off -colorspace gray -threshold "$2%" -format '%@' info: 2>/dev/null)
    [[ "$b" =~ ^([0-9]+)x([0-9]+)\+ ]] && echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}" || echo "0 0"
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LT_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key KP_0; wait_for 0.8 "Lightbox"
hover 300 250; wait_for 0.3 "render"; park_mouse; wait_for 0.4 "render"
lt_read
if [[ "${LB_SHOWN:-}" != -1 || -z "$(lt_cw 10)" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', controls '${C[*]}'"
else
    (( LB_BH >= 28 )) && pass "transport bar $LB_BH px tall (>= 28)" || fail "transport bar $LB_BH px tall, wanted >= 28"

    # the count box (5/8): its digits
    CX=$(lt_cx 10); CW=$(lt_cw 10)
    snap_region $(( CX + 2 )) $(( LB_BY + 3 )) $(( CW - 4 )) $(( LB_BH - 6 )) "lbtransport-count" >/dev/null && cp "$SNAP_RESULT" "$LT_DIR/count.png"
    IW=$(magick identify -format %w "$LT_DIR/count.png"); S100=$(( IW * 100 / (CW - 4) )); (( S100 < 100 )) && S100=100
    read -r TW TH <<< "$(lt_box "$LT_DIR/count.png" 60)"
    TH_VP=$(( TH * 100 / S100 ))
    info "  count box ${CW} px wide, digits ${TW}x${TH} snapshot px (scale ${S100}%) = $TH_VP px tall"
    (( TH_VP >= 9 )) && pass "the count box's digits are $TH_VP px tall (>= 9: the UI font at 2x)" || fail "the count box's digits are $TH_VP px tall, wanted >= 9"

    # the seek handle
    SX=$(lt_cx 9); SW=$(lt_cw 9)
    snap_region "$SX" $(( LB_BY + 1 )) "$SW" $(( LB_BH - 2 )) "lbtransport-seek" >/dev/null && cp "$SNAP_RESULT" "$LT_DIR/seek.png"
    read -r HW HH <<< "$(lt_box "$LT_DIR/seek.png" 85)"
    HW_VP=$(( (HW * 100 + S100 / 2) / S100 )); HH_VP=$(( (HH * 100 + S100 / 2) / S100 ))
    info "  seek bar ${SW} px wide, handle ${HW}x${HH} snapshot px = ${HW_VP}x${HH_VP} px"
    (( HW_VP >= 8 && HW_VP <= 12 )) && pass "the seek handle is $HW_VP px wide (>= 8)" || fail "the seek handle is $HW_VP px wide, wanted 8..12"
    (( HH_VP >= 14 )) && pass "the seek handle is $HH_VP px tall (a taller seek bar)" || fail "the seek handle is $HH_VP px tall, wanted >= 14"
    screenshot "anim-lightbox-transport"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LT_DIR"
assert_window_exists
