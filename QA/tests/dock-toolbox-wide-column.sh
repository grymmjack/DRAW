#!/bin/bash
# =============================================================================
# dock-toolbox-wide-column.sh — QA test: a toolbox in a column held WIDER than
# its own columns (the charmap stacked in it) is only as tall as the button
# rows it draws. Its height came from the wanted columns (1 here = many rows)
# while the buttons reflow across the whole width (fewer rows), leaving an
# empty band under them that pushed the organizer / drawer down - and dragging
# the column's edge narrower (fewer wanted columns) grew it.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt CHARMAP_VISIBLE=1 TOOLBOX_COLUMNS=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: toolbox in a wide column has no gap Test ==="
dk_begin
check_gap() {
    dk_p toolbox
    local bot
    bot=$(awk '$1 == "BTN" && $2 == "toolbox" && $9 > 0 {b = $8 + $10; if (b > m) m = b} END {print m + 0}' "$DK_DUMP")
    local gap=$(( P_Y + P_H - bot ))
    info "$1: toolbox ${P_W}x$P_H at y=$P_Y, its buttons end at y=$bot (gap $gap)"
    if (( gap <= 2 )); then pass "$1: the toolbox ends under its last button row"; else fail "$1: an empty band of ${gap}px under the toolbox's buttons"; fi
}
check_gap "alone in its column"
dk_move_expect charmap below drawer; dk_check "charmap below the drawer"
dk_park; dk_settle
dk_p charmap; CW=$P_W; dk_p toolbox
info "column now ${P_W}px wide (charmap $CW)"
check_gap "the charmap holds the column wide"
screenshot "dock-toolbox-wide-column"
assert_window_exists
info "=== Dock: toolbox in a wide column has no gap Test PASSED ==="
