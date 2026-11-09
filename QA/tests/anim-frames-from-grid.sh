#!/bin/bash
# =============================================================================
# anim-frames-from-grid.sh — QA test: ANIM > Create Frames from Grid.
#
# Rick, 2026-11-08: "i would like ANIM -> CREATE FRAMES FROM GRID - because
# there are times when i can just guess the grid and hold down g and arrows to
# get it right, and then it would be perfect." The frame size becomes the
# pixel grid's cell; the frames run up to the last cell with something drawn;
# one undo step (back to a plain picture).
#
# Dump: ANIM active count current frameW frameH.
# Fixture: a plain 64x48 picture, sprites in 16x16 cells 1-6 (4 per row).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 GRID_SIZE_X=14 GRID_SIZE_Y=14
# =============================================================================
info "=== Animation: Create Frames from Grid ==="

FG_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
FG_DIR="/tmp/draw-qa-fromgrid-$$"
mkdir -p "$FG_DIR"
FG_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( (n % 4) * 16 )); y=$(( (n / 4) * 16 ))
    FG_DRAW+=(-fill "#c0$(printf '%02x' $(( 40 + n * 30 )))40" -draw "rectangle $(( x + 3 )),$(( y + 3 )) $(( x + 12 )),$(( y + 12 ))")
done
magick -size 64x48 xc:none "${FG_DRAW[@]}" "PNG32:$FG_DIR/plain.png"

fg_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ A_ON A_COUNT A_CUR A_FW A_FH _ <<< "$(grep -m1 '^ANIM ' "$FG_DUMP")"
}
fg_s() { echo "active ${A_ON:-?}, ${A_COUNT:-?} frames of ${A_FW:-?}x${A_FH:-?}, current ${A_CUR:-?}"; }
fg_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$FG_DIR/plain.png"
draw_launch 15
wait_for 1.5 "Picture loaded"
assert_no_crash
fg_read
[[ "$A_ON" == 0 ]] || fail "start: $(fg_s) (wanted a plain picture)"

# G + arrows: the grid from 14x14 to 16x16, as a hand would
park_mouse; draw_focus
raw_key down g; sleep 0.3
for k in Right Right Down Down; do raw_key down "$k"; sleep 0.2; raw_key up "$k"; sleep 0.2; done
raw_key up g; wait_for 0.4 "grid sized"

fg_palette "create frames from grid"; fg_read
[[ "$A_ON" == -1 && "$A_COUNT" == 6 && "$A_FW" == 16 && "$A_FH" == 16 && "$A_CUR" == 1 ]] \
    && pass "Create Frames from Grid after G+arrows to 16x16: 6 frames of 16x16 (up to the last drawn cell), frame 1" \
    || fail "from grid: $(fg_s) (wanted 6 frames of 16x16)"
park_mouse; key ctrl+z; wait_for 0.6 "Undo"; fg_read
[[ "$A_ON" == 0 ]] && pass "undo: a plain picture again" || fail "undo: $(fg_s)"
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$FG_DIR"
assert_window_exists
