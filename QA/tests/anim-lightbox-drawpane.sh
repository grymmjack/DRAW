#!/bin/bash
# =============================================================================
# anim-lightbox-drawpane.sh — QA test: the lightbox marks the pane a stroke
# goes into (field kit T-7, Rick 2026-11-08: "It's not clear to me which frame
# is being drawn on - we need this to be more prominent with a unique color and
# pattern or line thickness").
#
# Every pane takes strokes. The pane under the pointer (or, mid-stroke, the one
# the stroke started in) gets a thick ring in its own colour (theme
# ANIM_FRAME_DRAWING, magenta) with a dashed outer edge, outside the current
# frame's blue outline. Its label turns that colour too. Pointer off the panes:
# no ring. The old build marked only the current frame (blue).
#
# Dump: ANIMLB (... pad drawPane), ANIMLBP (per pane: frame dx dy dw dh).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: the lightbox marks the pane a stroke goes into ==="

LD_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LD_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LD_DIR="/tmp/draw-qa-lbdrawpane-$$"
mkdir -p "$LD_DIR"
magick -size 64x16 xc:'#303030' -fill '#c04040' -draw 'rectangle 2,2 5,5' -fill '#40c040' -draw 'rectangle 18,2 21,5' \
    -fill '#4040c0' -draw 'rectangle 34,2 37,5' -fill '#c0c040' -draw 'rectangle 50,2 53,5' "PNG32:$LD_DIR/plain.png"
LD_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,2,12,0,0).hex())")
python3 "$LD_PY" put "$LD_DIR/plain.png" "$LD_DIR/sheet.png" drAn "$LD_BLOB"

ld_read() { # LB_* (LB_DRAW = the marked pane), PANE_DX/DY/DW/DH[k]
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD LB_DRAW _ <<< "$(grep -m1 '^ANIMLB ' "$LD_DUMP")"
    local p k i; p=($(grep -m1 '^ANIMLBP ' "$LD_DUMP")); i=0
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        PANE_F[$i]=${p[$k]}; PANE_DX[$i]=${p[$((k + 1))]}; PANE_DY[$i]=${p[$((k + 2))]}; PANE_DW[$i]=${p[$((k + 3))]}; PANE_DH[$i]=${p[$((k + 4))]}
        i=$(( i + 1 ))
    done
}
ld_mid() { echo "$(( PANE_DX[$1] + PANE_DW[$1] / 2 )) $(( PANE_DY[$1] + PANE_DH[$1] * 3 / 4 ))"; }
ld_hover() { # K - the pointer over pane K (two moves: a render either side)
    local x y; read -r x y <<< "$(ld_mid "$1")"
    hover $(( x + 1 )) "$y"; wait_for 0.2 "render"; hover "$x" "$y"; wait_for 0.4 "over pane $1"
}
ld_magenta() { # K [MARGIN=8] -> the count of ring-coloured pixels in pane K's picture + MARGIN px round it
    local m=${2:-8}
    snap_region $(( PANE_DX[$1] - m )) $(( PANE_DY[$1] - m )) $(( PANE_DW[$1] + 2 * m )) $(( PANE_DH[$1] + 2 * m )) "lbdrawpane-$1" >/dev/null
    magick "$SNAP_RESULT" -alpha off -fuzz 12% -fill white -opaque '#ff46c8' -fill black +opaque white \
        -format '%[fx:int(mean*w*h+0.5)]' info: 2>/dev/null
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LD_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key b; wait_for 0.3 "Brush"
park_mouse; key KP_0; wait_for 0.8 "Lightbox"
hover 300 250; wait_for 0.3 "render"
ld_read
if [[ "${LB_SHOWN:-}" != -1 || "${#PANE_DX[@]}" -lt 3 ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', ${#PANE_DX[@]} panes"
else
    info "panes: frames ${PANE_F[*]}"
    # the pointer on the strip: no pane marked
    hover $(( LB_X1 + 20 )) $(( LB_SY + LB_SH / 2 )); wait_for 0.2 "render"; hover $(( LB_X1 + 22 )) $(( LB_SY + LB_SH / 2 )); wait_for 0.4 "strip"
    ld_read; M0=$(ld_magenta 0); M1=$(ld_magenta 1); M2=$(ld_magenta 2)
    [[ "${LB_DRAW:-}" == -1 && "$M0" == 0 && "$M1" == 0 && "$M2" == 0 ]] && pass "pointer on the strip: no pane marked (ring px $M0 / $M1 / $M2)" \
        || fail "pointer on the strip: drawPane '${LB_DRAW:-}', ring px $M0 / $M1 / $M2 (wanted -1, 0 / 0 / 0)"

    for k in 0 1 2; do
        ld_hover "$k"; ld_read
        # the marked pane with its ring; the others inside their own picture (the ring sits in the gap)
        for j in 0 1 2; do if [[ $j == "$k" ]]; then MK[$j]=$(ld_magenta "$j" 8); else MK[$j]=$(ld_magenta "$j" 0); fi; done
        M0=${MK[0]}; M1=${MK[1]}; M2=${MK[2]}
        [[ $k == 1 ]] && screenshot "anim-lightbox-drawpane-current"
        OTHERS=0; for j in 0 1 2; do [[ $j != "$k" ]] && OTHERS=$(( OTHERS + MK[j] )); done
        # a ring round the picture: at least its perimeter, and nowhere else
        PER=$(( PANE_DW[k] + PANE_DH[k] ))
        if [[ "${LB_DRAW:-}" == "$k" ]] && (( MK[k] >= PER && OTHERS == 0 )); then
            pass "over pane $k (frame ${PANE_F[$k]}): it is marked, ring px ${MK[$k]} (>= $PER), none round the others"
        else
            fail "over pane $k: drawPane '${LB_DRAW:-}', ring px $M0 / $M1 / $M2 (wanted >= $PER round pane $k only)"
        fi
    done

    # mid-stroke the mark stays on the pane the stroke started in
    read -r X0 Y0 <<< "$(ld_mid 0)"; read -r X1 Y1 <<< "$(ld_mid 1)"
    mouse_down "$X0" "$Y0"
    hover $(( (X0 + X1) / 2 )) "$Y0"; sleep 0.15; hover "$X1" "$Y1"; wait_for 0.5 "stroke into pane 1"
    ld_read; SD=$LB_DRAW
    mouse_up; wait_for 0.4 "release"
    [[ "$SD" == 0 ]] && pass "a stroke from pane 0 into pane 1: pane 0 stays marked" || fail "mid-stroke drawPane '$SD', wanted 0 (the stroke's pane)"
    park_mouse; key ctrl+z; wait_for 0.5 "undo the stroke"
    screenshot "anim-lightbox-drawpane"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LD_DIR"
assert_window_exists
