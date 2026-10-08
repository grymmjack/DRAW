#!/bin/bash
# =============================================================================
# dock-combine-advbar.sh — QA test (one file per panel, same pattern): the
# advbar combined with every other docked panel. For each one it is stacked
# above it, below it, made a tab of its slot, and pulled back out by its tab
# to the opposite screen edge - dk_check (QA/dock-lib.sh) after every move.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: combine the advbar with every panel Test ==="
dk_begin
dk_check "start"
for other in toolbox organizer drawer layers editbar ; do
    dk_move advbar above $other && dk_expect_stacked advbar $other
    dk_check "advbar above $other"
    dk_move advbar below $other && dk_expect_stacked $other advbar
    dk_check "advbar below $other"
    dk_move advbar tab $other && dk_expect_tabs $other advbar
    dk_check "advbar tab of $other"
    # out again by its tab, to the edge across from where it is
    if [[ "$(dk_side_of advbar)" == 1 ]]; then dk_move advbar edge-right; else dk_move advbar edge-left; fi
    dk_expect_docked advbar
    dk_check "advbar out of $other's slot by its tab"
done
screenshot "dock-combine-advbar"
assert_window_exists
info "=== Dock: combine the advbar with every panel Test PASSED ==="
