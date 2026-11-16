#!/bin/bash
# =============================================================================
# anim-strip-tray.sh — QA test: the lightbox strip as an "ice cube tray".
#
# Rick 2026-11-09: "think like an ice cube tray for a freezer.. it can
# accommodate up to a minimum x/y size of the cube size, as a cell and it can
# stack across, and down, if the user prefers, or across only".
#
# LIGHTBOX_STRIP_FLOW=TRAY (the default) lays the strip's cells across, then
# down: the biggest cell that holds every frame, down to
# LIGHTBOX_STRIP_MIN_CELL. Builds before it showed one row as tall as the band
# (here ~6 of the 30 frames) and scrolled it sideways.
# - all 30 frames show, in 2+ rows; a click on row 2's first cell picks frame
#   cols + 1; dragging frame 2 onto row 2 drops it there (one undo step)
# - Ctrl+wheel up: bigger cells (LIGHTBOX_STRIP_CELL), so they no longer all
#   fit; the wheel then scrolls a whole row
# - a double-click on the strip's bottom edge: fitted again (all 30)
# - the right-click menu: Row (one row, across only) and back to Tray
#
# Dump: ANIMLB (... pad drawPane stripCols stripRows flow cellSetting), ANIM
# (current), ANIMC (a CRC per frame cell), ANIMLBE (the menu's x / y).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_STRIP_SIZE=30
# =============================================================================
info "=== Animation: the lightbox strip as a tray ==="

ST_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
ST_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
ST_DIR="/tmp/draw-qa-striptray-$$"
mkdir -p "$ST_DIR"
# 30 frames of 16x16 (a 6 x 5 sheet), each a different colour and size
ST_DRAW=()
for n in $(seq 0 29); do
    x=$(( (n % 6) * 16 + 2 )); y=$(( (n / 6) * 16 + 2 ))
    ST_DRAW+=(-fill "#$(printf '%02x%02x%02x' $(( 40 + n * 7 )) $(( 230 - n * 6 )) $(( 60 + (n * 37) % 190 )))" -draw "rectangle $x,$y $(( x + 2 + n % 11 )),$(( y + 3 + n % 9 ))")
done
magick -size 96x80 xc:none "${ST_DRAW[@]}" "PNG32:$ST_DIR/plain.png"
python3 "$ST_PY" put "$ST_DIR/plain.png" "$ST_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,30,1,12,0,0).hex())")"

