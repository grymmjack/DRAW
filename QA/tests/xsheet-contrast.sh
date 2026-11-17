#!/bin/bash
# =============================================================================
# xsheet-contrast.sh — QA test: the X-sheet's contrast (CFG.XSHEET_CONTRAST,
# TOOLS/ANIM-XS ANIM_XS_ink~&) and its lane line thickness.
#
# Rick 2026-11-16: "can we add CTRL+ALT+SHIFT+MWHEEL over the xsheet to
# increase/lower the contrast of the grid/lanes/etc. ? some of the dotted
# lines are very faint" / "can we make the line thickness configurable?"
#
#   - Ctrl+Alt+Shift+wheel up over the X-sheet: its grid lines change (stronger)
#   - and the canvas zoom / the X-sheet's own zoom did not move
#   - Ctrl+Alt+Shift+middle-click over it: back exactly as the theme draws it
#   - wheel down: softer (different again); reset again
#   - first the zoom slider dragged to its right end (a tick past 32.767 px: past what
#     CINT(zoom * 1000) held - Rick 2026-11-16: runtime error 6 Overflow, CONFIG.BM:1361);
#     each contrast step saves the cfg: no error, the zoom saved
#
# Fixture: a 6-frame sheet of 16x16 frames.
# Dump: ANIMXS (x1 y1 x2 y2 ... gx ... tick*100).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_ROWS=TEXT XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Animation: X-sheet contrast (Ctrl+Alt+Shift+wheel) ==="

XC_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XC_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
XC_DIR="/tmp/draw-qa-xscontrast-$$"
mkdir -p "$XC_DIR"
magick -size 96x16 xc:none -fill '#e02020' -draw 'rectangle 3,4 8,9' -fill '#40c040' -draw 'rectangle 20,4 25,9' "PNG32:$XC_DIR/plain.png"
python3 "$XC_PY" put "$XC_DIR/plain.png" "$XC_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,12,0,0).hex())")"

xc_line() { grep -m1 "^$1 " "$XC_DUMP" 2>/dev/null; }
xc_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ XON _ XX1 XY1 XX2 XY2 XNW XRH _ XGX XFF XLF _ _ _ _ XLH XT XTA XTM XZ1 XZ2 XTB XTX _ <<< "$(xc_line ANIMXS)"
}
xc_open() {
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$1"
    draw_launch 15
    wait_for 1.5 "Sheet loaded"
    assert_no_crash
    park_mouse; key KP_0; wait_for 0.6 "KP_0"
    xc_read; [[ "$XON" == -1 ]] || { park_mouse; key KP_8; wait_for 0.6 "KP_8"; }
    xc_read
}
xc_snap() { park_mouse; wait_for 0.4 "settle"; snap_region "$XGX" "$XY1" $(( XX2 - XGX )) $(( XY2 - XY1 )) "$1"; }

xc_open "$XC_DIR/sheet.png"
if [[ "$XON" != -1 ]]; then
    fail "the X-sheet did not open: ANIMXS [$(xc_line ANIMXS)]"
else
    # the zoom slider to its right end: the biggest tick
    ZHY=$(( XY1 + 1 + XRH / 2 ))
    drag $(( (XZ1 + XZ2) / 2 )) "$ZHY" $(( XZ2 + 6 )) "$ZHY"; wait_for 0.6 "zoom slider right"
    xc_read
    info "zoomed in: a tick $XT/100 px (max $XTX/100)"
    T0="$XT"
    xc_snap "xc-base"; BASE="$SNAP_RESULT"
    MX=$(( XGX + 40 )); MY=$(( XY1 + XRH + 6 ))
    for n in 1 2 3; do with_mods "ctrl+alt+shift" scroll_up "$MX" "$MY"; sleep 0.15; done
    wait_for 0.6 "contrast up"
    xc_read
    xc_snap "xc-up"; UP="$SNAP_RESULT"
    [[ "$XT" == "$T0" ]] && pass "Ctrl+Alt+Shift+wheel over the X-sheet: its zoom did not move" || fail "the X-sheet zoomed: tick $T0 -> $XT"
    assert_regions_differ "$BASE" "$UP" "Ctrl+Alt+Shift+wheel up: the X-sheet's lines stronger"
    screenshot "xsheet-contrast-up"
    with_mods "ctrl+alt+shift" middle_click "$MX" "$MY"; wait_for 0.6 "reset"
    xc_snap "xc-reset"; assert_regions_same "$BASE" "$SNAP_RESULT" "Ctrl+Alt+Shift+middle-click: back to the theme as is"
    for n in 1 2 3; do with_mods "ctrl+alt+shift" scroll_down "$MX" "$MY"; sleep 0.15; done
    wait_for 0.6 "contrast down"
    xc_snap "xc-down"; DOWN="$SNAP_RESULT"; assert_regions_differ "$BASE" "$DOWN" "wheel down: softer"
    assert_regions_differ "$UP" "$DOWN" "softer is not the same as stronger"
    with_mods "ctrl+alt+shift" middle_click "$MX" "$MY"; wait_for 0.6 "reset"
    xc_snap "xc-reset2"; assert_regions_same "$BASE" "$SNAP_RESULT" "reset again: the theme as is"
    ZS=$(grep -m1 '^XSHEET_ZOOM=' "$DRAW_ROOT/QA/DRAW.qa.cfg" 2>/dev/null); ZS=${ZS#*=}
    if [[ "${T0:-0}" -le 3277 ]]; then
        info "the biggest tick here is $T0/100 px - the overflow case is not reached"
    else
        awk -v z="$ZS" -v t="$T0" 'BEGIN{exit !(z*100 >= t-1 && z*100 <= t+1)}' \
            && pass "a contrast step saved the cfg with the zoom at $ZS (past 32.767: no overflow)" || fail "cfg XSHEET_ZOOM '$ZS', the tick $T0/100"
    fi
fi
assert_no_crash
rm -rf "$XC_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
