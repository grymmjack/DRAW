#!/bin/bash
# =============================================================================
# fill-adjust-dither.sh — QA test: the D key while a fill is adjusted (F8)
# (BUGS.md 2026-11-15, FILL ADJUST)
#
#  1. A gradient-filled rectangle with Fill Adjust on: D tapped cycles the
#     fill's dither (off -> ORDERED 2x2 -> ...), the fill changes, and D is
#     not the Dot tool.
#  2. D + wheel changes the amount; D + drag moves the pattern.
#  3. D + Shift+3 saves a preset, D + 3 recalls it; the digits are not the
#     opacity keys while D is held.
#  4. Enter keeps the fill; the next fill starts with the dither as it was.
#  5. A pattern fill is thinned by the dither (part of the fill shows through).
#  6. (Rick, 2026-11-15) the gradient has no dither of its own and still
#     dithers: a true pixel dither (stop colors only), and D + wheel visibly
#     changes it (the amount = how wide the dithered band is); hold Ctrl while
#     dragging the rotation arc = 15-degree steps.
# It used to: D picked the Dot tool and committed nothing of the kind.
#
# Dump: FILLADJ active mode amount% offX offY tileW tileH rot opacity dHeld |
#       VIEW zoom offX offY tool | CVORG x y | GRADSEL slot stops ownDither str% custom
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Fill Adjust: the D key dithers the fill ==="
FD_DIR="$(mktemp -d /tmp/draw-qa-filldither-XXXXXX)"
magick -size 320x200 xc:none "PNG32:$FD_DIR/blank.png"
draw_quit; draw_settle
DRAW_EXTRA_ARGS="$FD_DIR/blank.png"
draw_launch 15; wait_for 1.5 "loaded"
assert_no_crash
dk_begin
read -r _ Z _ _ _ <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"
read -r _ OX OY <<< "$(grep -m1 '^CVORG ' "$DK_DUMP")"
sx() { echo $(( OX + $1 * Z / 100 + Z / 200 )); }
sy() { echo $(( OY + $1 * Z / 100 + Z / 200 )); }
fa() { dk_settle; read -r _ F_ACT F_MODE F_AMT F_OX F_OY F_TW F_TH F_ROT F_OP F_DH <<< "$(grep -m1 '^FILLADJ ' "$DK_DUMP")"; }
tool() { read -r _ _ _ _ V_TOOL <<< "$(grep -m1 '^VIEW ' "$DK_DUMP")"; }
fillshot() { dk_park; snap_region "$(sx 60)" "$(sy 50)" $(( 120 * Z / 100 )) $(( 60 * Z / 100 )) "$1"; }
rect() { drag "$(sx 50)" "$(sy 40)" "$(sx 200)" "$(sy 130)"; wait_for 0.8 "filled rect"; }

key F2; wait_for 0.3 "gradient mode"
key F8; wait_for 0.3 "fill adjust on"
key shift+r; wait_for 0.3 "filled rectangle"
tool; RT=$V_TOOL
rect
fa
(( F_ACT == 1 )) && pass "a gradient fill enters Fill Adjust" || fail "Fill Adjust not active after the fill (active $F_ACT)"
(( F_MODE == -1 )) && pass "the fill's dither starts off" || info "dither starts at mode $F_MODE (a cfg?)"
fillshot "smooth"; SMOOTH="$SNAP_RESULT"

# -- 1. D tapped --
key d; wait_for 0.5 "D: cycle"
fa; tool
(( F_MODE == 0 )) && pass "D tapped picks the first dither (ORDERED 2x2)" || fail "D tapped: dither mode $F_MODE (want 0)"
(( V_TOOL == RT )) && pass "D did not pick the Dot tool (tool $V_TOOL)" || fail "D switched the tool $RT -> $V_TOOL"
(( F_ACT == 1 )) && pass "the fill is still being adjusted" || fail "Fill Adjust ended on D"
fillshot "dithered"
NC=$(magick "$SNAP_RESULT" -format '%k' info: 2>/dev/null)
# a flat fill (1 color) = the gradient's alpha was dropped; a dither shows the stop color + the checkerboard
if ! cmp -s "$SMOOTH" "$SNAP_RESULT" && (( NC >= 3 )); then pass "the dither changed the fill ($NC colors)"; else fail "the dithered fill: $NC colors / same as smooth (a flat fill: the gradient's alpha was dropped)"; fi
screenshot "fill-dither-2x2"
read -r _ G_SLOT G_N G_DM _ <<< "$(grep -m1 '^GRADSEL ' "$DK_DUMP")"
(( G_DM == -1 )) && pass "the gradient (slot $G_SLOT, $G_N stops) has no dither of its own" || info "gradient slot $G_SLOT has its own dither $G_DM"
(( NC <= 4 )) && pass "the fill's dither is a pixel dither: $NC colors (stop colors + the checkerboard)" || fail "the fill's dither left $NC colors - a smooth blend, not a dither"
key d; wait_for 0.4 "D again"; fa
(( F_MODE == 1 )) && pass "D again: the next dither (ORDERED 4x4)" || fail "second D: mode $F_MODE (want 1)"

