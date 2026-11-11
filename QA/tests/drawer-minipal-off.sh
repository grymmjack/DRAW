#!/bin/bash
# =============================================================================
# drawer-minipal-off.sh — QA test: with DRAWER_MINI_PALETTE off (the default
# outside QA) the Drawer has no mini palette and the bins take its space: more
# columns, reaching the drawer's right edge, instead of a 34% palette rail.
# Reads DRAWERL <cols> <rows> <rows shown> <pal y> <pal h> <bottom> <bin x> <bin y>
# <bin w> <bin h> <gap x> <gap y> ... and P drawer.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Drawer: mini palette off Test ==="
dk_begin
dk_check "layout sane"
dk_p drawer
info "drawer at $P_X,$P_Y ${P_W}x$P_H"
read -r _ DCOLS DROWS DVIS DPALY DPALH DY2 BX BY BW BH GX GY _ <<< "$(grep '^DRAWERL ' "$DK_DUMP")"
info "drawer layout: cols=$DCOLS rows=$DROWS visible=$DVIS palette y=$DPALY h=$DPALH bins at $BX,$BY ${BW}x$BH gap $GX"

if (( ${DPALH:-1} == 0 )); then pass "no mini palette"; else fail "mini palette still shown (h=$DPALH)"; fi

# The bins span the drawer: what is left at the right edge is less than one bin
RIGHT=$(( BX + DCOLS * (BW + GX) - GX ))
LEFTPAD=$(( BX - P_X ))
SPARE=$(( P_X + P_W - LEFTPAD - RIGHT ))
if (( SPARE < BW + GX )); then pass "bins fill the width ($DCOLS columns, ${SPARE}px spare)"; else fail "${SPARE}px empty right of the bins ($DCOLS columns of ${BW}px)"; fi
if (( DCOLS > 3 )); then pass "more than the classic 3 columns ($DCOLS)"; else fail "still $DCOLS columns: the rail's space was not given to the bins"; fi

screenshot "drawer-minipal-off"
assert_window_exists
info "=== Drawer: mini palette off Test PASSED ==="
