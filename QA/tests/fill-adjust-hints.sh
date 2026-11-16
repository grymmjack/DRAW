#!/bin/bash
# =============================================================================
# fill-adjust-hints.sh — QA test: Fill Adjust's hints sit around the box (Rick,
# 2026-11-15: "the text across the top is a bit much ... running off the screen")
#
# The state above, the keys left and right, Enter / Esc below; each side goes
# inside the box when there is no room, and all stay in the canvas view (not
# under the docks). Screenshots: a box, D held (the dither keys), a fill as big
# as the canvas. Enter keeps the fill, Esc drops it.
# =============================================================================
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
source "$DRAW_ROOT/QA/dock-lib.sh"
FD_DIR="$(mktemp -d /tmp/draw-qa-fah-XXXXXX)"
magick -size 320x200 xc:none "PNG32:$FD_DIR/blank.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$FD_DIR/blank.png"
draw_launch 15; wait_for 1.5 "loaded"
dk_begin
read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
sx() { echo $(( OX + $1 * Z / 100 + Z / 200 )); }
sy() { echo $(( OY + $1 * Z / 100 + Z / 200 )); }
fa() { dk_settle; read -r _ F_ACT F_MODE _ <<< "$(grep -m1 '^FILLADJ ' "$DK_DUMP")"; }
key F2; sleep 0.3; key F8; sleep 0.3; key shift+r; sleep 0.3
drag "$(sx 80)" "$(sy 50)" "$(sx 220)" "$(sy 140)"; sleep 0.8
key d; sleep 0.4; dk_park; sleep 0.3; screenshot "fah-box"
raw_key down d; sleep 0.6; screenshot "fah-dheld"; raw_key up d; sleep 0.3
fa; key Return; sleep 0.6; fa
(( F_ACT == 0 )) && pass "Enter keeps the fill" || fail "Enter: still active"
drag "$(sx 0)" "$(sy 0)" "$(sx 319)" "$(sy 199)"; sleep 0.8; dk_park; sleep 0.3
screenshot "fah-full"
key Escape; sleep 0.6; fa
(( F_ACT == 0 )) && pass "Esc drops the fill" || fail "Esc: still active"
rm -rf "$FD_DIR"
assert_no_crash
