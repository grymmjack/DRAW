#!/bin/bash
# =============================================================================
# anim-xsheet-zoom.sh — QA test: zooming the X-sheet, sizing its layer rows,
# and jumping between tags.
#
# Rick 2026-11-10 (Girl.ase: 60 frames, each held 24 ticks - two frames
# filled the X-sheet): "buttons on that row > and < for next and prev tag ...
# right click context menu to show the tags ... to jump right to a tag ... zoom
# the x-sheet both vertical and horizontally to snap to sizes of lanes for the
# thumbnail sizes ... a line or something with a drag handle to allow zooming -
# i love what we have for less frames so don't KILL it".
#
# - the default stays: a thumbnail a tick (40 frames x hold 24 here: ~3 shown)
# - the slider in the header's LAYER cell: dragged to its left end every frame
#   fits; a double-click on it: the default again
# - Ctrl+wheel over the grid zooms out; the header's right-click menu has
#   Zoom to Fit All Frames
# - Ctrl+Shift+wheel: the layer rows' size (TEXT -> TINY -> SMALL)
# - the TAGS row's < / > buttons go to the previous / next tag; its right-click
#   menu lists the tags first, a pick goes there
# Builds before it had none of this (the ANIMXS dump had no zoom fields).
#
# Dump: ANIMXS (... currentLayer layH tick*100 tickAuto*100 tickMin*100 zx1 zx2
# tagBtnX), ANIMXST (the tags row's y), ANIM (current), ANIMLBE (the menu).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_ROWS=TEXT XSHEET_ZOOM=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Animation: X-sheet zoom, row sizes, tag jumps ==="

XZ_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XZ_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
XZ_DIR="/tmp/draw-qa-xszoom-$$"
mkdir -p "$XZ_DIR"
# 40 frames of 16x16 (8 x 5), each a different mark, every one held 24 ticks
# at 40 FPS; tags idle 1-8, walk 9-20, jump 21-30, fall 31-40 (drAn v4)
XZ_DRAW=()
for n in $(seq 0 39); do
    x=$(( (n % 8) * 16 + 2 )); y=$(( (n / 8) * 16 + 2 ))
    XZ_DRAW+=(-fill "#$(printf '%02x%02x%02x' $(( 50 + n * 5 )) $(( 220 - n * 4 )) $(( 80 + (n * 29) % 170 )))" -draw "rectangle $x,$y $(( x + 3 + n % 9 )),$(( y + 3 + n % 7 ))")
done
magick -size 128x80 xc:none "${XZ_DRAW[@]}" "PNG32:$XZ_DIR/plain.png"
XZ_BLOB=$(python3 - <<'PY'
import struct
s = struct.pack('<10h', 4, 16, 16, 0, 0, 40, 1, 40, 0, 40) + struct.pack('<40h', *([24] * 40))
s += struct.pack('<h', 0) + struct.pack('<h', 0)   # layer flags, links
tags = [(1, 8, b'idle'), (9, 20, b'walk'), (21, 30, b'jump'), (31, 40, b'fall')]
s += struct.pack('<h', len(tags))
for a, b, nm in tags: s += struct.pack('<3h', a, b, len(nm)) + nm
print(s.hex())
PY
)
python3 "$XZ_PY" put "$XZ_DIR/plain.png" "$XZ_DIR/sheet.png" drAn "$XZ_BLOB"

xz_line() { grep -m1 "^$1 " "$XZ_DUMP" 2>/dev/null; }
xz_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ XON _ XX1 XY1 XX2 XY2 XNW XRH _ XGX XFF XLF _ _ _ _ XLH XT XTA XTM XZ1 XZ2 XTB _ <<< "$(xz_line ANIMXS)"
    read -r _ XTY _ <<< "$(xz_line ANIMXST)"
    read -r _ _ A_COUNT A_CUR _ <<< "$(xz_line ANIM)"
    read -r _ _ _ M_OPEN _ _ M_X M_Y _ <<< "$(xz_line ANIMLBE)"
}
xz_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
xz_shown() { echo $(( ${XLF:-0} - ${XFF:-0} + 1 )); }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$XZ_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
xz_key KP_0
xz_read; [[ "$XON" == -1 ]] || xz_key KP_8
xz_read
if [[ "$XON" != -1 || "${A_COUNT:-}" != 40 ]]; then
    fail "X-sheet with 40 frames: on '$XON', count '${A_COUNT:-}'"
