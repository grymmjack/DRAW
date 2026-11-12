#!/bin/bash
# =============================================================================
# anim-big-frame.sh — QA test: ANIM > Big Frame + X-Sheet, one lightbox pane.
#
# Rick, 2026-11-12: "i'd love to be able to see the XSHEET without the
# lightbox as an option - so if i'm animating a larger image, it's less
# cumbersome. or maybe just use lightbox but a single cell that spans the
# entire bottom area? ... like DP where it's possible to see a big image, and
# have things happening in one spot".
#
#   - Big Frame + X-Sheet from sheet view: the lightbox opens with ONE pane
#     (the current frame) under the X-sheet, as wide as the area allows - far
#     bigger than a pane of three
#   - the menu item is checked; a click in the pane paints only the current
#     frame; Num 5 shows the next frame in it; Ctrl+wheel zooms it
#   - again: back to 3 panes, the X-sheet stays
#   - Num * cycles 1 -> 3 -> 5 -> 7 -> 1
#   - LIGHTBOX_PANES=1 in the cfg is kept (it was reset to 3 on load)
#   (no LIGHTBOX_PANES in QA-OPTIONS: they become --option args and would beat
#   the relaunch's own --option LIGHTBOX_PANES=1; the QA cfg says 3)
#
# Dump: ANIMLB (... panes paneW paneH pad), ANIMLBP (per pane: frame dx dy dw
# dh), ANIMLBZ zoom%, ANIMXS cfg isOn x1 y1 x2 y2, ANIMMENUX id:checked:enabled,
# ANIMC (a CRC per frame).
# Fixture: a 640x200 sheet of two 320x200 frames (a large picture), red / green.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LIGHTBOX=0 XSHEET=0 ONION_SKIN=0 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: Big Frame + X-Sheet (one lightbox pane) ==="

BF_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
BF_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
BF_DIR="/tmp/draw-qa-bigframe-$$"
mkdir -p "$BF_DIR"
magick -size 640x200 xc:none -fill '#402020' -draw 'rectangle 0,0 319,199' -fill '#e06060' -draw 'rectangle 20,20 80,60' \
    -fill '#204020' -draw 'rectangle 320,0 639,199' -fill '#60e060' -draw 'rectangle 360,40 420,90' "PNG32:$BF_DIR/plain.png"
BF_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,320,200,0,0,2,1,12,0,0).hex())")
python3 "$BF_PY" put "$BF_DIR/plain.png" "$BF_DIR/sheet.png" drAn "$BF_BLOB"

