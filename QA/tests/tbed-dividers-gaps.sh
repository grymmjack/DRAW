#!/bin/bash
# =============================================================================
# tbed-dividers-gaps.sh — QA test: Customize Toolbars sets each panel's dividers and
# gaps (GUI/TOOLBAR-EDITOR, GUI/BUTTON-LIST, GUI/TOOLBAR).
# Rick 2026-11-23: "dividers should be adjustable in the toolbar customizer. and gaps
# should show up with [x] show gaps [x] show dividers, etc. in that same dialog" -
# per toolbar, saved in the workspace beside COLUMNS=.
#   1. the edit bar starts at the default: DIVIDER AUTO (the theme's margin), no lines,
#      no gap outlines
#   2. DIVIDER + + + : 3 px more - the buttons after the first divider move down 3
#   3. [x] SHOW DIVIDERS draws a line in the divider's space
#   4. + GAP after the first button, then [x] SHOW GAPS outlines the empty cell
#   5. kept in workspace CURRENT: [EDIT_BAR] DIVIDER_SIZE= / SHOW_DIVIDERS= / SHOW_GAPS=
#   6. the toolbox: a divider + DIVIDER 4 moves the row after it down 4 px (x scale)
#   7. RESET puts a panel's dividers / gaps back to the default
# Dump: TBSTYLE panel size(-1 = AUTO) px showDividers showGaps; BTN / TBED / TBC
# (TBED_dump$); controls divdn divup showdiv showgap.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

st() { read -r _ _ S_SIZE S_PX S_DIV S_GAP <<< "$(grep -m1 "^TBSTYLE $1 " "$DK_DUMP")"; }
bt() { read -r _ _ _ B_KIND _ _ B_X B_Y B_W B_H <<< "$(awk -v p="$1" -v i="$2" '$1 == "BTN" && $2 == p && $3 == i' "$DK_DUMP")"; } # PANEL IDX
first_div() { awk -v p="$1" '$1 == "BTN" && $2 == p && $4 == 3 {print $3; exit}' "$DK_DUMP"; }
# the first drawn button after entry IDX of PANEL -> its index
next_btn() { awk -v p="$1" -v i="$2" '$1 == "BTN" && $2 == p && $3 > i && ($4 == 1 || $4 == 2) && $9 > 0 {print $3; exit}' "$DK_DUMP"; }

info "=== Customize Toolbars: dividers and gaps ==="
wait_for 1.0 "settle"
key Escape
dk_park; dk_settle
tb_open
tb_click tab2; tb_state
[[ "$TB_TAB" == "editbar" ]] && pass "the Edit Bar tab" || fail "tab 2: '$TB_TAB'"

# --- 1. defaults ---------------------------------------------------------------------------------
st editbar
[[ "$S_SIZE" == -1 && "$S_DIV" == 0 && "$S_GAP" == 0 ]] && pass "edit bar starts at AUTO ($S_PX px), no lines, no gap outlines" || fail "edit bar style: size '$S_SIZE' px '$S_PX' div '$S_DIV' gap '$S_GAP'"
PX0=$S_PX
D=$(first_div editbar); A=$(next_btn editbar "$D"); P=$(( D - 1 ))
bt editbar "$A"; AY0=$B_Y
info "first divider: entry $D; the button after it: entry $A (y $AY0)"

# --- 2. DIVIDER + + + --------------------------------------------------------------------------------
tb_click divup; tb_click divup; tb_click divup
st editbar; bt editbar "$A"
(( S_SIZE == PX0 + 3 )) && pass "DIVIDER + x3: $PX0 -> $S_SIZE px" || fail "divider size '$S_SIZE' (want $(( PX0 + 3 )))"
(( B_Y > AY0 )) && pass "the buttons after the divider moved down ($AY0 -> $B_Y)" || fail "entry $A still at y $B_Y (was $AY0)"

# --- 3. SHOW DIVIDERS ----------------------------------------------------------------------------------
bt editbar "$P"; PB=$(( B_Y + B_H )); bt editbar "$A"; AT=$B_Y; LX=$B_X; LW=$B_W
GAPH=$(( AT - PB )); (( GAPH < 2 )) && GAPH=2
dk_park; dk_settle
snap_region $(( LX - 2 )) "$PB" $(( LW + 4 )) "$GAPH" "div-off"; OFF=$SNAP_RESULT
tb_click showdiv; dk_park; dk_settle
st editbar
[[ "$S_DIV" == -1 ]] && pass "[x] SHOW DIVIDERS is on" || fail "show dividers '$S_DIV'"
snap_region $(( LX - 2 )) "$PB" $(( LW + 4 )) "$GAPH" "div-on"; ON=$SNAP_RESULT
assert_regions_differ "$OFF" "$ON" "a line shows in the divider's space (y $PB..$AT)"
screenshot "tbed-dividers-on"

