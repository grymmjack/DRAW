#!/bin/bash
# =============================================================================
# organizer-grid-adjust.sh — QA test: R-click the organizer's grid button, then
# drag one cell on the canvas to set the grid (Deluxe Paint style; BUGS.md
# 2026-11-15)
#
#  1. R-click the grid button: the grid shows and DRAW waits for a drag.
#  2. A drag from canvas (20,12) to (35,23) is a 16x12 cell: the grid becomes
#     16x12, its origin 20 mod 16, 12 mod 12 = (4,0). No tool acted (the
#     history did not move), and the mode ends on the release.
#  3. R-click again, drag part way, Esc: the grid is back as it was.
# It used to do nothing on a R-click (the drag painted with the brush).
#
# Dump: GRID w h originX originY show adjusting | HIST cur count |
#       ORGW idx x y w h | VIEW zoom offX offY tool | CVORG x y
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Organizer grid button: R-click, drag a cell ==="
GA_DIR="$(mktemp -d /tmp/draw-qa-gridadj-XXXXXX)"
magick -size 320x200 xc:none "PNG32:$GA_DIR/blank.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$GA_DIR/blank.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash
dk_begin
read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
sx() { echo $(( OX + $1 * Z / 100 + Z / 200 )); }   # the middle of canvas pixel $1
sy() { echo $(( OY + $1 * Z / 100 + Z / 200 )); }
grid() { dk_settle; read -r _ G_W G_H G_X G_Y G_SHOW G_ADJ <<< "$(grep -m1 '^GRID ' "$DK_DUMP")"; }
hist() { read -r _ H_CUR H_CNT <<< "$(grep -m1 '^HIST ' "$DK_DUMP")"; }
read -r GBX GBY <<< "$(awk '$1=="ORGW" && $2==8 {print $3+int($5/2)" "$4+int($6/2); exit}' "$DK_DUMP")"
[[ -n "$GBY" ]] || fail "no ORGW 8 (grid button) in the dump"
key b; wait_for 0.3 "brush"
grid; hist; W0=$G_W; H0=$G_H; X0=$G_X; Y0=$G_Y; S0=$G_SHOW; C0=$H_CNT
info "grid before: ${W0}x$H0 at $X0,$Y0 show $S0, history $C0"

# -- 1 + 2: R-click, drag a 16x12 cell --
right_click "$GBX" "$GBY"; wait_for 0.4 "grid adjust"
dk_park; grid
(( G_ADJ == 1 )) && pass "R-click on the grid button starts the visual adjust" || fail "no adjust mode after the R-click (adjusting $G_ADJ)"
(( G_SHOW == 1 )) && pass "the grid is shown to adjust it" || fail "grid not shown (show $G_SHOW)"
mouse_down "$(sx 20)" "$(sy 12)"; sleep 0.1
hover "$(sx 28)" "$(sy 18)"; sleep 0.1; hover "$(sx 35)" "$(sy 23)"; sleep 0.3
grid; LIVE_W=$G_W
screenshot "grid-adjust-dragging"
mouse_up; wait_for 0.4 "release"
dk_park; grid; hist
info "grid after: ${G_W}x$G_H at $G_X,$G_Y adjusting $G_ADJ"
(( LIVE_W == 16 )) && pass "the grid follows the drag live (width $LIVE_W)" || fail "width while dragging $LIVE_W (want 16)"
(( G_W == 16 && G_H == 12 )) && pass "the dragged cell set the grid to 16x12" || fail "grid ${G_W}x$G_H after the drag (want 16x12)"
(( G_X == 4 && G_Y == 0 )) && pass "the cell's corner set the origin (4,0)" || fail "origin $G_X,$G_Y (want 4,0)"
(( G_ADJ == 0 )) && pass "the release ends the adjust" || fail "still adjusting after the release"
(( H_CNT == C0 )) && pass "no tool painted during the adjust (history $C0 -> $H_CNT)" || fail "the drag painted (history $C0 -> $H_CNT)"
screenshot "grid-adjust-done"

# -- 3: R-click, drag part way, Esc --
right_click "$GBX" "$GBY"; wait_for 0.4 "grid adjust again"
mouse_down "$(sx 40)" "$(sy 40)"; sleep 0.1; hover "$(sx 50)" "$(sy 47)"; sleep 0.3
key Escape; sleep 0.2; mouse_up; wait_for 0.4 "esc"
dk_park; grid
(( G_W == 16 && G_H == 12 && G_X == 4 && G_Y == 0 && G_ADJ == 0 )) && pass "Esc puts the grid back (16x12 at 4,0)" || fail "after Esc: ${G_W}x$G_H at $G_X,$G_Y adjusting $G_ADJ"
assert_no_crash
rm -rf "$GA_DIR"
