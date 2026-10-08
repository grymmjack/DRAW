#!/bin/bash
# =============================================================================
# dock-combine-organizer.sh — QA test (one file per panel, same pattern): the
# organizer combined with every other docked panel. For each one it is stacked
# above it, below it, made a tab of its slot, and pulled back out by its tab
# to the opposite screen edge - dk_check (QA/dock-lib.sh) after every move.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: combine the organizer with every panel Test ==="
dk_begin
dk_check "start"
for other in toolbox drawer layers editbar advbar ; do
    dk_move organizer above $other && dk_expect_stacked organizer $other
    dk_check "organizer above $other"
    dk_move organizer below $other && dk_expect_stacked $other organizer
    dk_check "organizer below $other"
    dk_move organizer tab $other && dk_expect_tabs $other organizer
    dk_check "organizer tab of $other"
    # out again by its tab, to the edge across from where it is
    if [[ "$(dk_side_of organizer)" == 1 ]]; then dk_move organizer edge-right; else dk_move organizer edge-left; fi
    dk_expect_docked organizer
    dk_check "organizer out of $other's slot by its tab"
done
screenshot "dock-combine-organizer"
assert_window_exists
info "=== Dock: combine the organizer with every panel Test PASSED ==="
