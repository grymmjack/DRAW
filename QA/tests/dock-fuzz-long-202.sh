#!/bin/bash
# =============================================================================
# dock-fuzz-long-202.sh — QA test: a long seeded chain (24 random moves) over
# every docked panel plus the Color Mixer and the Preview - outcome + invariants
# after every move (QA/dock-lib.sh dk_fuzz / dk_check).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_MIXER_VISIBLE=1
# QA-TIMEOUT: 1200 (Windows: the thinkpad took ~745 s, every check passing; was cut at 600 s, 2026-11-22)
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: long fuzz 202 Test ==="
dk_begin
dk_check "start"
dk_fuzz 202 24 toolbox organizer drawer layers editbar advbar colormixer preview
screenshot "dock-fuzz-long-202"
assert_window_exists
info "=== Dock: long fuzz 202 Test PASSED ==="