bf_settle() { { hover 5 300; wait_for 0.15 "render"; hover 6 302; wait_for 0.25 "render"; } >&2; }
bf_line() { grep -m1 "^$1 " "$BF_DUMP" 2>/dev/null; }
bf_read() {
    bf_settle
    read -r _ _ _ A_CUR _ <<< "$(bf_line ANIM)"
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(bf_line ANIMLB)"
    local p; p=($(bf_line ANIMLBP))
    P_N=$(( (${#p[@]} - 3) / 5 )); P_F=${p[3]:-0}; P_X=${p[4]:-0}; P_Y=${p[5]:-0}; P_W=${p[6]:-0}; P_H=${p[7]:-0}
    read -r _ Z _ <<< "$(bf_line ANIMLBZ)"
    read -r _ XS_CFG XS_ON XS_X1 XS_Y1 XS_X2 XS_Y2 _ <<< "$(bf_line ANIMXS)"
    local m; m=" $(bf_line ANIMMENUX) "; M_BIG=$(echo "$m" | grep -o ' 2593:[^ ]*' | tr -d ' ')
    local t; t=""; read -r _ t <<< "$(bf_line ANIMC)"; T=(x $t)
}
bf_s() { echo "lightbox ${LB_SHOWN:-?} panes ${LB_P:-?} (${LB_PW:-?}x${LB_PH:-?}), pane frames in ANIMLBP $P_N, first f $P_F picture ${P_W}x$P_H at $P_X,$P_Y; X-sheet cfg ${XS_CFG:-?} on ${XS_ON:-?} y ${XS_Y1:-?}..${XS_Y2:-?}; menu ${M_BIG:-?}; frame $A_CUR zoom ${Z:-?}"; }
bf_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
bf_cmd() {
    local try ok=0
    for try in 1 2 3; do
        park_mouse; key question; wait_for 1.0 "Command palette"
        grep -q '^POPUP cmdpalette' "$BF_DUMP" 2>/dev/null && { ok=1; break; }
        bf_settle; grep -q '^POPUP cmdpalette' "$BF_DUMP" 2>/dev/null && { ok=1; break; }
    done
    (( ok )) || { info "no palette for '$1'"; return 1; }
    type_text "$1"; wait_for "$(awk -v n=${#1} 'BEGIN{printf "%.1f", 0.6 + n * 0.08}')" "Filtered"
    key Return; wait_for 1.0 "$1"
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$BF_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse

# -- the 3-pane lightbox, for the size to beat --
bf_key KP_0; bf_read
W3=$P_W
[[ "$LB_SHOWN" == -1 && "$LB_P" == 3 ]] && pass "Num 0: the lightbox with 3 panes (each picture ${P_W}x$P_H)" || fail "Num 0: $(bf_s)"
bf_key KP_0; bf_read
[[ "$LB_SHOWN" == 0 ]] || fail "Num 0 again: still shown ($(bf_s))"

# -- Big Frame + X-Sheet from sheet view --
bf_cmd "big frame + x-sheet"; bf_read
if [[ "$LB_SHOWN" == -1 && "$LB_P" == 1 && "$P_N" == 1 && "$P_F" == 1 && "$XS_CFG" == -1 && "$XS_ON" == -1 ]]; then
    pass "Big Frame + X-Sheet: the lightbox, one pane (frame 1), the X-sheet on"
else
    fail "Big Frame + X-Sheet: $(bf_s)"
fi
(( P_W >= 320 && P_W > W3 )) && pass "the one pane shows the 320x200 frame at ${P_W}x$P_H (at least 1:1; a pane of three: ${W3} wide)" || fail "one pane: picture ${P_W} wide, a pane of three was $W3"
(( LB_PW >= LB_X2 - LB_X1 + 1 - 2 * LB_PAD - 1 )) && pass "the pane spans the area (${LB_PW} of $(( LB_X2 - LB_X1 + 1 )) px)" || fail "pane ${LB_PW} wide in an area $LB_X1..$LB_X2"
(( XS_Y2 < P_Y )) && pass "the X-sheet (y $XS_Y1..$XS_Y2) is above the pane (picture at y $P_Y)" || fail "X-sheet y $XS_Y1..$XS_Y2, pane picture y $P_Y"
[[ "$M_BIG" == "2593:-1:-1" ]] && pass "ANIM > Big Frame + X-Sheet is checked" || fail "menu item: '$M_BIG', wanted 2593:-1:-1"
screenshot "anim-big-frame-on"

# -- a click paints only the current frame --
T0=("${T[@]}")
key b; wait_for 0.3 "Brush"
click $(( P_X + P_W / 2 )) $(( P_Y + P_H / 2 )); wait_for 0.5 "paint"
bf_read
[[ "${T[1]}" != "${T0[1]}" && "${T[2]}" == "${T0[2]}" ]] && pass "a click in the big pane paints frame 1 only" || fail "paint: frame 1 ${T0[1]} -> ${T[1]}, frame 2 ${T0[2]} -> ${T[2]}"
key ctrl+z; wait_for 0.5 "undo"

# -- Num 5: the next frame in the pane; Ctrl+wheel zooms it --
bf_key KP_5; bf_read
[[ "$A_CUR" == 2 && "$P_F" == 2 && "$LB_P" == 1 ]] && pass "Num 5: frame 2 fills the pane" || fail "Num 5: $(bf_s)"
Z0=${Z:-0}
for i in 1 2; do with_mods ctrl scroll_up $(( P_X + P_W / 2 )) $(( P_Y + P_H / 2 )); wait_for 0.4 "Ctrl+wheel"; done
bf_read
[[ "${Z:-0}" =~ ^[0-9]+$ ]] && (( Z > 0 && Z != Z0 )) && pass "Ctrl+wheel zooms the big pane (zoom ${Z}%)" || fail "Ctrl+wheel: zoom '${Z:-}' (was $Z0)"
bf_key ctrl+0

# -- again: 3 panes, the X-sheet stays --
bf_cmd "big frame + x-sheet"; bf_read
[[ "$LB_SHOWN" == -1 && "$LB_P" == 3 && "$XS_CFG" == -1 && "$M_BIG" == "2593:0:-1" ]] && pass "Big Frame + X-Sheet again: 3 panes, the X-sheet stays, unchecked" || fail "toggle back: $(bf_s)"

# -- Num * cycles 3 -> 5 -> 7 -> 1 -> 3 --
GOT=""
for i in 1 2 3 4; do bf_key KP_Multiply; bf_read; GOT+="$LB_P "; done
[[ "$GOT" == "5 7 1 3 " ]] && pass "Num * cycles 3 -> 5 -> 7 -> 1 -> 3" || fail "Num * gave: $GOT(wanted 5 7 1 3)"

# -- LIGHTBOX_PANES=1 from the cfg is kept --
draw_quit
draw_settle
DRAW_EXTRA_ARGS="--option LIGHTBOX_PANES=1 $BF_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
bf_key KP_0; bf_read
[[ "$LB_SHOWN" == -1 && "$LB_P" == 1 ]] && pass "LIGHTBOX_PANES=1 in the cfg: Num 0 opens one pane" || fail "cfg LIGHTBOX_PANES=1: $(bf_s)"

rm -rf "$BF_DIR"
park_mouse
