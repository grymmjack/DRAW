#!/bin/bash
# =============================================================================
# swatches-edge-resize.sh — QA test: the floating Swatches panel resizes from
# its left / right sides, its bottom and both bottom corners, not only the
# bottom-right grip (Rick, 2026-11-14), with the matching resize cursor over
# each. Left / bottom-left keep the right side still; right / bottom keep the
# left side still. The grip is the three dots of every other floating window.
#
# Dump: SWATW dispX dispY dispW dispH panelW panelH docked edge (viewport px);
# CURSOR id flip (7 corner, 8 horizontal, 9 vertical; flip 2 = SW, 3 = SE).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-ramps.gpl
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

sw_win() { read -r _ W_X W_Y W_W W_H W_PW W_PH W_DOCK W_EDGE <<< "$(grep '^SWATW ' "$DK_DUMP")"; }
cursor() { read -r _ CUR_ID CUR_FLIP <<< "$(grep '^CURSOR ' "$DK_DUMP")"; }
# hover the middle, then the point (a real move onto it), then read the cursor
hover_cur() { hover $(( W_X + W_W / 2 )) $(( W_Y + W_H / 2 )); sleep 0.2; hover "$1" "$2"; sleep 0.4; dk_settle; cursor; }
near() { local d=$(( $1 - $2 )); (( d < 0 )) && d=$(( -d )); (( d <= ${3:-3} )); }
expect_cur() { # LABEL ID FLIP
    if [[ "$CUR_ID" == "$2" && ( -z "${3:-}" || "$CUR_FLIP" == "${3:-}" ) ]]; then pass "$1: cursor $CUR_ID/$CUR_FLIP"
    else fail "$1: cursor '$CUR_ID/$CUR_FLIP', want '$2/${3:-any}'"; fi
}

info "=== Swatches: resize from the sides and bottom ==="
dk_begin
sw_win
if [[ -z "$W_X" ]]; then fail "no SWATW line in the dump"; fi
if [[ "$W_DOCK" == 0 ]]; then pass "Swatches floats ($W_X,$W_Y ${W_W}x${W_H})"; else fail "Swatches is docked"; fi

# the middle of the grid: no resize cursor
hover_cur $(( W_X + W_W / 2 )) $(( W_Y + W_H / 2 ))
if [[ "$CUR_ID" != 7 && "$CUR_ID" != 8 && "$CUR_ID" != 9 ]]; then pass "no resize cursor inside ($CUR_ID)"; else fail "resize cursor inside the grid ($CUR_ID)"; fi

# LEFT edge: grow 40px to the left, right side still
sw_win; R0=$(( W_X + W_W )); W0=$W_W; H0=$W_H
X=$W_X; Y=$(( W_Y + W_H / 2 ))
hover_cur "$X" "$Y"; expect_cur "left edge" 8
dk_drag "$X" "$Y" $(( X - 40 )) "$Y" 6; dk_park; dk_settle; sw_win
near $(( W_W - W0 )) 40 && pass "left: wider by ~40 ($W0 -> $W_W)" || fail "left: width $W0 -> $W_W, want +40"
near $(( W_X + W_W )) "$R0" 2 && pass "left: right side still ($R0)" || fail "left: right side moved $R0 -> $(( W_X + W_W ))"
near "$W_H" "$H0" 1 && pass "left: height unchanged" || fail "left: height $H0 -> $W_H"

# RIGHT edge: shrink 30px, left side still
sw_win; L0=$W_X; W0=$W_W; H0=$W_H
X=$(( W_X + W_W - 1 )); Y=$(( W_Y + W_H / 2 ))
hover_cur "$X" "$Y"; expect_cur "right edge" 8
dk_drag "$X" "$Y" $(( X - 30 )) "$Y" 6; dk_park; dk_settle; sw_win
near $(( W0 - W_W )) 30 && pass "right: narrower by ~30 ($W0 -> $W_W)" || fail "right: width $W0 -> $W_W, want -30"
near "$W_X" "$L0" 1 && pass "right: left side still" || fail "right: left side moved $L0 -> $W_X"

# BOTTOM edge: grow 30px down, width unchanged
sw_win; W0=$W_W; H0=$W_H; T0=$W_Y
X=$(( W_X + W_W / 2 )); Y=$(( W_Y + W_H - 1 ))
hover_cur "$X" "$Y"; expect_cur "bottom edge" 9
dk_drag "$X" "$Y" "$X" $(( Y + 30 )) 6; dk_park; dk_settle; sw_win
near $(( W_H - H0 )) 30 && pass "bottom: taller by ~30 ($H0 -> $W_H)" || fail "bottom: height $H0 -> $W_H, want +30"
near "$W_W" "$W0" 1 && pass "bottom: width unchanged" || fail "bottom: width $W0 -> $W_W"
near "$W_Y" "$T0" 1 && pass "bottom: top still" || fail "bottom: top moved $T0 -> $W_Y"

# BOTTOM-LEFT corner: grow 20 left and 20 down, right side still
sw_win; R0=$(( W_X + W_W )); W0=$W_W; H0=$W_H
X=$W_X; Y=$(( W_Y + W_H - 1 ))
hover_cur "$X" "$Y"; expect_cur "bottom-left corner" 7 2
dk_drag "$X" "$Y" $(( X - 20 )) $(( Y + 20 )) 6; dk_park; dk_settle; sw_win
near $(( W_W - W0 )) 20 && near $(( W_H - H0 )) 20 && pass "bottom-left: both grew (${W0}x$H0 -> ${W_W}x$W_H)" || fail "bottom-left: ${W0}x$H0 -> ${W_W}x$W_H, want +20 each"
near $(( W_X + W_W )) "$R0" 2 && pass "bottom-left: right side still" || fail "bottom-left: right side moved $R0 -> $(( W_X + W_W ))"

# BOTTOM-RIGHT grip: shrink 25 each way
sw_win; W0=$W_W; H0=$W_H; L0=$W_X
X=$(( W_X + W_W - 2 )); Y=$(( W_Y + W_H - 2 ))
hover_cur "$X" "$Y"; expect_cur "bottom-right grip" 7 3
dk_drag "$X" "$Y" $(( X - 25 )) $(( Y - 25 )) 6; dk_park; dk_settle; sw_win
near $(( W0 - W_W )) 25 && near $(( H0 - W_H )) 25 && pass "grip: both shrank (${W0}x$H0 -> ${W_W}x$W_H)" || fail "grip: ${W0}x$H0 -> ${W_W}x$W_H, want -25 each"
near "$W_X" "$L0" 1 && pass "grip: left side still" || fail "grip: left side moved $L0 -> $W_X"

screenshot "swatches-edge-resize"
assert_no_crash
info "=== Swatches: resize from the sides and bottom: done ==="