# --- 4. a gap, SHOW GAPS ---------------------------------------------------------------------------------
bt editbar 1; GX0=$B_X; GY0=$B_Y; GW=$B_W; GH=$B_H
tb_ls_click 0
tb_click gap
dk_park; dk_settle
bt editbar 1
[[ "$B_KIND" == 4 ]] && pass "+ GAP put a gap after the first button" || fail "entry 1 is kind '$B_KIND' (want 4, a gap)"
snap_region "$GX0" "$GY0" "$GW" "$GH" "gap-off"; OFF=$SNAP_RESULT
tb_click showgap; dk_park; dk_settle
st editbar
[[ "$S_GAP" == -1 ]] && pass "[x] SHOW GAPS is on" || fail "show gaps '$S_GAP'"
snap_region "$GX0" "$GY0" "$GW" "$GH" "gap-on"; ON=$SNAP_RESULT
assert_regions_differ "$OFF" "$ON" "the gap's cell is outlined ($GX0,$GY0 ${GW}x$GH)"
screenshot "tbed-gaps-on"

# --- 5. saved -------------------------------------------------------------------------------------------
WSF=$(tb_ws_file)
sec() { tr -d '\r' < "$WSF" | awk -v s="[$1]" '$0 == s {on=1; next} /^\[/ {on=0} on'; } # (DRAW writes CRLF)
if [[ -n "$WSF" ]] && sec EDIT_BAR | grep -q "^DIVIDER_SIZE=$S_SIZE$" && sec EDIT_BAR | grep -q '^SHOW_DIVIDERS=TRUE$' && sec EDIT_BAR | grep -q '^SHOW_GAPS=TRUE$'; then
    pass "kept in $(basename "$WSF"): [EDIT_BAR] DIVIDER_SIZE=$S_SIZE SHOW_DIVIDERS=TRUE SHOW_GAPS=TRUE"
else
    fail "not saved: [EDIT_BAR] is [$(sec EDIT_BAR 2>/dev/null | tr '\n' ' ')] ($WSF)"
fi

# --- 6. the toolbox -------------------------------------------------------------------------------------
tb_click tab1; tb_state
[[ "$TB_TAB" == "toolbox" ]] && pass "the Toolbox tab" || fail "tab 1: '$TB_TAB'"
st toolbox
[[ "$S_SIZE" == -1 && "$S_PX" == 0 ]] && pass "toolbox starts at AUTO (0 px: a divider only ends the row)" || fail "toolbox style: size '$S_SIZE' px '$S_PX'"
tb_ls_click 1
tb_click div
dk_park; dk_settle
D=$(first_div toolbox); A=$(next_btn toolbox "$D")
[[ -n "$D" && -n "$A" ]] && pass "+ DIV put a divider in the toolbox (entry $D; next button $A)" || fail "no divider in the toolbox [$(tb_list toolbox)]"
bt toolbox "$A"; TY0=$B_Y
tb_click divup; tb_click divup; tb_click divup; tb_click divup
dk_park; dk_settle
st toolbox; bt toolbox "$A"
(( S_SIZE == 4 )) && pass "DIVIDER + x4: 4 px" || fail "toolbox divider size '$S_SIZE'"
(( B_Y >= TY0 + 4 )) && pass "the row after the divider moved down ($TY0 -> $B_Y)" || fail "toolbox entry $A at y $B_Y (was $TY0, want +4 x scale)"
bt toolbox $(( D - 1 )); TPB=$(( B_Y + B_H )); bt toolbox "$A"; TAT=$B_Y; TX=$B_X; TW=$(( B_W * 2 ))
snap_region "$TX" "$TPB" "$TW" $(( TAT - TPB )) "tbdiv-off"; OFF=$SNAP_RESULT
tb_click showdiv; dk_park; dk_settle
snap_region "$TX" "$TPB" "$TW" $(( TAT - TPB )) "tbdiv-on"; ON=$SNAP_RESULT
assert_regions_differ "$OFF" "$ON" "SHOW DIVIDERS: a line shows in the toolbox's divider space (y $TPB..$TAT; theme ICON_BAR_DIVIDER_FG)"
screenshot "tbed-toolbox-divider"

# --- 7. RESET -------------------------------------------------------------------------------------------
tb_click reset; dk_park; dk_settle
st toolbox
[[ "$S_SIZE" == -1 && "$S_DIV" == 0 && "$S_GAP" == 0 ]] && pass "RESET: the toolbox's dividers / gaps back to the default" || fail "after RESET: size '$S_SIZE' div '$S_DIV' gap '$S_GAP'"
st editbar
[[ "$S_DIV" == -1 ]] && pass "... the edit bar keeps its own (per toolbar)" || fail "edit bar lost its setting: div '$S_DIV'"
tb_click done; sleep 0.5; dk_settle
dk_park
assert_no_crash
