#!/bin/bash
# =============================================================================
# dock-charmap-stub.sh — QA test: the character map's "stub" (the strip beside
# the menu bar it paints when it heads its own column) is never painted over
# the panels ABOVE it when it is stacked below them. It once filled y=0 down to
# its own top across its width, wiping the toolbox and organizer to one flat
# colour (their clicks still worked, invisibly).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt CHARMAP_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: charmap stub below other panels Test ==="
dk_begin
dk_move_expect charmap below organizer; dk_check "charmap below the organizer"
dk_park; dk_settle; wait_for 0.5 "settle render"

# a panel's rect should show its widgets, not one flat fill
colours_in() { identify -format '%k' "$1" 2>/dev/null; }
for name in toolbox organizer; do
    dk_p "$name" || fail "$name not in the dock dump"
    (( P_H > 4 )) || fail "$name has no height ($P_H)"
    snap_region "$P_X" "$P_Y" "$P_W" "$P_H" "stub-$name"
    n=$(colours_in "$SNAP_RESULT")
    info "$name at $P_X,$P_Y ${P_W}x$P_H: $n colours"
    if (( n > 3 )); then
        pass "the $name above the charmap is still drawn ($n colours)"
    else
        fail "the $name above the charmap is painted over (only $n colours)"
    fi
done
screenshot "dock-charmap-stub"
assert_window_exists
info "=== Dock: charmap stub below other panels Test PASSED ==="
