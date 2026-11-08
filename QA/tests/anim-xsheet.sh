#!/bin/bash
# =============================================================================
# anim-xsheet.sh — QA test: the X-sheet view (Animation 4.1, TOOLS/ANIM-XS,
# ANIM > X-Sheet / Num 8 / the transport bar's X-SHEET chip, action 2540).
#
# The lightbox's top band becomes a frames x layers grid: a column per tick
# (a frame spans its hold), the header's frame numbers, one row per layer
# (top layer first) with each cell's drawing as a thumbnail, the holds row.
# A click on a cell = that frame and that layer current; the header = the
# frame (Ctrl adds it to the selection). What a cell shows is checked on
# screen (the colour at the thumbnail's middle is that frame's colour; an
# empty cell shows none), which cells are drawn in the dump.
#
# Dump: ANIMXS on shown x1 y1 x2 y2 nameW rowH tickW gx firstF lastF nRows
# firstRow rowsShown currentLayer / ANIMXSF f x w ... / ANIMXSR r slot y fill.
# Fixture: a 64x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour (the frame's middle pixel is inside it); 4 frames at 10 fps,
# frame 2 held 3, current 1. One layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: the X-sheet ==="

XS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
XS_DIR="/tmp/draw-qa-xsheet-$$"
mkdir -p "$XS_DIR"
XS_DRAW=()
XS_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 3 + n ))
    XS_DRAW+=(-fill "#${XS_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 64x16 xc:none "${XS_DRAW[@]}" "PNG32:$XS_DIR/plain.png"
python3 "$XS_PY" put "$XS_DIR/plain.png" "$XS_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<12h',1,16,16,0,0,4,1,10,0,2,1,3).hex())")"

