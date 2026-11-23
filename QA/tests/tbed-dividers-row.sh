#!/bin/bash
# =============================================================================
# tbed-dividers-row.sh — QA test: SHOW DIVIDERS / SHOW GAPS on a bar docked in a top row
# (GUI/BUTTON-LIST BL_bar_draw_h% / BL_hbar_span%).
# Rick 2026-11-23: "i don't see a difference when i change to allow show dividers show
# gaps and so on in a docked toolbar at the top". A sideways bar is one even grid
# (Rick 2026-11-16: no breaks); with SHOW DIVIDERS on a divider ends the icon column,
# takes its DIVIDER size and draws a line; with SHOW GAPS on a gap takes an outlined cell.
#   1. the edit bar docked along the top lies sideways
#   2. SHOW DIVIDERS: the bar grows wider (the dividers' columns + room) and looks different
#   3. + GAP, SHOW GAPS: wider again
#   4. both off: back to the even grid's width
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

st() { read -r _ _ S_SIZE S_PX S_DIV S_GAP <<< "$(grep -m1 "^TBSTYLE $1 " "$DK_DUMP")"; }

info "=== SHOW DIVIDERS / SHOW GAPS on a bar in a top row ==="
wait_for 1.0 "settle"
key Escape
dk_park; dk_settle

# --- 1. the edit bar along the top ---------------------------------------------------------------
dk_move_expect editbar band-top
dk_p editbar; W0=$P_W; X0=$P_X; Y0=$P_Y; H0=$P_H
(( P_W > P_H )) && pass "the edit bar in a top row lies sideways (${P_W}x$P_H)" || fail "edit bar in a row: ${P_W}x$P_H"
snap_region "$X0" "$Y0" "$W0" "$H0" "row-plain"; PLAIN=$SNAP_RESULT

# --- 2. SHOW DIVIDERS ------------------------------------------------------------------------------
tb_open
tb_click tab2
tb_click showdiv
tb_click done; sleep 0.5; dk_park; dk_settle
st editbar
[[ "$S_DIV" == -1 ]] && pass "SHOW DIVIDERS on" || fail "show dividers '$S_DIV'"
dk_p editbar; W1=$P_W
(( W1 > W0 )) && pass "the row bar grows for its dividers ($W0 -> $W1 px)" || fail "row bar width $W0 -> $W1 (dividers take no room?)"
snap_region "$X0" "$Y0" "$W0" "$H0" "row-divs"; DIVS=$SNAP_RESULT
assert_regions_differ "$PLAIN" "$DIVS" "the row bar shows its dividers"
screenshot "tbed-row-dividers"

# --- 3. a gap + SHOW GAPS --------------------------------------------------------------------------
tb_open
tb_click tab2
tb_ls_click 0
tb_click gap
tb_click showgap
tb_click done; sleep 0.5; dk_park; dk_settle
st editbar
[[ "$S_GAP" == -1 ]] && pass "SHOW GAPS on" || fail "show gaps '$S_GAP'"
dk_p editbar; W2=$P_W
(( W2 >= W1 )) && pass "the gap takes a cell ($W1 -> $W2 px)" || fail "row bar width $W1 -> $W2 after a shown gap"
screenshot "tbed-row-gaps"

# --- 4. both off: the even grid again -----------------------------------------------------------------
tb_open
tb_click tab2
tb_click showdiv
tb_click showgap
tb_click done; sleep 0.5; dk_park; dk_settle
dk_p editbar; W3=$P_W
(( W3 == W0 )) && pass "both off: the even grid's width again ($W3 px)" || fail "row bar width $W3 (want $W0)"
dk_park
assert_no_crash
