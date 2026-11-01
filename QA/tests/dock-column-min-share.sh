#!/bin/bash
# =============================================================================
# dock-column-min-share.sh — QA test: a flex panel's minimum is kept INSIDE its
# column. The Preview docked above the layers with a tiny share (@1 vs @9): its
# share of the column is smaller than the Preview's minimum height. The old
# column code raised the Preview to its minimum without the layers giving way,
# so the column ran past the dock's bottom; the column is now one LAYOUT line
# in flex mode - the Preview freezes at its minimum and the layers take the rest.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer DOCK_LEFT_2=AUTO;advbar DOCK_RIGHT_1=AUTO;preview@1|layers@9 DOCK_RIGHT_2=AUTO;editbar
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

info "=== Dock: a flex minimum stays inside its column ==="
dk_begin
dk_check "start"
dk_expect_stacked preview layers
dk_scr
dk_p preview; dk_slot "$P_SLOT"; PY=$S_Y; PH=$S_H
dk_p layers; dk_slot "$P_SLOT"; LY=$S_Y; LH=$S_H
info "preview slot y=$PY h=$PH, layers slot y=$LY h=$LH, dock bottom $DOCK_BOT"
read -r _ _ _ _ _ WH _ <<< "$(grep '^WIN preview ' "$DK_DUMP")"
if (( PH >= WH )); then pass "the Preview's slot holds its window (slot $PH >= window $WH)"; else fail "the Preview's slot ($PH) is shorter than its window ($WH)"; fi
if (( LY + LH <= DOCK_BOT + 1 )); then
    pass "the layers end inside the column (bottom $(( LY + LH )) <= dock bottom $(( DOCK_BOT + 1 )))"
else
    fail "the column runs past the dock: layers bottom $(( LY + LH )) > dock bottom $(( DOCK_BOT + 1 ))"
fi
assert_no_crash
