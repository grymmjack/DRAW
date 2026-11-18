#!/bin/bash
# =============================================================================
# dock-browser-columns.sh — QA test: the Browser in the left / right dock
# columns (Rick 2026-11-16: "and allow browser to dock to left/right?"). It is a
# native-window slot like the Preview's: menu, drag, from a row, and back.
#   menu     floating Browser's handle menu: Dock Left / Dock Right / Along the
#            Top / Bottom; Dock Left -> a left column
#   move     handle menu Move to Right Edge -> a right column
#   stack    below the layers (a slot in their column)
#   from row Along the bottom, then the left edge: a column again (no row left)
#   persist  restart: still in its left column
#   fuzz     a short fuzz with the Browser among the columns
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: the Browser in the side columns Test ==="
dk_begin
dk_check "start"
dk_expect_floating browser

# --- the floating Browser's menu (DOCK_ACT_LEFT 1 / RIGHT 2 / BAND_TOP 7 / BAND_BOTTOM 8)
dk_rmenu browser
if [[ "$M_OPEN" == -1 ]] && dk_menu_has 1 && dk_menu_has 2 && dk_menu_has 7 && dk_menu_has 8; then
    pass "floating Browser's menu offers Dock Left / Right / Along the Top / Bottom"
else
    fail "browser menu: open '$M_OPEN', rows: $(grep '^DMENUR' "$DK_DUMP" | awk '{print $3}' | paste -sd,)"
fi
dk_pick 1 "Dock Left"
dk_expect_side browser 1
dk_check "browser docked left (menu)"
screenshot "dock-browser-left"

# --- Move to Right Edge ------------------------------------------------------
dk_rmenu browser
dk_pick 2 "Move to Right Edge"
dk_expect_side browser 2
dk_check "browser moved to the right edge (menu)"

# --- a slot under the layers ---------------------------------------------------
dk_move_expect browser below layers; dk_check "browser below the layers"
dk_p browser
if (( P_W >= 100 && P_H >= 60 )); then pass "browser in a column slot is usable (${P_W}x$P_H)"; else fail "browser in a column slot: ${P_W}x$P_H"; fi

# --- from a row to a column ------------------------------------------------------
dk_move_expect browser band-bottom; dk_check "browser along the bottom"
dk_move_expect browser edge-left;   dk_check "browser from the row to a left column"
dk_band; if (( B_SIDE == 0 )); then pass "no row holds the Browser any more"; else fail "the Browser's row is still there (side $B_SIDE)"; fi
dk_rows; if (( R_BOTH == 0 )); then pass "the bottom row is gone with it"; else fail "an empty bottom row is left (${R_BOTH}px)"; fi
dk_expect_side browser 1

# --- persists --------------------------------------------------------------------
draw_quit
rm -f "$DK_DUMP"
draw_launch 15
dk_begin
dk_expect_side browser 1
dk_check "after restart"
screenshot "dock-browser-left-restarted"

dk_fuzz 5 8 browser layers toolbox editbar

assert_window_exists
info "=== Dock: the Browser in the side columns Test PASSED ==="
