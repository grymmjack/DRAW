#!/bin/bash
# =============================================================================
# dock-bar-scroll-grow.sh — QA test: the edit bar's scroll offset follows its
# slot. Scrolled in a short slot, then given room (the panel above it moved
# away), its top icons must come back. The offset was never re-clamped, and the
# wheel does nothing once the content fits, so they stayed scrolled away.
# Reads BARS <ebScroll> <ebContentH> ... from the QA dump.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt EDIT_BAR_COLUMNS=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: edit bar scroll after its slot grows Test ==="
dk_begin
eb_scroll()   { awk '$1 == "BARS" {print $2}' "$DK_DUMP"; }
eb_content()  { awk '$1 == "BARS" {print $3}' "$DK_DUMP"; }

# short: the layers above the edit bar, sharing its column
dk_move layers above editbar && dk_expect_stacked layers editbar
dk_check "layers above the edit bar"
# make it short: drag the divider between them down (in the layers' width it
# reflows into several columns and would fit otherwise)
dk_p editbar
dk_drag $(( P_X + P_W / 2 )) $(( P_Y - 1 )) $(( P_X + P_W / 2 )) $(( P_Y + P_H - 60 ))
dk_park; dk_settle
dk_p editbar
info "edit bar ${P_W}x$P_H at $P_X,$P_Y, content $(eb_content)"
(( $(eb_content) > P_H )) || fail "the edit bar is not short enough to scroll (content $(eb_content) <= $P_H)"
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do scroll_down $(( P_X + P_W / 2 )) $(( P_Y + P_H / 2 )); done
wait_for 0.3 "scrolled"; dk_park; dk_settle
S1=$(eb_scroll)
(( S1 > 0 )) && pass "the short edit bar scrolled ($S1 px)" || fail "the edit bar did not scroll (offset $S1)"

# room again: the layers out of its column
if [[ "$(dk_side_of editbar)" == 1 ]]; then dk_move layers edge-right; else dk_move layers edge-left; fi
dk_expect_docked layers
dk_park; dk_settle; wait_for 0.3 "redraw"; dk_settle
dk_p editbar
C=$(eb_content); S2=$(eb_scroll)
MAXOFF=$(( C - (P_H - 1) )); (( MAXOFF < 0 )) && MAXOFF=0
info "edit bar now ${P_W}x$P_H, content $C, offset $S2 (max $MAXOFF)"
if (( S2 <= MAXOFF )); then
    pass "the offset is within the content after the slot grew ($S2 <= $MAXOFF)"
else
    fail "the edit bar stays scrolled past its content ($S2 > $MAXOFF): its top icons are gone"
fi
assert_window_exists
info "=== Dock: edit bar scroll after its slot grows Test PASSED ==="
