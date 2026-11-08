#!/bin/bash
# =============================================================================
# anim-lightbox-crosshair.sh — QA test: the Shift crosshair in the lightbox.
#
# Rick, 2026-11-08 (field kit T-23): holding Shift showed the crosshair over
# the lightbox's strip and bar too, and off the pointer (drawn with the sheet
# view's mapping). It now shows only over the pane under the pointer, through
# that pane's view: its lines cross at the pointer and stop at the pane.
#
# Dump: ANIM, ANIMLB (strip + bar bands), ANIMLBP (per pane: frame dx dy dw dh).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3
# =============================================================================
info "=== Animation: the Shift crosshair in the lightbox ==="

LC_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LC_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LC_DIR="/tmp/draw-qa-lbcross-$$"
mkdir -p "$LC_DIR"
magick -size 64x16 xc:'#303030' -fill '#c04040' -draw 'rectangle 2,2 5,5' -fill '#40c040' -draw 'rectangle 18,2 21,5' \
    -fill '#4040c0' -draw 'rectangle 34,2 37,5' -fill '#c0c040' -draw 'rectangle 50,2 53,5' "PNG32:$LC_DIR/plain.png"
LC_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,2,12,0,0).hex())")
python3 "$LC_PY" put "$LC_DIR/plain.png" "$LC_DIR/sheet.png" drAn "$LC_BLOB"

lc_read() {
    read -r _ _ _ A_CUR _ <<< "$(grep -m1 '^ANIM ' "$LC_DUMP")"
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH _ <<< "$(grep -m1 '^ANIMLB ' "$LC_DUMP")"
    local p k; p=($(grep -m1 '^ANIMLBP ' "$LC_DUMP")); PX=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; }
    done
}
lc_snaps() { # TAG: the current pane -> $LC_DIR/pane-TAG.png, the strip + bar -> bands-TAG.png
    snap_region "$PX" "$PY" "$PW" "$PH" "lbcross-pane-$1" && cp "$SNAP_RESULT" "$LC_DIR/pane-$1.png"
    snap_region "$LB_X1" "$LB_SY" $(( LB_X2 - LB_X1 + 1 )) $(( LB_SH + LB_BH )) "lbcross-bands-$1" && cp "$SNAP_RESULT" "$LC_DIR/bands-$1.png"
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LC_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key b; wait_for 0.3 "Brush"
park_mouse; key KP_0; wait_for 0.8 "Lightbox"
hover 300 250; wait_for 0.3 "render"
lc_read
if [[ "${LB_SHOWN:-}" != -1 || -z "$PX" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', current pane '${PX:-}'"
else
    # the pointer over pixel (10, 11) of the current frame's pane
    MX=$(( PX + (21 * PW) / 32 )); MY=$(( PY + (23 * PH) / 32 ))
    hover "$MX" "$MY"; wait_for 0.3 "over the pane"
    hover $(( MX + 1 )) "$MY"; wait_for 0.2 "render"; hover "$MX" "$MY"; wait_for 0.4 "render"
    lc_snaps plain
    xdotool keydown shift; wait_for 0.3 "Shift down"
    hover $(( MX + 1 )) "$MY"; wait_for 0.2 "render"; hover "$MX" "$MY"; wait_for 0.5 "render"
    lc_snaps shift
    xdotool keyup shift; wait_for 0.3 "Shift up"

    assert_regions_same "$LC_DIR/bands-plain.png" "$LC_DIR/bands-shift.png" "Shift over a pane: no crosshair on the strip / transport bar" 0
    assert_regions_differ "$LC_DIR/pane-plain.png" "$LC_DIR/pane-shift.png" "Shift over a pane: the crosshair shows in it"
    # the vertical line in the pane's top rows sits at the pointer's pixel
    IW=$(magick identify -format %w "$LC_DIR/pane-plain.png"); IH=$(magick identify -format %h "$LC_DIR/pane-plain.png")
    S10=$(( IW * 10 / PW )); [[ $S10 -lt 10 ]] && S10=10
    BAND=$(( 4 * S10 / 10 ))
    BOX=$(magick "$LC_DIR/pane-plain.png" "$LC_DIR/pane-shift.png" -compose difference -composite \
        -crop "${IW}x${BAND}+0+$(( 2 * S10 / 10 ))" +repage -threshold 0 -format '%@' info: 2>/dev/null)
    # the crosshair marks the left edge of the frame pixel under the pointer (as in sheet view)
    WANT=$(( ((MX - PX) * 16 / PW) * PW * S10 / 160 ))
    if [[ "$BOX" =~ ^([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+)$ ]]; then
        BW=${BASH_REMATCH[1]}; BX=${BASH_REMATCH[3]}
        info "  vertical line at x $BX..$(( BX + BW - 1 )) (image px), the pointer's pixel edge at x $WANT"
        if (( BW <= 4 * S10 / 10 + 4 && WANT >= BX - S10 / 10 - 2 && WANT <= BX + BW + S10 / 10 + 1 )); then
            pass "the crosshair's vertical line is on the pointer's pixel"
        else
            fail "the crosshair's vertical line is at x $BX (width $BW), the pointer's pixel at $WANT"
        fi
    else
        fail "no crosshair line in the pane's top rows (diff box '$BOX')"
    fi
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LC_DIR"
assert_window_exists
