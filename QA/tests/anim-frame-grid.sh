#!/bin/bash
# =============================================================================
# anim-frame-grid.sh — QA test: the animation frame grid in sheet view.
#
# Animation 1.3 (PLANS/ANIMATION.md): a sheet with frames shows each cell's
# border, the frame numbers and a 2 px outline round the current frame; View >
# Frame Grid (action 2500, CFG FRAME_GRID) hides and shows it; a picture
# without frames draws nothing.
#
# Fixture (made here): a 64x32 sheet carrying a drAn chunk - 16x16 frames,
# 7 of the 8 cells, current frame 3 (TOOLS/ANIM serialize layout). DRAW opens
# it from the command line. Where the cells land on screen comes from the QA
# dump: VIEW (zoom %) and ANIM (... drawn dx dy). Small regions straddle the
# frame 1|2 border (orange), the frame 2|3 border (frame 3 = current, cyan
# outline) and frame 2's number, compared with the grid on / off / on again.
#
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: frame grid overlay ==="

FG_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
FG_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
FG_DIR="/tmp/draw-qa-fgrid-$$"
mkdir -p "$FG_DIR"
magick -size 64x32 xc:'#204060' -fill '#c04040' -draw 'rectangle 20,4 27,11' "$FG_DIR/plain.png"
# version 1; 16x16 frames; gutter 0; margin 0; 7 frames; current 3; 12 fps; loop fwd; no holds
FG_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$FG_PY" put "$FG_DIR/plain.png" "$FG_DIR/sheet.png" drAn "$FG_BLOB"

fg_dump_line() { # KEY -> that dump line's fields (after a couple of drawn frames)
    { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.4 "render"; } >&2
    grep -m1 "^$1 " "$FG_DUMP" 2>/dev/null
}
fg_toggle() {
    park_mouse
    key question
    wait_for 0.4 "Command palette open"
    type_text "frame grid"
    wait_for 0.3 "Filtered"
    key Return
    wait_for 0.5 "Frame grid toggled"
}

# -- a sheet with frames --
info "Launching DRAW with a 64x32 sheet of 16x16 frames"
draw_quit
draw_settle # a small file loads fast enough to race the old window (see draw_settle)
DRAW_EXTRA_ARGS="$FG_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
# Zoom 100%: the 64x32 sheet then sits whole inside the work area whatever the
# docks (a small file auto-zooms to fill the viewport, part of it behind panels)
park_mouse
key ctrl+0
wait_for 0.5 "Zoom 100%"

read -r _ FG_ON FG_COUNT FG_CUR _ _ _ _ FG_COLS FG_ROWS _ _ FG_DRAWN FG_DX FG_DY <<< "$(fg_dump_line ANIM)"
read -r _ FG_ZOOM _ <<< "$(fg_dump_line VIEW)"
info "ANIM on=$FG_ON count=$FG_COUNT current=$FG_CUR cells=${FG_COLS}x$FG_ROWS drawn=$FG_DRAWN at ($FG_DX,$FG_DY), zoom ${FG_ZOOM}%"
[[ "$FG_ON" == -1 && "$FG_COUNT" == 7 && "$FG_CUR" == 3 && "$FG_COLS" == 4 && "$FG_ROWS" == 2 ]] \
    && pass "the sheet opened with its frames (7 of 4x2 cells, current 3)" \
    || fail "frames not loaded: on=$FG_ON count=$FG_COUNT current=$FG_CUR cells=${FG_COLS}x$FG_ROWS"
[[ "$FG_DRAWN" == -1 ]] && pass "the frame grid is drawn" || fail "the frame grid is not drawn (drawn=$FG_DRAWN)"

