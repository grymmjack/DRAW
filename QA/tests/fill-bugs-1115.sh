#!/bin/bash
# =============================================================================
# fill-bugs-1115.sh — QA test: the Flood Fill items from PLANS/BUGS.md
# (2026-11-15)
#
#  1. Shift+click (sample all visible layers merged) reads every layer where the
#     canvas shows it. A layer drawn into the apron has a bigger buffer, and the
#     merge stretched that buffer onto the canvas, so the fill followed a
#     shrunken, shifted copy of the art (a "previous mask") and crossed lines it
#     should have stopped at.
#  2. Hold W or G + click with the Fill tool = the all-layers fill (as hold F);
#     W tapped alone still picks the Magic Wand (on its release).
#
# Fixture: a 320x200 transparent PNG. A vertical line at canvas x = 60 on layer
# 1, moved 10px right with the Move tool (a Move promotes the layer into the
# apron: its buffer is the canvas plus the apron all round), then a new empty
# layer 2 to fill on. FG is white.
# Dump: VIEW zoom offX offY tool | CVORG x y | LAYER ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Flood fill: BUGS.md 2026-11-15 ==="
FB_DIR="$(mktemp -d /tmp/draw-qa-fill-XXXXXX)"
magick -size 320x200 xc:none "PNG32:$FB_DIR/blank.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$FB_DIR/blank.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash
dk_begin
read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
sx() { echo $(( OX + $1 * Z / 100 )); }  # canvas -> screen
sy() { echo $(( OY + $1 * Z / 100 )); }
tool() { read -r _ _ _ _ V_TOOL <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; }
white_at() { # canvas X Y -> 0 when the 4x4 screen box there is white
    snap_region $(( $(sx "$1") - 2 )) $(( $(sy "$2") - 2 )) 4 4 "px"
    magick "$SNAP_RESULT" -colorspace HSL -channel B -separate -format '%[fx:minima]' info: 2>/dev/null | awk '{exit !($1 > 0.95)}'
}
info "zoom $Z%, canvas at $OX,$OY"

# -- the line on layer 1, top to bottom --
key l; wait_for 0.3 "line tool"
key grave; wait_for 0.1 "pointer"
drag "$(sx 60)" "$(sy 0)" "$(sx 60)" "$(sy 199)"; wait_for 0.5 "line"
snap_region "$(sx 60)" "$(sy 100)" 2 2 "line"
magick "$SNAP_RESULT" -colorspace HSL -channel B -separate -format '%[fx:minima]' info: 2>/dev/null | awk '{exit !($1 > 0.95)}' \
    && pass "the line is drawn at x 60" || fail "no line at x 60"
# a Move (the whole layer, 10 canvas px right) promotes layer 1 into the apron -
# as a Move / Alt-clone stamp does; the line is now at x 70
key v; wait_for 0.3 "move tool"
drag "$(sx 100)" "$(sy 100)" "$(sx 110)" "$(sy 100)"; wait_for 0.5 "move the layer"
key Return; wait_for 0.5 "apply"
dk_park
snap_region "$(sx 70)" "$(sy 100)" 2 2 "moved"
magick "$SNAP_RESULT" -colorspace HSL -channel B -separate -format '%[fx:minima]' info: 2>/dev/null | awk '{exit !($1 > 0.95)}' \
    && pass "the Move put the line at x 70" || fail "no line at x 70 after the Move"
key ctrl+shift+n; wait_for 0.5 "new layer"
dk_settle
(( $(grep -c '^LAYER ' "$DK_DUMP") == 2 )) && pass "layer 2 made" || fail "want 2 layers: $(grep -c '^LAYER ' "$DK_DUMP")"

# -- 1. Shift+click fill on layer 2 stops at layer 1's line --
key f; wait_for 0.3 "fill tool"
raw_key down shift; sleep 0.2
click "$(sx 30)" "$(sy 100)"; sleep 0.3
raw_key up shift; wait_for 0.5 "shift fill"
dk_park
screenshot "fill-merged"
white_at 30 100 && pass "Shift+click filled left of the line" || fail "Shift+click: nothing filled at (30,100)"
LEAK=0
for x in 76 100 130 200; do white_at $x 100 && LEAK=$(( LEAK + 1 )); done
(( LEAK == 0 )) && pass "the merged fill stopped at the line on layer 1 (a promoted layer)" || fail "the merged fill crossed the line: $LEAK of 4 spots right of it filled"

# -- 2. hold W + click: all-layers fill; W stays the Fill tool --
raw_key down w; sleep 0.25
click "$(sx 200)" "$(sy 100)"; sleep 0.3
raw_key up w; wait_for 0.5 "W fill"
dk_park; dk_settle; tool
white_at 200 100 && pass "hold W + click filled (all-layers fill)" || fail "hold W + click did not fill"
(( V_TOOL == 2 )) && pass "the Fill tool stays after W held + click" || fail "the tool changed to $V_TOOL after W + click"
screenshot "fill-hold-w"

# -- hold G + click (after an undo of the W fill) --
key ctrl+z; wait_for 0.5 "undo W fill"
white_at 200 100 && fail "the undo left the W fill" || pass "Ctrl+Z took the W fill back"
raw_key down g; sleep 0.25
click "$(sx 200)" "$(sy 100)"; sleep 0.3
raw_key up g; wait_for 0.5 "G fill"
dk_park; dk_settle; tool
white_at 200 100 && pass "hold G + click filled (all-layers fill)" || fail "hold G + click did not fill"
(( V_TOOL == 2 )) && pass "the Fill tool stays after G held + click" || fail "the tool changed to $V_TOOL after G + click"

# -- W tapped alone: the Magic Wand --
key w; wait_for 0.5 "tap W"; dk_settle; tool
(( V_TOOL == 5 )) && pass "a W tap with the Fill tool picks the Magic Wand (tool $V_TOOL)" || fail "a W tap left tool $V_TOOL (want the wand, 5)"
assert_no_crash
rm -rf "$FB_DIR"
