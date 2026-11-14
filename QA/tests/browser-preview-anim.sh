#!/bin/bash
# =============================================================================
# browser-preview-anim.sh — QA test: the Browser's preview pane plays
# animations and shows .draw files (Rick, 2026-11-14: "make the preview of
# browser support animations, and also it cannot preview .draw files?! ...
# give it basic animation controls, play, pause, and seek, in the preview pane").
#
#  - an animated GIF: its frames play (the frame showing moves on, the pane redraws)
#  - pause stops it; play starts it again
#  - a click on the seek track jumps there; a drag along it scrubs to the end
#  - a press on the controls arms no file drag-out (dragging off the panel is not a drop)
#  - a PNG with frames (drAn chunk) plays too; a still PNG has no controls
#  - a .draw file shows its picture
#
# Dump: BROWSERPV frames showing playing seeking boxX boxY boxS trackX trackW
# picW picH name | BROWSERS ... (rows) | BROWSERL (list x, dialog w) | WIN browser.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BROWSER_POS_X=40 BROWSER_POS_Y=40 BROWSER_WIDTH=520 BROWSER_HEIGHT=360 BROWSER_DEFAULT_VIEW_MODE=0 BROWSER_DEFAULT_PREVIEW_OPEN=1 BROWSER_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Browser: animated preview + .draw files ==="

PV_DIR="/tmp/draw-qa-brpv-$$"
mkdir -p "$PV_DIR"
# 4 frames, 10 cs each: red, green, blue, yellow
magick -delay 10 -size 24x24 xc:red xc:lime xc:blue xc:yellow -loop 0 "$PV_DIR/a-anim.gif"
# a 4-frame sheet (16x16 cells in a row) with a drAn chunk: v1, 16x16, gutter 0,
# margin 0, 4 frames, current 1, 8 fps, loop 0, no holds
magick -size 64x16 xc:none -fill red -draw 'rectangle 0,0 15,15' -fill lime -draw 'rectangle 16,0 31,15' \
    -fill blue -draw 'rectangle 32,0 47,15' -fill yellow -draw 'rectangle 48,0 63,15' "PNG32:$PV_DIR/plain.png"
PV_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,8,0,0).hex())")
python3 "$DRAW_ROOT/QA/fixtures/png-chunk.py" put "$PV_DIR/plain.png" "$PV_DIR/c-sheet.png" drAn "$PV_BLOB"
rm -f "$PV_DIR/plain.png"
magick -size 32x20 xc:'#3060a0' "PNG32:$PV_DIR/d-still.png"
cp "$DRAW_ROOT/QA/fixtures/drawer-40.draw" "$PV_DIR/b-project.draw"

draw_quit
draw_settle
DRAW_TEST_OPTIONS+=" --option BROWSER_DEFAULT_FOLDER=$PV_DIR"
draw_launch 15
wait_for 1.5 "launched, the Browser at $PV_DIR"
dk_begin

pv() { read -r _ PV_N PV_K PV_PLAY PV_SEEK PV_BX PV_BY PV_BS PV_TX PV_TW PV_PW PV_PH PV_NAME <<< "$(grep -m1 '^BROWSERPV ' "$DK_DUMP")"; }
bs() { read -r _ BS_VIS BS_SEL _ BS_ROWH BS_TOP BS_SCROLL BS_N _ _ _ BS_DRAG _ <<< "$(grep -m1 '^BROWSERS ' "$DK_DUMP")"; }
bwin() { read -r _ _ WX WY WW WH _ <<< "$(grep -m1 '^WIN browser ' "$DK_DUMP")"; read -r _ _ LX _ _ _ _ DW _ <<< "$(grep -m1 '^BROWSERL' "$DK_DUMP")"; }
pv_s() { pv; echo "$PV_NAME: frames $PV_N showing $PV_K playing $PV_PLAY seek $PV_SEEK picture ${PV_PW}x$PV_PH"; }
vx() { echo $(( WX + $1 * WW / DW )); }
vy() { echo $(( WY + $1 * WW / DW )); }
# select the list entry called NAME
pick() {
    local i fy
    bs; bwin
    for (( i = 0; i < BS_N; i++ )); do
        fy=$(( BS_TOP + i * BS_ROWH - BS_SCROLL + BS_ROWH / 2 ))
        click "$(vx $(( LX + 30 )))" "$(vy "$fy")"; wait_for 0.5 "row $i"; dk_settle; pv
        [[ "$PV_NAME" == "$1" ]] && return 0
    done
    fail "no entry $1 in the list ($BS_N entries)"; return 1
}

bs
(( BS_VIS == -1 && BS_N >= 4 )) && pass "the Browser shows the fixtures ($BS_N entries)" || fail "Browser: visible $BS_VIS, $BS_N entries"

