#!/bin/bash
# =============================================================================
# dock-fuzz-11.sh — QA test: a seeded chain of 12 random panel moves
# (QA/dock-lib.sh dk_fuzz: edge / new column / above / below / tab / column
# bottom / float, between the toolbox, organizer, drawer, layers, edit bar and
# advanced bar). The seed makes it repeatable; every move checks what it should
# have done and the invariants (dk_check).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: fuzz 11 Test ==="
dk_begin
dk_check "start"
dk_fuzz 11 12 toolbox organizer drawer layers editbar advbar
screenshot "dock-fuzz-11"
assert_window_exists
info "=== Dock: fuzz 11 Test PASSED ==="