xs_line() { grep -m1 "^$1 " "$XS_DUMP" 2>/dev/null; }
xs_read() { # XS_ON XS_SHOWN ... XS_CL, XS_F (spans), A_COUNT A_CUR, LB_SHOWN, ROWS[r]="slot y fill"
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.2 "render"; } >&2
    XS_ON=""; XS_SHOWN=""
    read -r _ XS_ON XS_SHOWN XS_X1 XS_Y1 XS_X2 XS_Y2 XS_NW XS_RH XS_TW XS_GX XS_FF XS_LF XS_NR XS_FR XS_RS XS_CL _ <<< "$(xs_line ANIMXS)"
    XS_F=($(xs_line ANIMXSF)); XS_F=("${XS_F[@]:1}")
    read -r _ _ A_COUNT A_CUR _ <<< "$(xs_line ANIM)"
    read -r _ LB_SHOWN _ <<< "$(xs_line ANIMLB)"
    ROWS=(); local r
    for (( r = 1; r <= ${XS_NR:-0}; r++ )); do ROWS[$r]="$(grep -m1 "^ANIMXSR $r " "$XS_DUMP" | cut -d' ' -f3-)"; done
}
xs_s() { echo "on '${XS_ON:-}' shown '${XS_SHOWN:-}' lightbox '${LB_SHOWN:-}' rows ${XS_NR:-?} current frame ${A_CUR:-?}/${A_COUNT:-?} layer ${XS_CL:-?} spans '${XS_F[*]:-}'"; }
xs_fill() { cut -d' ' -f3 <<< "${ROWS[$1]}"; } # ROW -> its fill string
xs_ry() { cut -d' ' -f2 <<< "${ROWS[$1]}"; }    # ROW -> its y on screen
xs_span() { # FRAME -> SPX SPW (its span)
    local i
    SPX=""; SPW=""
    for (( i = 0; i + 2 < ${#XS_F[@]}; i += 3 )); do
        [[ "${XS_F[$i]}" == "$1" ]] && { SPX=${XS_F[$((i + 1))]}; SPW=${XS_F[$((i + 2))]}; }
    done
}
xs_thumb_colour() { # ROW FRAME -> the colour on screen at the middle of that cell's thumbnail
    local ry bw bh s dw dy x y
    xs_span "$2"; ry=$(xs_ry "$1")
    bw=$(( XS_TW - 3 )); bh=$(( XS_RH - 2 ))
    s=$(( bw < bh ? bw : bh )); dw=$s # 16x16 frames: the thumbnail is square
    dy=$(( ry + (XS_RH - 1 - dw) / 2 ))
    x=$(( SPX + 2 + (15 * dw) / 32 )); y=$(( dy + (15 * dw) / 32 ))
    snap_region "$x" "$y" 1 1 "xs_px" >/dev/null
    magick "${SNAP_RESULT:-/nonexistent}" -format '%[hex:p{0,0}]' info: 2>/dev/null | cut -c1-6 | tr 'A-F' 'a-f'
}
xs_shows() { [[ "$(xs_thumb_colour "$1" "$2")" == "${XS_COLORS[$(( $2 - 1 ))]}" ]]; } # ROW FRAME
xs_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
xs_chip() { # click the transport bar's X-SHEET chip (the bar moves with the band's height)
    local c by
    read -r -a c <<< "$(xs_line ANIMLBC)"
    XS_CHX=${c[29]:-}; XS_CHW=${c[30]:-}
    read -r _ _ _ _ _ _ _ _ by _ <<< "$(xs_line ANIMLB)"
    click $(( XS_CHX + XS_CHW / 2 )) $(( by + 2 + 4 )); xs_read
}

info "Launching DRAW with a 64x16 sheet of 16x16 frames (4 at 10 fps, frame 2 held 3, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$XS_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
xs_key KP_8
xs_read
if [[ "$XS_ON" != -1 || "$XS_SHOWN" != -1 || "$LB_SHOWN" != -1 || "$XS_NR" != 1 ]]; then
    fail "Num 8 from sheet view did not open the lightbox with the X-sheet: $(xs_s)"
else
    pass "Num 8 from sheet view: the lightbox, its top band the X-sheet, 1 layer row"
    XS_L1=$(cut -d' ' -f1 <<< "${ROWS[1]}")

    # -- columns: a tick each, frame 2 spans its hold of 3 --
    xs_span 1; S1X=$SPX; S1W=$SPW; xs_span 2; S2X=$SPX; S2W=$SPW; xs_span 3; S3X=$SPX
    [[ "$S1W" == "$XS_TW" && "$S2W" == $(( 3 * XS_TW )) && "$S2X" == $(( S1X + XS_TW )) && "$S3X" == $(( S2X + 3 * XS_TW )) ]] \
        && pass "a column per tick: frame 2 (hold 3) spans 3 ($S2W px), frame 3 starts after it" || fail "spans: '${XS_F[*]}' tick $XS_TW"

    # -- cells: the layer's drawing in each frame, on screen --
    [[ "$(xs_fill 1)" == 1111 ]] && pass "the layer has a drawing in all 4 frames (fill 1111)" || fail "fill: '${ROWS[1]}'"
    XS_OK=1; XS_SEEN=""
    for k in 1 2 3 4; do XS_SEEN="$XS_SEEN #$(xs_thumb_colour 1 $k)"; xs_shows 1 $k || XS_OK=0; done
    [[ $XS_OK == 1 ]] && pass "each cell's thumbnail shows that frame's drawing (${XS_SEEN# })" || fail "thumbnails on screen:$XS_SEEN, wanted ${XS_COLORS[*]}"

    # -- a new layer: a row above, empty; a dot in frame 1 on it, undo --
    xs_key ctrl+shift+n; xs_read
    [[ "$XS_NR" == 2 && "$(xs_fill 1)" == 0000 && "$(xs_fill 2)" == 1111 && "$XS_CL" == "$(cut -d' ' -f1 <<< "${ROWS[1]}")" ]] \
        && pass "New Layer: a second row on top, its cells empty, it is the current layer" || fail "new layer: $(xs_s), rows '${ROWS[1]}' / '${ROWS[2]}'"
    XS_EMPTY="$(xs_thumb_colour 1 1)"
    [[ "$XS_EMPTY" != "${XS_COLORS[0]}" ]] && xs_shows 2 1 && pass "an empty cell shows no drawing (#$XS_EMPTY), the layer under it still does" || fail "empty cell #$XS_EMPTY"
    read -r -a XS_P <<< "$(xs_line ANIMLBP)"
    XS_PX=""; for (( k = 3; k + 4 < ${#XS_P[@]}; k += 5 )); do [[ "${XS_P[$k]}" == 1 ]] && { XS_PX=${XS_P[$((k + 1))]}; XS_PY=${XS_P[$((k + 2))]}; XS_PW=${XS_P[$((k + 3))]}; }; done
    key b; wait_for 0.3 "Brush"
    click $(( XS_PX + XS_PW / 2 )) $(( XS_PY + XS_PW / 2 )); wait_for 0.6 "a dot"
    xs_read
    [[ "$(xs_fill 1)" == 1000 && "$(xs_fill 2)" == 1111 ]] && pass "a brush dot in frame 1 on the new layer: its row shows frame 1 drawn (1000)" || fail "after the dot: '${ROWS[1]}' / '${ROWS[2]}'"
    xs_key ctrl+z; xs_read
    [[ "$(xs_fill 1)" == 0000 ]] && pass "undo: the cell is empty again" || fail "after undo: '${ROWS[1]}'"
    xs_key ctrl+y; xs_read

    # -- clicks: a cell = its frame and its layer; the header = the frame; Ctrl adds --
    xs_span 3
    click $(( SPX + XS_TW / 2 )) $(( $(xs_ry 2) + XS_RH / 2 )); xs_read
    [[ "$A_CUR" == 3 && "$XS_CL" == "$XS_L1" ]] && pass "a click on the bottom layer's frame 3 cell: frame 3, that layer current" || fail "cell click: $(xs_s) (wanted frame 3, layer $XS_L1)"
    xs_span 4
    click $(( SPX + XS_TW / 2 )) $(( XS_Y1 + 1 + XS_RH / 2 )); xs_read
    [[ "$A_CUR" == 4 && "$XS_CL" == "$XS_L1" ]] && pass "a click on frame 4's number: frame 4 (the layer stays)" || fail "header click: $(xs_s)"
    xs_span 2
    ctrl_click $(( SPX + XS_TW / 2 )) $(( XS_Y1 + 1 + XS_RH / 2 )); xs_read
    read -r _ _ _ _ XS_NSEL XS_SEL <<< "$(xs_line ANIMLBS)"
    [[ "$A_CUR" == 2 && "$XS_NSEL" == 2 ]] && pass "Ctrl+click frame 2: frames 2 and 4 selected, 2 current" || fail "ctrl click: $(xs_s), selection '$(xs_line ANIMLBS)'"
    # the current frame's column is tinted (header, away from its number)
    xs_span 2; snap_region $(( SPX + SPW - 3 )) $(( XS_Y1 + XS_RH / 2 )) 1 1 "xs_cur" >/dev/null; XS_C1=$(magick "$SNAP_RESULT" -format '%[hex:p{0,0}]' info:)
    xs_span 3; snap_region $(( SPX + XS_TW - 3 )) $(( XS_Y1 + XS_RH / 2 )) 1 1 "xs_oth" >/dev/null; XS_C3=$(magick "$SNAP_RESULT" -format '%[hex:p{0,0}]' info:)
    [[ "$XS_C1" != "$XS_C3" ]] && pass "the current frame's column is tinted (#${XS_C1:0:6} vs #${XS_C3:0:6})" || fail "current column not tinted: #$XS_C1 = #$XS_C3"

    # -- a frame op: the grid follows --
    xs_key KP_Add; xs_read
    [[ "$A_COUNT" == 5 && "$(xs_fill 2)" == 11111 && "${#XS_F[@]}" == 15 ]] && pass "Num +: 5 frames, 5 columns, the new frame drawn" || fail "after Num +: $(xs_s), '${ROWS[2]}'"

    # -- the chip and Num 8: back to the strip, the lightbox stays --
    xs_chip
    [[ "$XS_ON" == 0 && "$LB_SHOWN" == -1 ]] && pass "the X-SHEET chip: the strip back, still the lightbox" || fail "chip: $(xs_s) (chip at '$XS_CHX' w '$XS_CHW')"
    xs_chip
    [[ "$XS_ON" == -1 && "$XS_SHOWN" == -1 ]] && pass "and again: the X-sheet" || fail "chip again: $(xs_s)"
    xs_key KP_8; xs_read
    [[ "$XS_ON" == 0 && "$LB_SHOWN" == -1 ]] && pass "Num 8: the strip" || fail "Num 8 off: $(xs_s)"
fi
assert_no_crash

# leave a plain DRAW running for the next test (the X-sheet off in its config)
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$XS_DIR"
assert_window_exists
