#!/bin/bash
# =============================================================================
# move-tool-bugs-1115.sh — QA test: the Move tool items from PLANS/BUGS.md
# (2026-11-15)
#
#  1. Alt+drag (no selection) clones without leaving a selection behind: the
#     whole-layer lift's auto marquee used to turn into a canvas-sized user
#     selection, and Esc slid it back to the lift's origin with the apron
#  2. Alt+arrows stamp copies as they go; letting go of Alt drops the float,
#     so the next drag moves the layer WITH the stamps - the stale float used to
#     stay live and a drag moved it as a separate floating copy
#  3. Shift+arrows nudge NUDGE_N px with the Move tool - the canvas pan had
#     taken them over (the view moved, the art did not)
#
# Fixture: a 320x200 transparent PNG with a 20x20 red square in the middle.
# Dump: MOVE <active> <transforming> <symbol> <layer> <ox> <oy> <cx> <cy> |
#       MARQ <active> <user> <x> <y> <w> <h> <live> | VIEW <zoom> <offX> <offY> <tool>
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Move tool: BUGS.md 2026-11-15 ==="
MV_DIR="$(mktemp -d /tmp/draw-qa-move-XXXXXX)"
magick -size 320x200 xc:none -fill '#c00000' -draw 'rectangle 150,90 169,109' "PNG32:$MV_DIR/square.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$MV_DIR/square.png"
draw_launch 15; wait_for 1.5 "square loaded"
assert_no_crash
dk_begin
CX=$CANVAS_CX; CY=$CANVAS_CY
mv()   { read -r _ MV_ACT _ _ _ MV_OX MV_OY MV_CX MV_CY <<< "$(grep -m1 '^MOVE ' "$DK_DUMP")"; }
marq() { read -r _ MQ_ACT MQ_USER MQ_X MQ_Y MQ_W MQ_H MQ_LIVE <<< "$(grep -m1 '^MARQ ' "$DK_DUMP")"; }
view() { read -r _ V_ZOOM V_OX V_OY _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; }
red_at() { # X Y -> 0 when the 4x4 screen box there is red
    snap_region $(( $1 - 2 )) $(( $2 - 2 )) 4 4 "px"
    magick "$SNAP_RESULT" -colorspace HSL -channel G -separate -format '%[fx:minima]' info: 2>/dev/null | awk '{exit !($1 > 0.8)}'
}

# -- 1. Alt+drag clone: no selection made --
key v; wait_for 0.3 "move tool"
key grave; wait_for 0.1 "pointer"
# (Under Xvfb a press made while Alt is held never reaches DRAW; Alt pressed
# during the drag and held through the release is the same stamp - MOVE_stamp)
mouse_down $CX $CY; sleep 0.15
hover $(( CX + 30 )) $CY; hover $(( CX + 60 )) $CY; sleep 0.15
raw_key down alt; sleep 0.2
mouse_up; sleep 0.2
raw_key up alt; wait_for 0.6 "alt+drag clone"
dk_park; dk_settle; marq
red_at $CX $CY && red_at $(( CX + 60 )) $CY && pass "Alt+drag left the square and stamped a copy" || fail "no clone after Alt+drag"
(( MQ_LIVE == 0 )) && pass "Alt+drag clone: no selection made (live $MQ_LIVE, user $MQ_USER)" || fail "Alt+drag made a selection: MARQ $MQ_ACT $MQ_USER $MQ_X $MQ_Y $MQ_W $MQ_H live $MQ_LIVE"
screenshot "move-alt-clone"
key Escape; wait_for 0.5 "esc"; dk_settle; marq; mv
(( MQ_LIVE == 0 && MQ_ACT == 0 )) && pass "Esc after the clone: no selection, no marquee" || fail "after Esc: MARQ $MQ_ACT $MQ_USER $MQ_X $MQ_Y $MQ_W $MQ_H live $MQ_LIVE"
red_at $(( CX + 60 )) $CY && pass "Esc keeps the stamped copy" || fail "the stamp went away on Esc"

# -- 2. Alt+arrows stamp; letting go of Alt drops the float --
key v; wait_for 0.3 "move tool"; view; info "tool $(grep -m1 '^VIEW ' "$DK_DUMP")"
raw_key down alt; sleep 0.2
for i in 1 2 3; do raw_key down Down; sleep 0.15; raw_key up Down; sleep 0.25; done
dk_settle; mv; ACT_HELD=$MV_ACT
raw_key up alt; sleep 0.4
dk_park; dk_settle; mv
(( ACT_HELD != 0 && MV_ACT == 0 )) && pass "letting go of Alt after Alt+arrows ends the float" || fail "the float: while Alt held $ACT_HELD, after $MV_ACT (want live, then gone)"
screenshot "move-alt-arrows"
snap_region $(( CX - 18 )) $(( CY + 20 )) 36 5 "stamps"
magick "$SNAP_RESULT" -colorspace HSL -channel G -separate -format '%[fx:minima]' info: 2>/dev/null | awk '{exit !($1 > 0.8)}' \
    && pass "Alt+Down x3 stamped copies below the square" || fail "no stamps below the square after Alt+Down x3"
# a drag now moves the whole layer, the stamps with it: where the square and
# its three copies were (rows CY .. CY+6 screen px) nothing is left
drag $CX $CY $(( CX - 100 )) $(( CY - 60 )); wait_for 0.6 "drag the layer"
key Return; wait_for 0.4 "apply"; dk_park; dk_settle
LEFT=0
for dy in 0 4 8 12 16 20 24; do red_at $CX $(( CY + dy )) && LEFT=$(( LEFT + 1 )); done
screenshot "move-after-drag"
(( LEFT == 0 )) && pass "the drag moved the layer with its stamps (no floating copy left behind)" || fail "$LEFT red spots left where the stamps were: a separate floating copy"
key v; wait_for 0.3 "move tool"

# -- 3. Shift+arrows nudge, the view stays --
view; OX0=$V_OX; OY0=$V_OY
key Right; wait_for 0.4 "nudge 1"; dk_settle; mv; C0=$MV_CX
key shift+Right; wait_for 0.4 "nudge 10"; dk_settle; mv; view
(( V_OX == OX0 && V_OY == OY0 )) && pass "Shift+Right with the Move tool does not pan the view" || fail "the view panned: $OX0,$OY0 -> $V_OX,$V_OY"
(( MV_CX - C0 == 10 )) && pass "Shift+Right nudged the layer 10px ($C0 -> $MV_CX)" || fail "Shift+Right nudge: x $C0 -> $MV_CX (want +10)"
key Escape; wait_for 0.4 "done"

assert_no_crash
rm -rf "$MV_DIR"
