#!/bin/bash
# =============================================================================
# dock-combine-layers.sh — QA test (one file per panel, same pattern): the
# layers combined with every other docked panel. For each one it is stacked
# above it, below it, made a tab of its slot, and pulled back out by its tab
# to the opposite screen edge - dk_check (QA/dock-lib.sh) after every move.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: combine the layers with every panel Test ==="
dk_begin
dk_check "start"
for other in toolbox organizer drawer editbar advbar ; do
    dk_move layers above $other && dk_expect_stacked layers $other
    dk_check "layers above $other"
    dk_move layers below $other && dk_expect_stacked $other layers
    dk_check "layers below $other"
    dk_move layers tab $other && dk_expect_tabs $other layers
    dk_check "layers tab of $other"
    # out again by its tab, to the edge across from where it is
    if [[ "$(dk_side_of layers)" == 1 ]]; then dk_move layers edge-right; else dk_move layers edge-left; fi
    dk_expect_docked layers
    dk_check "layers out of $other's slot by its tab"
done
screenshot "dock-combine-layers"
assert_window_exists
info "=== Dock: combine the layers with every panel Test PASSED ==="
