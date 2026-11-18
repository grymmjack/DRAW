#!/bin/bash
# =============================================================================
# dock-browser-wide.sh — QA test: the Browser docked in a side column widens
# past the old 600 px cap (Rick 2026-11-16: "when docked to left right the
# browser should allow more resizing it's width - it does not") - up to the
# window less a strip for the canvas (DOCK_panel_max_w%: SCRN.w - 200).
# Drag its column's inner edge far out: the column follows past 600 px, and
# stops short of the whole window.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 TOOLTIPS_DISABLED=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: the Browser column widens ==="
dk_begin
dk_move browser edge-left
dk_p browser; dk_slot "$P_SLOT"; dk_col "$S_COL"
(( C_SIDE == 1 )) && pass "the Browser in a left column (${C_W}px)" || fail "the Browser is not in a left column [$(dk_tree)]"
W0=$C_W; EX=$(( C_X + C_W )); EY=$(( C_Y + C_H / 2 ))
dk_drag "$EX" "$EY" $(( EX + 700 )) "$EY" 8; dk_park; dk_settle
dk_p browser; dk_slot "$P_SLOT"; dk_col "$S_COL"
info "column $W0 -> ${C_W}px (dragged its edge from $EX to $(( EX + 700 )))"
(( C_W > 620 )) && pass "the Browser column widens past 600: ${C_W}px" || fail "the Browser column stops at ${C_W}px (was $W0)"
(( C_X + C_W < 958 - 150 )) && pass "the canvas keeps a strip (column ends at $(( C_X + C_W )))" || fail "the column reaches $(( C_X + C_W )) of the window"
screenshot "dock-browser-wide"
dk_check "the wide Browser column"
assert_window_exists
info "=== Dock: Browser column done ==="
