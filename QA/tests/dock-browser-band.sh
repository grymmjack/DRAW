#!/bin/bash
# =============================================================================
# dock-browser-band.sh — QA test: the Browser docks along the top or bottom of
# the canvas area (its band - the one exception to left/right-only docking).
#   bottom   drag its title to the bottom: band 2, the canvas shifts up
#   resize   drag the band's top edge up: taller, saved (DOCK_BAND=BOTTOM,h)
#   top      drag its title (the band's handle) to the top: band 1
#   column   into a left column: no band any more
#   back     from the column to the bottom band again
#   float    it floats: no band
#   restart  docked along the bottom, relaunch: still there, same height
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=60
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: the Browser's band Test ==="
dk_begin
dk_check "start"

dk_move_expect browser band-bottom; dk_check "browser along the bottom"
screenshot "dock-band-bottom"

# taller by its top edge
dk_band; H0=$B_H; EX=$(( B_X + B_W / 2 )); EY=$B_Y
dk_drag "$EX" "$EY" "$EX" $(( EY - 60 )) 5; dk_park; dk_settle
dk_band
if (( B_H >= H0 + 40 )); then pass "band taller by its edge ($H0 -> $B_H)"; else fail "band edge drag: $H0 -> $B_H"; fi
SB=$(grep -m1 '^DOCK_BAND=' "$QA_CFG" | tr -d '\r')
if [[ "$SB" == "DOCK_BAND=BOTTOM,$B_H" ]]; then pass "band height saved ($SB)"; else fail "band not saved as BOTTOM,$B_H ($SB)"; fi
dk_check "band resized"

dk_move_expect browser band-top;    dk_check "browser along the top"
screenshot "dock-band-top"
dk_move_expect browser edge-left
dk_band; if (( B_SIDE == 0 )); then pass "in a column: no band"; else fail "band still set ($B_SIDE) with the browser in a column"; fi
dk_check "browser in a left column"
dk_move_expect browser band-bottom; dk_check "from the column back to the bottom band"
dk_move_expect browser float
dk_band; if (( B_SIDE == 0 )); then pass "floating: no band"; else fail "band still set ($B_SIDE) with the browser floating"; fi
dk_check "browser floating"

# persists
dk_move_expect browser band-bottom; dk_check "bottom again"
dk_band; H1=$B_H
draw_quit
rm -f "$DK_DUMP"
draw_launch 15
dk_begin
dk_expect_band 2
dk_band; if (( B_H == H1 )); then pass "same band height after a restart ($B_H)"; else fail "band height $H1 -> $B_H after a restart"; fi
dk_check "after restart"
screenshot "dock-band-restarted"

assert_window_exists
info "=== Dock: the Browser's band Test PASSED ==="
