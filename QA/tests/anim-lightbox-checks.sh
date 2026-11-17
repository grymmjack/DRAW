#!/bin/bash
# =============================================================================
# anim-lightbox-checks.sh — QA test: the lightbox's transparency checks stay
# put from frame to frame.
#
# Rick 2026-11-16: "when playback is happening the transparency grid is moving
# to the left and going slightly up and back down when playing back". Each
# pane cut its checks from the canvas checkerboard at its frame's place on the
# sheet, so frames that sit a part-check apart (here 20 px frames, 8 px checks)
# showed checks shifted sideways, and a frame on the next row shifted down.
# Now every frame takes them from the checkerboard's corner: the same checks.
#
# Fixture: a 60x40 sheet of 20x20 frames (3 across, 2 down), all transparent.
# The current pane's picture (ANIMLBP) at frames 1, 2 and 4 must be the same.
#
# Dump: ANIM (count, current), ANIMLBP (panes: frame dx dy dw dh).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=1 TRANSPARENCY_CHECK_SIZE_X=8 TRANSPARENCY_CHECK_SIZE_Y=8
# =============================================================================
info "=== Animation: the lightbox's checks stay put frame to frame ==="

LK_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LK_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LK_DIR="/tmp/draw-qa-lbchecks-$$"
mkdir -p "$LK_DIR"
magick -size 60x40 xc:none "PNG32:$LK_DIR/plain.png"
python3 "$LK_PY" put "$LK_DIR/plain.png" "$LK_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,20,20,0,0,6,1,12,0,0).hex())")"

lk_line() { grep -m1 "^$1 " "$LK_DUMP" 2>/dev/null; }
lk_read() { # A_COUNT A_CUR, the current pane's picture PX PY PW PH
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(lk_line ANIM)"
    local p k; p=($(lk_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
lk_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
lk_goto() { # FRAME - Num 5 (next frame) until it is current
    local n
    for (( n = 0; n < 8 && A_CUR != $1; n++ )); do lk_key KP_5; lk_read; done
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LK_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
lk_read
[[ "$A_COUNT" == 6 ]] || fail "the sheet: $A_COUNT frames, wanted 6"
lk_key KP_0
lk_read
if [[ -z "$PW" || "${PW:-0}" -lt 20 ]]; then
    fail "no lightbox pane for frame $A_CUR: [$(lk_line ANIMLBP)]"
else
    # the middle of the picture (its edges can carry the pane's frame)
    SX=$(( PX + 2 )); SY=$(( PY + 2 )); SW=$(( PW - 4 )); SH=$(( PH - 4 ))
    snap_region "$SX" "$SY" "$SW" "$SH" "lbchecks-f1"; S1=$SNAP_RESULT
    lk_goto 2
    if [[ "$A_CUR" == 2 ]]; then
        snap_region "$SX" "$SY" "$SW" "$SH" "lbchecks-f2"; S2=$SNAP_RESULT
        assert_regions_same "$S1" "$S2" "frame 2 (20 px along the sheet): the same checks as frame 1" 0
    else
        fail "could not reach frame 2 (current $A_CUR)"
    fi
    lk_goto 4
    if [[ "$A_CUR" == 4 ]]; then
        snap_region "$SX" "$SY" "$SW" "$SH" "lbchecks-f4"; S4=$SNAP_RESULT
        assert_regions_same "$S1" "$S4" "frame 4 (the next row down): the same checks as frame 1" 0
    else
        fail "could not reach frame 4 (current $A_CUR)"
    fi
fi
assert_no_crash
rm -rf "$LK_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
