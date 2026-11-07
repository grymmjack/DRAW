#!/bin/bash
# =============================================================================
# dock-seams-band.sh — QA test: the Browser's band (top / bottom of the canvas
# area) has one border line on its canvas side, and its ends do not put a
# second line beside the columns' seams. Rick, 2026-11-07: "make sure that all
# docks are consistent and have the correct borders between them and the
# canvas and them and other docks... in any configuration".
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=60 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock seams (Browser band) ==="
dk_begin
dk_move_expect browser band-top
dk_seams "the Browser in its top band"
dk_move_expect browser band-bottom
dk_seams "the Browser in its bottom band"
assert_window_exists
info "=== Dock seams (Browser band) done ==="