# --- an animated GIF plays ---------------------------------------------------------
pick a-anim.gif
pv
(( PV_N == 4 && PV_PLAY == -1 && PV_BS > 0 )) && pass "a-anim.gif: 4 frames, playing, controls drawn" || fail "a-anim.gif: $(pv_s)"
(( PV_PW == 24 && PV_PH == 24 )) && pass "its picture 24x24" || fail "picture ${PV_PW}x$PV_PH"
SEEN=" $PV_K"
for t in 1 2 3 4 5 6; do wait_for 0.25 "playing"; dk_settle; pv; SEEN+=" $PV_K"; done
DISTINCT=$(echo $SEEN | tr ' ' '\n' | sort -u | wc -l)
(( DISTINCT >= 3 )) && pass "it plays: frames seen [$SEEN ]" || fail "it does not move on: frames seen [$SEEN ]"
bwin
# the picture: the middle of the pane, just above the controls
MIDX=$(( (PV_BX + PV_TX + PV_TW) / 2 )); PICY=$(( PV_BY - 12 ))
snap_region $(( $(vx $MIDX) - 8 )) "$(vy $PICY)" 16 4 "pv-a"; SA=$SNAP_RESULT
wait_for 0.15 "a frame later"
snap_region $(( $(vx $MIDX) - 8 )) "$(vy $PICY)" 16 4 "pv-b"; SB=$SNAP_RESULT
assert_regions_differ "$SA" "$SB" "the pane redraws as it plays"
screenshot "browser-preview-anim-playing"

# --- pause / play ----------------------------------------------------------------------
click "$(vx $(( PV_BX + PV_BS / 2 )))" "$(vy $(( PV_BY + PV_BS / 2 )))"; wait_for 0.4 "pause"; dk_settle; pv
K0=$PV_K
(( PV_PLAY == 0 )) && pass "the box pauses it" || fail "pause: $(pv_s)"
wait_for 0.8 "paused a while"; dk_settle; pv
(( PV_K == K0 )) && pass "paused: it stays on frame $K0" || fail "paused but moved $K0 -> $PV_K"
bs; (( BS_DRAG == 0 )) && pass "a press on the box arms no file drag" || fail "the box armed a file drag (drag $BS_DRAG)"

# --- seek: a click at the end of the track, a drag back to the start ---------------
click "$(vx $(( PV_TX + PV_TW - 2 )))" "$(vy $(( PV_BY + PV_BS / 2 )))"; wait_for 0.4 "seek to the end"; dk_settle; pv
(( PV_K == 4 && PV_PLAY == 0 )) && pass "a click at the track's end: frame 4 (still paused)" || fail "seek end: $(pv_s)"
drag "$(vx $(( PV_TX + PV_TW - 2 )))" "$(vy $(( PV_BY + PV_BS / 2 )))" "$(vx $(( PV_TX + 1 )))" "$(vy $(( PV_BY + PV_BS / 2 )))"
wait_for 0.4 "scrubbed"; dk_settle; pv
(( PV_K == 1 && PV_SEEK == 0 )) && pass "a drag back along it: frame 1" || fail "scrub: $(pv_s)"
# a scrub that leaves the panel: no file drag-out
mouse_down "$(vx $(( PV_TX + 2 )))" "$(vy $(( PV_BY + PV_BS / 2 )))"; wait_for 0.2 "held"
hover $(( WX + WW + 40 )) $(( WY + WH / 2 )); wait_for 0.3 "outside"; dk_settle; bs; pv
DRAG_OUT=$BS_DRAG; SEEK_OUT=$PV_SEEK
mouse_up; wait_for 0.5 "released"; dk_park; dk_settle; bs; pv
(( DRAG_OUT == 0 && SEEK_OUT == -1 )) && pass "scrubbing off the panel stays a scrub (no file drag)" || fail "off the panel: drag $DRAG_OUT seek $SEEK_OUT"
(( BS_VIS == -1 )) && pass "and the Browser is still there (nothing dropped)" || fail "the Browser went away: $(pv_s)"
click "$(vx $(( PV_BX + PV_BS / 2 )))" "$(vy $(( PV_BY + PV_BS / 2 )))"; wait_for 0.4 "play"; dk_settle; pv
(( PV_PLAY == -1 )) && pass "the box plays it again" || fail "play: $(pv_s)"

# --- a sheet with frames ------------------------------------------------------------------
pick c-sheet.png
(( PV_N == 4 && PV_PLAY == -1 )) && pass "c-sheet.png (drAn): 4 frames playing" || fail "sheet: $(pv_s)"
# --- a still picture -------------------------------------------------------------------------
pick d-still.png
(( PV_N == 0 && PV_PW == 32 && PV_PH == 20 )) && pass "d-still.png: a still 32x20 picture, no controls" || fail "still: $(pv_s)"
# --- a .draw -----------------------------------------------------------------------------------
pick b-project.draw
(( PV_PW > 0 && PV_PH > 0 )) && pass "b-project.draw: its picture shows (${PV_PW}x$PV_PH)" || fail ".draw: $(pv_s)"
screenshot "browser-preview-draw"
assert_no_crash
rm -rf "$PV_DIR"
info "=== Browser: animated preview + .draw files: done ==="
