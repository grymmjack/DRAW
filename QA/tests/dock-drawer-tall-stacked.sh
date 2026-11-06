#!/bin/bash
# =============================================================================
# dock-drawer-tall-stacked.sh — QA test: a 1-bin-wide drawer (its palette under
# the bins) in a tall slot shows more bin rows instead of an empty area under
# the palette. The palette was always given a third of the drawer's height.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLBOX_COLUMNS=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: tall one-column drawer Test ==="
dk_begin
dk_move drawer newcol toolbox
dk_check "drawer in its own column"
dk_p drawer
info "drawer at $P_X,$P_Y ${P_W}x$P_H"
read -r _ DCOLS DROWS DVIS DPALY DPALH DY2 <<< "$(grep '^DRAWERL ' "$DK_DUMP")"
info "drawer layout: cols=$DCOLS rows=$DROWS visible=$DVIS palette y=$DPALY h=$DPALH bottom=$DY2"
(( DCOLS == 1 )) || info "(drawer has $DCOLS columns)"
GAP=$(( DY2 - (DPALY + DPALH) ))
BINPITCH=$(( (DPALY - P_Y) / (DVIS > 0 ? DVIS : 1) ))
if (( DVIS >= DROWS || GAP < BINPITCH + 4 )); then pass "no empty area under the palette ($GAP px, a bin row is $BINPITCH px)"; else fail "${GAP}px empty under the palette while only $DVIS of $DROWS bin rows show"; fi
screenshot "dock-drawer-tall-stacked"
assert_window_exists
info "=== Dock: tall one-column drawer Test PASSED ==="
