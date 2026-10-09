#!/bin/bash
# =============================================================================
# dock-toolbox-stacked-fit.sh — QA test: with the organizer and drawer stacked
# under it (the default column), a 1-column toolbox still adds columns until
# the buttons, the organizer and a usable drawer fit the window height
# (TOOLBAR_reflow counts what shares its column).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLBOX_COLUMNS=1
# =============================================================================

source "$DRAW_ROOT/QA/dock-lib.sh"

info "=== Stacked toolbox column still fits the height ==="
wait_for 1.0 "settle"
key Escape
dk_park
dk_settle
dk_scr
COLS=$(awk '$1 == "BTN" && $2 == "toolbox" {print $7}' "$DK_DUMP" | sort -un | wc -l)
if (( COLS >= 3 )); then pass "1 column asked, $COLS used: the organizer and drawer are counted"; else fail "only $COLS columns: the column overflows"; fi
dk_p drawer
if (( P_Y + P_H - 1 <= DOCK_BOT )); then pass "the drawer ends inside the window (y $(( P_Y + P_H - 1 )) <= $DOCK_BOT)"; else fail "the drawer runs past the window bottom"; fi
assert_no_crash
