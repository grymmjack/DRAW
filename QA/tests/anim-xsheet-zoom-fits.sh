#!/bin/bash
# =============================================================================
# anim-xsheet-zoom-fits.sh — QA test: the X-sheet's zoom slider is there even
# when every frame already fits.
#
# Rick 2026-11-16: "also the layer zoom slider for xsheet is gone... where did
# that go?" - it hid whenever every frame fit at the default size (any short
# animation). Now it is always in the header's LAYER cell: left = every frame
# across, right = 4x the default (the frames spread out - room for lane keys),
# a notch at the default; a double-click goes back to it. XSHEET_FIT_ALL=TRUE
# (Settings > Animation > Show all frames) makes every-frame-across the default.
#
# Fixture: a 6-frame sheet of 16x16 frames (all fit at the default).
# Dump: ANIMXS (... tick*100 tickAuto*100 tickMin*100 zx1 zx2 tagBtnX
# tickMax*100 tickDef*100 tickFit*100), ANIM (count).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_ROWS=TEXT XSHEET_ZOOM=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Animation: the X-sheet zoom slider with every frame fitting ==="

ZF_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
ZF_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
ZF_DIR="/tmp/draw-qa-xszfit-$$"
mkdir -p "$ZF_DIR"
magick -size 96x16 xc:none -fill '#e02020' -draw 'rectangle 3,4 8,9' -fill '#40c040' -draw 'rectangle 20,4 25,9' "PNG32:$ZF_DIR/plain.png"
python3 "$ZF_PY" put "$ZF_DIR/plain.png" "$ZF_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,12,0,0).hex())")"

zf_line() { grep -m1 "^$1 " "$ZF_DUMP" 2>/dev/null; }
zf_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ XON _ XX1 XY1 XX2 XY2 XNW XRH _ XGX XFF XLF _ _ _ _ XLH XT XTA XTM XZ1 XZ2 XTB XTX XTD XTF _ <<< "$(zf_line ANIMXS)"
    read -r _ _ A_COUNT A_CUR _ <<< "$(zf_line ANIM)"
}
zf_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
zf_open() { # EXTRA ARGS
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$1"
    draw_launch 15
    wait_for 1.5 "Sheet loaded"
    assert_no_crash
    zf_key KP_0
    zf_read; [[ "$XON" == -1 ]] || zf_key KP_8
    zf_read
}

zf_open "$ZF_DIR/sheet.png"
if [[ "$XON" != -1 || "${A_COUNT:-}" != 6 ]]; then
    fail "X-sheet with 6 frames: on '$XON', count '${A_COUNT:-}'"
else
    HY=$(( XY1 + 1 + XRH / 2 ))
    [[ "${XZ1:-0}" -gt 0 && "${XZ2:-0}" -gt "${XZ1:-0}" && "$XT" == "$XTA" && "$XTM" == "$XTA" ]] \
        && pass "every frame fits at the default, and the zoom slider is still there ($XZ1-$XZ2)" \
        || fail "slider '${XZ1:-?}-${XZ2:-?}', tick '$XT' auto '$XTA' min '$XTM'"
    # drag the handle to the right end: zoomed in past the default
    drag $(( (XZ1 + XZ2) / 2 )) "$HY" $(( XZ2 + 6 )) "$HY"; wait_for 0.6 "drag the zoom handle right"
    zf_read
    [[ -n "$XT" && "$XT" == "$XTX" && "$XT" -gt "$XTA" ]] && pass "dragged right: zoomed in past the default (a tick $XT/100 px, default $XTA/100)" \
        || fail "after the drag right: tick '$XT', max '$XTX', auto '$XTA'"
    screenshot "xszfit-in"
    double_click $(( (XZ1 + XZ2) / 2 )) "$HY"; wait_for 0.8 "double-click the slider"
    zf_read
    [[ "$XT" == "$XTA" ]] && pass "a double-click: the default size again" || fail "after the double-click: tick '$XT', wanted '$XTA'"
fi

# -- XSHEET_FIT_ALL: every frame across by default --
zf_open "--option XSHEET_FIT_ALL=TRUE $ZF_DIR/sheet.png"
if [[ "$XON" != -1 ]]; then
    fail "X-sheet (XSHEET_FIT_ALL): on '$XON'"
else
    [[ -n "$XT" && "$XT" == "$XTF" && "$XTD" == "$XTF" && "$XT" -gt "$XTA" && "$XFF" == 1 && "$XLF" == 6 ]] \
        && pass "XSHEET_FIT_ALL=TRUE: the default spreads the 6 frames across (a tick $XT/100 px, a thumbnail's $XTA/100)" \
        || fail "fit-all default: tick '$XT', def '$XTD', fit '$XTF', auto '$XTA', frames $XFF-$XLF"
fi
assert_no_crash
rm -rf "$ZF_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
