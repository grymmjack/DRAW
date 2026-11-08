#!/bin/bash
# =============================================================================
# anim-lightbox-follow.sh — QA test: with Clip Strokes to the Frame off, a
# freehand stroke runs on into the next pane.
#
# Rick, 2026-11-08: "if i have clip frames turned off - it only draws across
# the rows, not the entire thing in the lightbox. like all 7 frames ... it drew
# across the first 3, then the second 3". A stroke past a pane's edge went on
# into the cell beside it on the sheet (or off the sheet), not into the next
# pane's frame. Now a brush / dot / spray / eraser stroke stays in the panes:
# each pane's part lands in its own frame, nothing outside the cells changes,
# and it is one undo step.
#
# Dump: ANIM, ANIMC (a CRC per frame cell), ANIMLBP (per pane: frame dx dy dw dh).
# Fixture: a 48x48 sheet of 16x16 frames, 3 per row, 7 frames, current 3 - so
# the pane after frame 3 shows frame 4, the first cell of the next row.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 CLIP_FRAME_LIGHTBOX=0
# =============================================================================
info "=== Animation: a stroke runs on into the next pane (clip off) ==="

LF_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LF_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LF_DIR="/tmp/draw-qa-lbfollow-$$"
mkdir -p "$LF_DIR"
LF_DRAW=()
for n in 0 1 2 3 4 5 6; do
    x=$(( (n % 3) * 16 )); y=$(( (n / 3) * 16 ))
    LF_DRAW+=(-fill "#$(printf '%02x%02x%02x' $(( 40 + n * 30 )) $(( 200 - n * 20 )) 90)" -draw "rectangle $(( x + 1 )),$(( y + 1 )) $(( x + 4 )),$(( y + 4 ))")
done
magick -size 48x48 xc:none "${LF_DRAW[@]}" "PNG32:$LF_DIR/plain.png"
LF_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$LF_PY" put "$LF_DIR/plain.png" "$LF_DIR/sheet.png" drAn "$LF_BLOB"

lf_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2; }
lf_read() {
    lf_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(grep -m1 '^ANIM ' "$LF_DUMP")"
    A_T=""; read -r _ A_T <<< "$(grep -m1 '^ANIMC ' "$LF_DUMP")"; T=(x $A_T)
    LP=($(grep -m1 '^ANIMLBP ' "$LF_DUMP"))
}
lf_pane() { # FRAME -> QX QY QW QH (its pane's picture)
    local k; QX=""
    for (( k = 3; k + 4 < ${#LP[@]}; k += 5 )); do
        [[ "${LP[$k]}" == "$1" ]] && { QX=${LP[$((k + 1))]}; QY=${LP[$((k + 2))]}; QW=${LP[$((k + 3))]}; QH=${LP[$((k + 4))]}; }
    done
}
lf_changed() { # "F..." -> 0 when exactly those frames differ from T0
    local i want=" $1 "
    for (( i = 1; i <= 7; i++ )); do
        if [[ "$want" == *" $i "* ]]; then [[ "${T[$i]}" != "${T0[$i]}" ]] || return 1
        else [[ "${T[$i]}" == "${T0[$i]}" ]] || return 1; fi
    done
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LF_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key b; wait_for 0.3 "Brush"
park_mouse; key KP_0; wait_for 0.8 "Lightbox"
lf_read
T0=(x $A_T)
lf_pane 3; X3=$QX; Y3=$QY; W3=$QW; H3=$QH
lf_pane 4; X4=$QX; W4=$QW
if [[ "$A_COUNT" != 7 || "$A_CUR" != 3 || -z "$X3" || -z "$X4" ]]; then
    fail "lightbox: $A_COUNT frames, current $A_CUR, panes of frames 3 / 4 '${X3:-}' / '${X4:-}'"
else
    # a stroke along row 10 of the frames: from the middle of frame 3's pane to the middle of frame 4's
    SY=$(( Y3 + (21 * H3) / 32 ))
    SX=$(( X3 + W3 / 2 )); EX=$(( X4 + W4 / 2 ))
    lf_edges() { # TAG: frame 3's last quarter and frame 4's first quarter along the stroke's row
        snap_region $(( X3 + (3 * W3) / 4 )) $(( SY - 2 )) $(( W3 / 4 - 1 )) 5 "lbfollow-3r-$1" && cp "$SNAP_RESULT" "$LF_DIR/e3-$1.png"
        snap_region $(( X4 + 1 )) $(( SY - 2 )) $(( W4 / 4 - 1 )) 5 "lbfollow-4l-$1" && cp "$SNAP_RESULT" "$LF_DIR/e4-$1.png"
    }
    lf_edges before
    hover "$SX" "$SY"; sleep 0.3
    mouse_down "$SX" "$SY"
    for (( i = 1; i <= 12; i++ )); do hover $(( SX + (EX - SX) * i / 12 )) "$SY"; sleep 0.08; done
    sleep 0.2; mouse_up; wait_for 0.6 "stroke released"
    lf_read
    lf_edges after
    info "  cells after the stroke: ${T[*]:1}"
    assert_regions_differ "$LF_DIR/e3-before.png" "$LF_DIR/e3-after.png" "the stroke reaches frame 3's right edge"
    assert_regions_differ "$LF_DIR/e4-before.png" "$LF_DIR/e4-after.png" "the stroke goes on from frame 4's left edge"
    lf_changed "3 4" && pass "a stroke from frame 3's pane into frame 4's: both frames get their part, the other five stay" \
        || fail "stroke 3 -> 4: changed cells don't match (T0 ${T0[*]:1}, now ${T[*]:1})"
    park_mouse; key ctrl+z; wait_for 0.6 "Undo"; lf_read
    lf_changed "" && pass "undo: one step takes back both parts" || fail "undo the stroke: cells ${T[*]:1}"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LF_DIR"
assert_window_exists