st_line() { grep -m1 "^$1 " "$ST_DUMP" 2>/dev/null; }
st_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(st_line ANIM)"
    local t; read -r _ t <<< "$(st_line ANIMC)"; T=(x $t)
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH _ _ LB_SF LB_SN LB_CW LB_CH _ _ _ LB_PAD _ LB_COLS LB_ROWS LB_FLOW LB_CELL _ <<< "$(st_line ANIMLB)"
    read -r _ _ _ M_OPEN _ _ M_X M_Y _ <<< "$(st_line ANIMLBE)"
}
st_cx() { echo $(( LB_X1 + LB_PAD + $1 * (LB_CW + LB_PAD) + LB_CW / 2 )); } # cell column C's centre x
st_cy() { echo $(( LB_SY + LB_PAD + $1 * (LB_CH + LB_PAD) + LB_CH / 2 )); } # cell row R's centre y
st_menu() { # ITEM-INDEX (before the divider): right-click the strip, pick it
    right_click "$(st_cx 0)" "$(st_cy 0)"; wait_for 0.5 "the strip's menu"
    st_read
    if [[ "$M_OPEN" != -1 ]]; then info "the strip's menu did not open"; return 1; fi
    click $(( M_X + 20 )) $(( M_Y + 2 + $1 * 12 + 6 )); wait_for 0.6 "menu item $1"
    st_read
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$ST_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key b; wait_for 0.3 "Brush"
park_mouse; key KP_0; wait_for 0.6 "Lightbox"
st_read
if [[ "${LB_SHOWN:-}" != -1 || "${A_COUNT:-}" != 30 ]]; then
    fail "lightbox with 30 frames: shown '${LB_SHOWN:-}' count '${A_COUNT:-}'"
else
    ST_T0="${T[*]:1}"; T0=(x $ST_T0)

    # -- the tray holds every frame, in rows --
    (( ${LB_SN:-0} == 30 && ${LB_ROWS:-0} >= 2 && ${LB_COLS:-0} >= 2 )) \
        && pass "the tray shows all 30 frames: $LB_COLS across x $LB_ROWS down, ${LB_CW}x$LB_CH px cells" \
        || fail "the tray: ${LB_SN:-?} of 30 frames shown, ${LB_COLS:-?} x ${LB_ROWS:-?} cells (one row as tall as the band before)"
    COLS=${LB_COLS:-6}; CH0=${LB_CH:-0}

    click "$(st_cx 0)" "$(st_cy 1)"; wait_for 0.5 "row 2's first cell"
    st_read
    [[ "$A_CUR" == $(( COLS + 1 )) ]] && pass "a click on row 2's first cell picks frame $(( COLS + 1 ))" \
        || fail "row 2's first cell picked frame '$A_CUR', wanted $(( COLS + 1 ))"

    # -- drag frame 2 onto row 2, before its third cell --
    drag "$(st_cx 1)" "$(st_cy 0)" $(( $(st_cx 2) - LB_CW / 4 )) "$(st_cy 1)"; wait_for 0.8 "drag frame 2 down a row"
    st_read
    [[ -n "${T[2]:-}" && "${T[$(( COLS + 2 ))]}" == "${T0[2]}" && "${T[2]}" == "${T0[3]}" ]] \
        && pass "dragging frame 2 onto row 2 moves it there (now frame $(( COLS + 2 )))" \
        || fail "after the drag down a row: cell $(( COLS + 2 )) is not old frame 2 [${T[*]:1:$(( COLS + 3 ))}]"
    park_mouse; key ctrl+z; wait_for 0.8 "undo the move"
    st_read
    [[ "${T[*]:1}" == "$ST_T0" ]] && pass "Ctrl+Z puts the frames back" || fail "undo of the move: the frames differ"

    # -- Ctrl+wheel: bigger cells; the wheel then scrolls a row --
    ctrl_scroll_up "$(st_cx 0)" "$(st_cy 0)"; wait_for 0.4 "Ctrl+wheel up"
    ctrl_scroll_up "$(st_cx 0)" "$(st_cy 0)"; wait_for 0.6 "Ctrl+wheel up"
    st_read
    if (( ${LB_CH:-0} > CH0 && ${LB_CELL:-0} > 0 && ${LB_SN:-30} < 30 )); then
        pass "Ctrl+wheel up: bigger cells ($CH0 -> $LB_CH px, ${LB_SN} frames shown, $LB_COLS across)"
        COLS2=$LB_COLS
        scroll_down "$(st_cx 0)" "$(st_cy 0)"; wait_for 0.6 "wheel down"
        st_read
        [[ "$LB_SF" == $(( 1 + COLS2 )) ]] && pass "the wheel scrolls the tray a row ($COLS2 frames): from frame $LB_SF" \
            || fail "after a wheel tick the strip starts at frame '$LB_SF', wanted $(( 1 + COLS2 ))"
    else
        fail "Ctrl+wheel up: cells $CH0 -> ${LB_CH:-?} px, setting '${LB_CELL:-?}', ${LB_SN:-?} shown (wanted bigger, < 30)"
    fi

    # -- a double-click on the strip's edge: fitted again --
    CX=$(( (LB_X1 + LB_X2) / 2 ))
    double_click "$CX" $(( LB_BY - 1 )); wait_for 0.8 "double-click the strip's edge"
    st_read
    [[ "$LB_CELL" == 0 && "$LB_SN" == 30 && "$LB_SF" == 1 ]] && pass "a double-click on the edge fits the cells again (all 30, ${LB_CH} px)" \
        || fail "after the double-click: setting '${LB_CELL:-?}', first $LB_SF, $LB_SN shown (wanted 0, 1, 30)"
    screenshot "strip-tray"

    # -- the right-click menu: Row, then Tray --
    if st_menu 1; then
        [[ "$LB_FLOW" == 1 && "$LB_ROWS" == 1 && "$LB_SN" -lt 30 ]] && pass "menu > Row: one row across ($LB_SN frames, ${LB_CH} px)" \
            || fail "menu > Row: flow '$LB_FLOW', rows '$LB_ROWS', $LB_SN shown"
        screenshot "strip-row"
        st_menu 0
        [[ "$LB_FLOW" == 0 && "$LB_SN" == 30 ]] && pass "menu > Tray: back to the tray (all 30)" \
            || fail "menu > Tray: flow '$LB_FLOW', $LB_SN shown"
    else
        fail "a right-click on the strip opens no menu"
    fi
fi
assert_no_crash
rm -rf "$ST_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