else
    GX=$(( (XGX + XX2) / 2 )); GY=$(( XY1 + 1 + XRH + XLH / 2 )) # the grid, the first layer row
    # -- the default: unchanged, a thumbnail a tick --
    N0=$(xz_shown)
    [[ -n "$XT" && "$XT" == "$XTA" && "$N0" -le 6 && "${XZ1:-0}" -gt 0 ]] \
        && pass "the default X-sheet: a thumbnail a tick ($(( XTA / 100 )) px), $N0 frames shown, the zoom slider there" \
        || fail "default: tick '${XT:-?}' (auto '${XTA:-?}'), $N0 frames shown, slider '${XZ1:-?}'"

    # -- the slider: drag to its left end -> every frame --
    HY=$(( XY1 + 1 + XRH / 2 ))
    drag "$XZ2" "$HY" $(( XZ1 - 6 )) "$HY"; wait_for 0.6 "drag the zoom handle left"
    xz_read
    [[ "$XFF" == 1 && "$XLF" == 40 && "$XT" == "$XTM" ]] && pass "the slider dragged left: all 40 frames across (a tick $(( XT ))/100 px)" \
        || fail "after the slider drag: frames $XFF-$XLF, tick '$XT' (min '$XTM')"
    screenshot "xszoom-all"
    double_click $(( (XZ1 + XZ2) / 2 )) "$HY"; wait_for 0.8 "double-click the slider"
    xz_read
    [[ -n "$XT" && "$XT" == "$XTA" ]] && pass "a double-click on the slider: the default size again ($(xz_shown) frames)" || fail "after the double-click: tick '$XT', wanted '$XTA'"

    # -- Ctrl+wheel zooms out --
    ctrl_scroll_down "$GX" "$GY"; wait_for 0.4 "Ctrl+wheel down"
    ctrl_scroll_down "$GX" "$GY"; wait_for 0.6 "Ctrl+wheel down"
    xz_read
    (( ${XT:-9999} < ${XTA:-0} && $(xz_shown) >= N0 )) && pass "Ctrl+wheel down zooms out: a tick $XT/100 px, $(xz_shown) frames shown" \
        || fail "Ctrl+wheel down: tick '$XT' (auto '$XTA'), $(xz_shown) frames shown (was $N0)"

    # -- the header's menu: Zoom to Fit All Frames --
    right_click "$GX" "$HY"; wait_for 0.5 "the header's menu"
    xz_read
    if [[ "$M_OPEN" == -1 ]]; then
        click $(( M_X + 20 )) $(( M_Y + 2 + 6 )); wait_for 0.6 "Zoom to Fit All Frames"
        xz_read
        [[ "$XFF" == 1 && "$XLF" == 40 ]] && pass "header menu > Zoom to Fit All Frames: 1-40 shown" || fail "Zoom to Fit: frames $XFF-$XLF"
    else
        fail "a right-click on the X-sheet's header opens no menu"
    fi

    # -- Ctrl+Shift+wheel: the layer rows' size --
    LH0=$XLH
    with_mods ctrl+shift scroll_up "$GX" "$GY"; wait_for 0.4 "Ctrl+Shift+wheel up"
    with_mods ctrl+shift scroll_up "$GX" "$GY"; wait_for 0.6 "Ctrl+Shift+wheel up"
    xz_read
    [[ "$XLH" == 36 || ( "$LH0" -ge 36 && "$XLH" -ge "$LH0" ) ]] && pass "Ctrl+Shift+wheel up twice: SMALL layer rows ($LH0 -> $XLH px)" \
        || fail "layer rows after Ctrl+Shift+wheel: $LH0 -> '${XLH:-?}' px, wanted 36"
    screenshot "xszoom-rows"

    # -- the TAGS row's < / > buttons --
    xz_read
    if (( ${XTB:-0} > 0 )); then
        TBY=$(( XTY + XRH / 2 ))
        click $(( XTB + 16 )) "$TBY"; wait_for 0.5 "next tag"
        xz_read; C1=$A_CUR
        click $(( XTB + 16 )) "$TBY"; wait_for 0.5 "next tag"
        xz_read; C2=$A_CUR
        click $(( XTB + 5 )) "$TBY"; wait_for 0.5 "previous tag"
        xz_read; C3=$A_CUR
        [[ "$C1" == 9 && "$C2" == 21 && "$C3" == 9 ]] && pass "the TAGS row's > / > / <: frames $C1, $C2, $C3 (walk, jump, walk)" \
            || fail "tag buttons: > $C1 (want 9), > $C2 (want 21), < $C3 (want 9)"
    else
        fail "no < / > buttons on the TAGS row"
    fi

    # -- the TAGS row's menu lists the tags: pick the 4th (fall) --
    right_click "$GX" $(( XTY + XRH / 2 )); wait_for 0.5 "the tags menu"
    xz_read
    if [[ "$M_OPEN" == -1 ]]; then
        click $(( M_X + 20 )) $(( M_Y + 2 + 3 * 12 + 6 )); wait_for 0.6 "the menu's 4th tag"
        xz_read
        [[ "$A_CUR" == 31 ]] && pass "the TAGS menu lists the tags: picking 'fall' goes to frame 31" || fail "tags menu pick: frame '$A_CUR', wanted 31"
    else
        fail "a right-click on the TAGS row opens no menu"
    fi
fi
assert_no_crash
rm -rf "$XZ_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
