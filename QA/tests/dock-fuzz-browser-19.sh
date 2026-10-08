#!/bin/bash
# =============================================================================
# dock-fuzz-browser-19.sh — QA test: a seeded chain of 14 random moves with the
# Browser in the mix (its top / bottom band included) among docked panels and
# the Color Mixer - outcome + invariants after every move.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=60 COLOR_MIXER_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: fuzz browser 19 Test ==="
dk_begin
dk_check "start"
dk_fuzz 19 14 browser layers editbar drawer colormixer
screenshot "dock-fuzz-browser-19"
assert_window_exists
info "=== Dock: fuzz browser 19 Test PASSED ==="
