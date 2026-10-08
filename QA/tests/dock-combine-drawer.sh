#!/bin/bash
# =============================================================================
# dock-combine-drawer.sh — QA test (one file per panel, same pattern): the
# drawer combined with every other docked panel. For each one it is stacked
# above it, below it, made a tab of its slot, and pulled back out by its tab
# to the opposite screen edge - dk_check (QA/dock-lib.sh) after every move.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: combine the drawer with every panel Test ==="
dk_begin
dk_check "start"
for other in toolbox organizer layers editbar advbar ; do
    dk_move drawer above $other && dk_expect_stacked drawer $other
    dk_check "drawer above $other"
    dk_move drawer below $other && dk_expect_stacked $other drawer
    dk_check "drawer below $other"
    dk_move drawer tab $other && dk_expect_tabs $other drawer
    dk_check "drawer tab of $other"
    # out again by its tab, to the edge across from where it is
    if [[ "$(dk_side_of drawer)" == 1 ]]; then dk_move drawer edge-right; else dk_move drawer edge-left; fi
    dk_expect_docked drawer
    dk_check "drawer out of $other's slot by its tab"
done
screenshot "dock-combine-drawer"
assert_window_exists
info "=== Dock: combine the drawer with every panel Test PASSED ==="
