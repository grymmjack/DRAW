#!/bin/bash
# =============================================================================
# dock-combine-toolbox.sh — QA test (one file per panel, same pattern): the
# toolbox combined with every other docked panel. For each one it is stacked
# above it, below it, made a tab of its slot, and pulled back out by its tab
# to the opposite screen edge - dk_check (QA/dock-lib.sh) after every move.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: combine the toolbox with every panel Test ==="
dk_begin
dk_check "start"
for other in organizer drawer layers editbar advbar ; do
    dk_move toolbox above $other && dk_expect_stacked toolbox $other
    dk_check "toolbox above $other"
    dk_move toolbox below $other && dk_expect_stacked $other toolbox
    dk_check "toolbox below $other"
    dk_move toolbox tab $other && dk_expect_tabs $other toolbox
    dk_check "toolbox tab of $other"
    # out again by its tab, to the edge across from where it is
    if [[ "$(dk_side_of toolbox)" == 1 ]]; then dk_move toolbox edge-right; else dk_move toolbox edge-left; fi
    dk_expect_docked toolbox
    dk_check "toolbox out of $other's slot by its tab"
done
screenshot "dock-combine-toolbox"
assert_window_exists
info "=== Dock: combine the toolbox with every panel Test PASSED ==="