if [[ -n "$FG_ZOOM" && -n "$FG_DX" && "$FG_DRAWN" == -1 ]]; then
    fg_x() { echo $(( FG_DX + $1 * FG_ZOOM / 100 )); }   # canvas x -> viewport x
    fg_y() { echo $(( FG_DY + $1 * FG_ZOOM / 100 )); }
    B12_X=$(( $(fg_x 16) - 3 )); B23_X=$(( $(fg_x 32) - 3 )); MID_Y=$(fg_y 6)
    LBL_X=$(( $(fg_x 16) + 1 )); LBL_Y=$(( $(fg_y 0) + 1 ))
    info "regions: 1|2 border x=$B12_X, 2|3 border x=$B23_X, y=$MID_Y; frame 2 number at ($LBL_X,$LBL_Y)"
    park_mouse
    snap_region "$B12_X" "$MID_Y" 6 16 "fg-b12-on";  FG_B12_ON="$SNAP_RESULT"
    snap_region "$B23_X" "$MID_Y" 6 16 "fg-b23-on";  FG_B23_ON="$SNAP_RESULT"
    snap_region "$LBL_X" "$LBL_Y" 8 8 "fg-lbl-on";   FG_LBL_ON="$SNAP_RESULT"

    # the current frame's outline is cyan, the plain border orange (THEME.ANIM_FRAME_*)
    fg_has() { magick "$1" -fuzz 12% -fill black +opaque "$2" -format '%[fx:maxima.r+maxima.g+maxima.b>0?1:0]' info: 2>/dev/null; }
    [[ "$(fg_has "$FG_B23_ON" 'rgb(80,200,255)')" == 1 ]] && pass "the current frame (3) has its cyan outline" \
        || fail "no cyan outline at the current frame's edge"

    info "View > Frame Grid: off"
    fg_toggle
    read -r _ _ _ _ _ _ _ _ _ _ _ _ FG_DRAWN _ <<< "$(fg_dump_line ANIM)"
    [[ "$FG_DRAWN" == 0 ]] && pass "toggled off: not drawn" || fail "still drawn after toggling off (drawn=$FG_DRAWN)"
    park_mouse
    snap_region "$B12_X" "$MID_Y" 6 16 "fg-b12-off"; FG_B12_OFF="$SNAP_RESULT"
    snap_region "$B23_X" "$MID_Y" 6 16 "fg-b23-off"; FG_B23_OFF="$SNAP_RESULT"
    snap_region "$LBL_X" "$LBL_Y" 8 8 "fg-lbl-off";  FG_LBL_OFF="$SNAP_RESULT"
    assert_regions_differ "$FG_B12_ON" "$FG_B12_OFF" "the frame 1|2 border goes away"
    assert_regions_differ "$FG_B23_ON" "$FG_B23_OFF" "the current frame outline goes away"
    assert_regions_differ "$FG_LBL_ON" "$FG_LBL_OFF" "frame 2's number goes away"

    info "View > Frame Grid: on again"
    fg_toggle
    park_mouse
    snap_region "$B12_X" "$MID_Y" 6 16 "fg-b12-on2"; assert_regions_same "$FG_B12_ON" "$SNAP_RESULT" "the 1|2 border comes back as it was" 3
    snap_region "$B23_X" "$MID_Y" 6 16 "fg-b23-on2"; assert_regions_same "$FG_B23_ON" "$SNAP_RESULT" "the current outline comes back as it was" 3
    snap_region "$LBL_X" "$LBL_Y" 8 8 "fg-lbl-on2";  assert_regions_same "$FG_LBL_ON" "$SNAP_RESULT" "the number comes back as it was" 3
fi

# -- a picture without frames: nothing drawn --
info "Relaunching with the same picture, no frames"
draw_quit
draw_settle # a small file loads fast enough to race the old window (see draw_settle)
DRAW_EXTRA_ARGS="$FG_DIR/plain.png"
draw_launch 15
wait_for 1.5 "Picture loaded"
read -r _ FG_ON _ _ _ _ _ _ _ _ _ _ FG_DRAWN _ <<< "$(fg_dump_line ANIM)"
[[ "$FG_ON" == 0 && "$FG_DRAWN" == 0 ]] && pass "a picture without frames has no frame grid" \
    || fail "a plain picture got frames (on=$FG_ON drawn=$FG_DRAWN)"

# leave a plain DRAW running for the next test
draw_quit
draw_settle # a small file loads fast enough to race the old window (see draw_settle)
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$FG_DIR"
assert_window_exists
