#!/bin/bash
# =============================================================================
# dock-combine-editbar.sh — QA test (one file per panel, same pattern): the
# editbar combined with every other docked panel. For each one it is stacked
# above it, below it, made a tab of its slot, and pulled back out by its tab
# to the opposite screen edge - dk_check (QA/dock-lib.sh) after every move.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: combine the editbar with every panel Test ==="
dk_begin
dk_check "start"
for other in toolbox organizer drawer layers advbar ; do
    dk_move editbar above $other && dk_expect_stacked editbar $other
    dk_check "editbar above $other"
    dk_move editbar below $other && dk_expect_stacked $other editbar
    dk_check "editbar below $other"
    dk_move editbar tab $other && dk_expect_tabs $other editbar
    dk_check "editbar tab of $other"
    # out again by its tab, to the edge across from where it is
    if [[ "$(dk_side_of editbar)" == 1 ]]; then dk_move editbar edge-right; else dk_move editbar edge-left; fi
    dk_expect_docked editbar
    dk_check "editbar out of $other's slot by its tab"
done
screenshot "dock-combine-editbar"
assert_window_exists
info "=== Dock: combine the editbar with every panel Test PASSED ==="