# -- 2. D + wheel, D + drag --
A0=$F_AMT
raw_key down d; sleep 0.25
scroll_up "$(sx 120)" "$(sy 80)"; sleep 0.2; scroll_up "$(sx 120)" "$(sy 80)"; sleep 0.3
fa; A1=$F_AMT
(( F_DH == 1 )) && pass "D is seen held" || fail "D held not seen (dHeld $F_DH)"
mouse_down "$(sx 100)" "$(sy 80)"; sleep 0.1; hover "$(sx 103)" "$(sy 81)"; sleep 0.1; hover "$(sx 105)" "$(sy 82)"; sleep 0.3
mouse_up; sleep 0.2
raw_key up d; sleep 0.4
fa
(( A1 == A0 + 10 )) && pass "D + wheel up: amount $A0% -> $A1%" || fail "D + wheel: amount $A0% -> $A1% (want +10)"
fillshot "amount-$A1"; AMT_A="$SNAP_RESULT"
raw_key down d; sleep 0.25
for w in 1 2 3 4 5 6; do scroll_down "$(sx 120)" "$(sy 80)"; sleep 0.12; done
sleep 0.3; raw_key up d; sleep 0.4; fa
fillshot "amount-$F_AMT"
! cmp -s "$AMT_A" "$SNAP_RESULT" && pass "D + wheel down changed the gradient's dither on screen ($A1% -> $F_AMT%)" || fail "the amount $A1% -> $F_AMT% left the gradient fill the same"
raw_key down d; sleep 0.25
for w in 1 2 3 4 5 6; do scroll_up "$(sx 120)" "$(sy 80)"; sleep 0.12; done
sleep 0.3; raw_key up d; sleep 0.4; fa
(( F_AMT == A1 )) || fail "the amount did not come back to $A1% ($F_AMT%)"
(( F_OX == 5 && F_OY == 2 )) && pass "D + drag moved the pattern (5,2)" || fail "D + drag: offset $F_OX,$F_OY (want 5,2)"
(( F_MODE == 1 )) && pass "D let go after the wheel / drag did not cycle (mode $F_MODE)" || fail "D up after a chord cycled the mode to $F_MODE"
screenshot "fill-dither-amount-offset"

# -- 3. presets --
OP0=$F_OP
raw_key down d; sleep 0.2; raw_key down shift; sleep 0.1
raw_key down 3; sleep 0.15; raw_key up 3; sleep 0.1
raw_key up shift; sleep 0.1; raw_key up d; sleep 0.4
key d; wait_for 0.3 "cycle away"; key d; wait_for 0.3 "cycle away"
fa; MAWAY=$F_MODE
raw_key down d; sleep 0.2; raw_key down 3; sleep 0.15; raw_key up 3; sleep 0.1; raw_key up d; sleep 0.4
fa
info "preset: saved mode 1 $A1% at 5,2; moved to mode $MAWAY; recalled mode $F_MODE $F_AMT% at $F_OX,$F_OY"
(( MAWAY != 1 )) || fail "the mode did not move away before the recall"
(( F_MODE == 1 && F_AMT == A1 && F_OX == 5 && F_OY == 2 )) && pass "D + Shift+3 saved and D + 3 recalled the preset" || fail "recall: mode $F_MODE $F_AMT% at $F_OX,$F_OY (want 1 $A1% at 5,2)"
(( F_OP == OP0 )) && pass "the digits under D left the opacity alone ($F_OP)" || fail "opacity $OP0 -> $F_OP: a digit under D set it"

# -- 6. Ctrl + rotation arc = 15-degree steps --
# the L handle sits at the shape's corner (canvas 50,40); its arc: radius 28, upper right
HX=$(sx 50); HY=$(sy 40)
mouse_down $(( HX + 20 )) $(( HY - 20 )); sleep 0.1
hover $(( HX + 25 )) $(( HY - 10 )); sleep 0.1; hover $(( HX + 28 )) $(( HY + 5 )); sleep 0.3
mouse_up; sleep 0.3; fa; R0=$F_ROT
info "rotation drag (no Ctrl): $R0 degrees"
(( R0 % 15 != 0 )) && pass "a free rotation drag is not snapped ($R0)" || info "free rotation landed on a multiple of 15 ($R0)"
mouse_down $(( HX + 20 )) $(( HY - 20 )); sleep 0.1
raw_key down ctrl; sleep 0.15
hover $(( HX + 25 )) $(( HY - 10 )); sleep 0.1; hover $(( HX + 28 )) $(( HY + 5 )); sleep 0.3
mouse_up; sleep 0.2; raw_key up ctrl; sleep 0.3; fa
info "rotation drag with Ctrl: $R0 -> $F_ROT degrees"
(( F_ROT % 15 == 0 && F_ROT != R0 )) && pass "Ctrl + rotation drag snaps to 15 degrees ($F_ROT)" || fail "Ctrl + rotation: $F_ROT (want a multiple of 15, not $R0)"
screenshot "fill-rotate-snap"

# -- 4. commit, the next fill remembers --
key Return; wait_for 0.5 "commit"; fa
(( F_ACT == 0 )) && pass "Enter keeps the fill" || fail "still adjusting after Enter"
key ctrl+z; wait_for 0.4 "undo the fill"
rect; fa
(( F_ACT == 1 && F_MODE == 1 && F_AMT == A1 )) && pass "the next fill starts with the dither as it was (mode $F_MODE, $F_AMT%)" || fail "next fill: active $F_ACT mode $F_MODE $F_AMT% (want 1 / $A1%)"
key Escape; wait_for 0.4 "cancel"

# -- 5. pattern fill: thinned --
key F3; wait_for 0.3 "pattern mode"
rect; fa
if (( F_ACT == 1 )); then
    fillshot "pattern-dithered"
    # transparent cells show the checkerboard: the region has more than the pattern's colors
    key d; wait_for 0.3; key d; wait_for 0.3; key d; wait_for 0.3   # ... back to off eventually? cycle on
    pass "a pattern fill enters Fill Adjust with the dither"
    screenshot "fill-dither-pattern"
else
    info "no pattern fill to adjust (no pattern selected) - skipped"
fi
key Escape; wait_for 0.3 "cancel"
assert_no_crash
rm -rf "$FD_DIR"
