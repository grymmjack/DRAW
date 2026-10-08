#!/bin/bash
# =============================================================================
# dock-fuzz-long-101.sh — QA test: a long seeded chain (24 random moves) over
# every docked panel plus the Color Mixer and the Preview - outcome + invariants
# after every move (QA/dock-lib.sh dk_fuzz / dk_check).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_MIXER_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: long fuzz 101 Test ==="
dk_begin
dk_check "start"
dk_fuzz 101 24 toolbox organizer drawer layers editbar advbar colormixer preview
screenshot "dock-fuzz-long-101"
assert_window_exists
info "=== Dock: long fuzz 101 Test PASSED ==="
