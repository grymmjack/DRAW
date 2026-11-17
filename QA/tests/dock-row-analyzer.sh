#!/bin/bash
# =============================================================================
# dock-row-analyzer.sh — QA test: the Pixel Art Analyzer with a top dock row
# (Rick 2026-11-16, screenshot: "when pixel art analyzer is on it shows borders
# of the docks" - the rows went to empty outlined boxes while it was open). Its
# frozen chrome is now the screen as shown with the canvas cut out, not
# SCRN.GUI& (which lacks the docked panels):
#   - the toolbox in a top row; the row's buttons snapped
#   - Help -> Pixel Art Analyzer (via the command palette)
#   - the row looks the same with it open (its buttons still drawn)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock rows: the Pixel Art Analyzer keeps the rows drawn ==="
dk_begin

colors() { convert "$1" -format %k info: 2>/dev/null; }

dk_move toolbox band-top
dk_p toolbox; dk_slot "$P_SLOT"; dk_col "$S_COL"
(( C_SIDE == 3 )) && pass "toolbox in a top row (y $C_Y h $C_H)" || fail "toolbox not in a top row [$(dk_tree)]"
RX=$C_X; RY=$C_Y; RW=$(( C_W < 300 ? C_W : 300 )); RH=$C_H
dk_park; dk_settle
snap_region "$RX" "$RY" "$RW" "$RH" "row-before"; BEFORE=$SNAP_RESULT
N0=$(colors "$BEFORE")
info "the row's left ${RW}px before: $N0 colours"

park_mouse; key question; wait_for 1.0 "Command palette"
Q="pixel art analyzer"
for (( qi = 0; qi < ${#Q}; qi++ )); do type_text "${Q:qi:1}"; done
wait_for 1.0 "typed"
key Return; wait_for 3.0 "the analyzer"
screenshot "dock-row-analyzer"
snap_region "$RX" "$RY" "$RW" "$RH" "row-during"; DURING=$SNAP_RESULT
N1=$(colors "$DURING")
info "with the analyzer open: $N1 colours"
(( N1 >= 4 && N1 * 2 >= N0 )) && pass "the row's buttons are still drawn ($N1 colours, $N0 before)" || fail "the row went flat with the analyzer open ($N0 -> $N1 colours)"
assert_regions_same "$BEFORE" "$DURING" "the row looks as it did with the analyzer open"

key Escape; wait_for 1.0 "analyzer closed"
assert_window_exists
info "=== Pixel Art Analyzer with rows done ==="
