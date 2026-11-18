#!/bin/bash
# =============================================================================
# dock-row-charmap.sh — QA test: the character map in a top dock row widens its
# grid into the room the row gives it (Rick 2026-11-16: "allow it's character
# grid to extend to the right when i make room for it, snapping many cells"):
#   - alone in a top row it stretches across, and its cells per row are as many
#     whole cells as fit the slot (more than the side column's 16)
#   - every cell column fits inside the panel (cols * (cell + pad) <= width)
#   - a neighbour beside it takes room: fewer columns, still whole cells
#   - back in a side column: its Settings cells per row again
# Dump: CMAPC cols cellW pad panelW(units) inRow; P (panel rects)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt CHARMAP_VISIBLE=1 TOOLTIPS_DISABLED=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
row_of() { dk_p "$1" || return 1; dk_slot "$P_SLOT"; dk_col "$S_COL"; }
cmapc() { read -r _ CM_COLS CM_CW CM_PAD CM_PW CM_ROW <<< "$(grep -m1 '^CMAPC' "$DK_DUMP")"; }
fits() { (( CM_COLS * CM_CW + (CM_COLS - 1) * CM_PAD + 5 <= CM_PW )); }

info "=== Dock rows: the character map widens its grid ==="
dk_begin
cmapc; C0=$CM_COLS
info "side column: $CM_COLS cells a row (cell $CM_CW, pad $CM_PAD, panel $CM_PW, row $CM_ROW)"
dk_move charmap band-top
if row_of charmap && (( C_SIDE == 3 )); then pass "the character map in a top row (h $C_H)"; else fail "charmap not in a top row [$(dk_tree)]"; fi
cmapc; dk_p charmap; W1=$P_W; N1=$CM_COLS
info "in the row: ${P_W}px wide, $CM_COLS cells a row (panel $CM_PW units)"
(( CM_ROW == 1 && CM_COLS > C0 )) && pass "its grid widens: $C0 -> $CM_COLS cells a row" || fail "in the row: $CM_COLS cells a row (side column $C0, inRow $CM_ROW)"
fits && pass "whole cells: $CM_COLS x $(( CM_CW + CM_PAD )) fits $CM_PW" || fail "$CM_COLS cells of $CM_CW+$CM_PAD overrun the panel ($CM_PW)"
screenshot "dock-row-charmap"
dk_check "charmap in the row"
dk_seams "charmap in the row"
# a neighbour beside it: less room, fewer whole cells
dk_move toolbox right charmap
dk_expect_tree 'TOP\.[0-9]+: charmap \| toolbox' "the toolbox beside it"
cmapc; dk_p charmap
info "with the toolbox: ${P_W}px, $CM_COLS cells a row"
(( P_W < W1 && CM_COLS < N1 )) && pass "less room, fewer cells: $N1 -> $CM_COLS" || fail "with the toolbox: ${P_W}px ($W1 before), $CM_COLS cells ($N1 before)"
fits && pass "still whole cells" || fail "$CM_COLS cells overrun the panel ($CM_PW)"
dk_check "charmap + toolbox"
# back in a side column: the Settings count again
dk_move charmap edge-left
cmapc
(( CM_ROW == 0 && CM_COLS == C0 )) && pass "in a side column again: $CM_COLS cells a row" || fail "side column: $CM_COLS cells (want $C0), inRow $CM_ROW"
dk_check "charmap back at the side"
assert_window_exists
info "=== Dock rows: character map done ==="
