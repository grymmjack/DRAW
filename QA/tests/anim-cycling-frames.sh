#!/bin/bash
# =============================================================================
# anim-cycling-frames.sh — QA test: color cycling with animation frames
# (BUGS.md 2026-11-15, ANIMATION: "drawing not present while cycling")
#
# Rick's steps: christmas.draw, Shift+Tab (cycling), Num + (a 2nd frame), draw
# on frame 2, play. Found: the default FG there is white, palette index 66 -
# the FIRST color of the stars' twinkle range (66-105: white + 39 sky tones).
# Pixels drawn with it ARE cycled, like the stars, so they show sky most of the
# time. Cycling itself runs on every frame. This test pins:
#  1. pressing on the canvas with an FG in a cycle range while cycling runs
#     says so in the status bar ("FG cycles"), once;
#  2. a drawing on frame 2 in a color outside every range is on screen with
#     cycling on: stepping to frame 2 shows it, frame 1 does not have it;
#  3. while playing with cycling on, frame 2 comes round with the drawing;
#  4. cycling runs on frame 2 too (the pane changes over time while still).
# Runs in the Animate workspace (the lightbox: the current frame is the pane).
#
# Dump: ANIM active count current ... | ANIMLBP clipLB clipSheet {frame dx dy dw dh} |
#       PCYC running ranges fgIdx fgRange fgRGB ranges... | FLASH msg
# QA-OPTIONS: WORKSPACE=animate DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Animation frames + color cycling ==="
AC_DIR="$(mktemp -d /tmp/draw-qa-animcyc-XXXXXX)"
cp "$DRAW_ROOT/SAMPLES/COLOR CYCLING/christmas.draw" "$AC_DIR/christmas.draw"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$AC_DIR/christmas.draw"
draw_launch 15; wait_for 2.0 "loaded"
assert_no_crash
dk_begin
cur() { read -r _ _ _ A_CUR _ <<< "$(grep -m1 '^ANIM ' "$DK_DUMP")"; echo "${A_CUR:-0}"; }
pcyc() { read -r _ P_RUN P_N P_FG P_FGR P_RGB _ <<< "$(grep -m1 '^PCYC ' "$DK_DUMP")"; }
pane() { # -> PX PY PW PH of the current frame's picture
    local l; l=$(grep -m1 '^ANIMLBP ' "$DK_DUMP"); set -- $l; shift 3
    local c; c=$(cur)
    while (( $# >= 5 )); do if (( $1 == c )); then PX=$2; PY=$3; PW=$4; PH=$5; return 0; fi; shift 5; done; return 1
}
lx() { echo $(( PX + $1 * PW / 320 )); }
ly() { echo $(( PY + $1 * PH / 200 )); }
count_rgb() { # SNAP RRGGBB -> pixels of exactly that color
    magick "$1" -fill black +opaque "#$2" -fill white -opaque "#$2" -format '%[fx:int(mean*w*h+0.5)]' info: 2>/dev/null
}
snap_pane() { dk_park; snap_region "$PX" "$PY" "$PW" "$PH" "$1"; }

key shift+Tab; wait_for 0.5 "cycling on"
key KP_Add; wait_for 0.8 "add frame"
dk_settle; pcyc
(( P_RUN == 1 )) && pass "cycling runs ($P_N ranges)" || fail "cycling not running ($P_RUN)"
(( $(cur) == 2 )) && pass "Num + added frame 2 and made it current" || fail "current frame $(cur) after Num +"
pane || fail "no pane for the current frame"
info "frame 2 pane $PX,$PY ${PW}x$PH; FG $P_FG ($P_RGB) in range $P_FGR"

# -- 1. the FG-in-a-range hint --
key b; wait_for 0.3 brush
if (( P_FGR > 0 )); then
    click "$(lx 300)" "$(ly 20)"; wait_for 0.4 "a dab with the cycling FG"
    FL=$(grep -m1 '^FLASH ' "$DK_DUMP")
    [[ "$FL" == *"FG cycles"* ]] && pass "drawing with a cycling FG says so: ${FL#FLASH }" || fail "no 'FG cycles' notice (flash: '$FL')"
    key ctrl+z; wait_for 0.4 "undo the dab"
else
    info "the FG is not in a range here - hint not checked"
fi

# -- 2. a non-cycling color on frame 2 --
for pt in "160 172" "158 168" "150 120" "170 100"; do
    set -- $pt
    key i; wait_for 0.3 picker; click "$(lx $1)" "$(ly $2)"; wait_for 0.4 "pick $pt"; dk_settle; pcyc
    (( P_FGR == 0 && P_FG > 0 )) && break
done
(( P_FGR == 0 )) && pass "picked a color outside every range (index $P_FG, #$P_RGB)" || fail "no non-cycling color picked (FG $P_FG range $P_FGR)"
BROWN=$P_RGB
key b; wait_for 0.3 brush
key bracketright; key bracketright; key bracketright; key bracketright
for yy in 40 50 60; do drag "$(lx 30)" "$(ly $yy)" "$(lx 110)" "$(ly $yy)"; sleep 0.3; done
FL=$(grep -m1 '^FLASH ' "$DK_DUMP")
[[ "$FL" != *"FG cycles"* ]] && pass "no cycling notice for a non-cycling FG" || fail "the notice showed for a non-cycling FG"
snap_pane "f2"; N2=$(count_rgb "$SNAP_RESULT" "$BROWN")
screenshot "anim-cyc-frame2"
(( N2 > 200 )) && pass "frame 2's drawing shows with cycling on ($N2 px)" || fail "frame 2's drawing missing with cycling on ($N2 px of #$BROWN)"
key KP_4; wait_for 0.5 "frame 1"; dk_settle; pane
snap_pane "f1"; N1=$(count_rgb "$SNAP_RESULT" "$BROWN")
info "frame 1: $N1 px of the stroke color (the tree's own trunk shares it)"
(( N1 < N2 )) && pass "frame 1 has not got frame 2's drawing ($N1 < $N2)" || fail "frame 1 shows as much of the color as frame 2 ($N1 vs $N2)"

# -- 3. playing with cycling: frame 2 comes round with the drawing --
key KP_Enter; sleep 0.3
SEEN2=0; SEEN1=0
for i in 1 2 3 4 5 6 7 8 9 10; do
    pane; snap_pane "play-$i"; n=$(count_rgb "$SNAP_RESULT" "$BROWN")
    if (( n >= N2 - 20 )); then SEEN2=$(( SEEN2 + 1 )); else SEEN1=$(( SEEN1 + 1 )); fi
    sleep 0.15
done
key KP_Enter; wait_for 0.4 "stop"
info "playing: frame 2 with its drawing in $SEEN2 of 10 samples, without in $SEEN1"
(( SEEN2 > 0 )) && pass "frame 2's drawing shows while playing with cycling" || fail "frame 2's drawing never showed while playing"
(( SEEN1 > 0 )) && pass "frame 1 (without it) came round too" || info "every sample caught frame 2"
screenshot "anim-cyc-played"

# -- 4. cycling runs on frame 2 --
key KP_6; wait_for 0.5 "frame 2"; dk_settle; pane
(( $(cur) == 2 )) || key KP_5
dk_settle; pane
snap_pane "cyc-a"; CA="$SNAP_RESULT"; sleep 0.6; snap_pane "cyc-b"; CB="$SNAP_RESULT"
assert_regions_differ "$CA" "$CB" "frame 2 cycles (the pane changes while it stands still)"
assert_no_crash
rm -rf "$AC_DIR"
