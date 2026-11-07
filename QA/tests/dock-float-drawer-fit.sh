#!/bin/bash
# =============================================================================
# dock-float-drawer-fit.sh — QA test: a floating drawer's window goes no wider
# than its widest bin grid + palette and no taller than that content: dragged
# out past it, the window stops there instead of following the mouse, so no
# black area beside or under the bins. Rick, 2026-11-06: "the drawer has blank
# space" (a wide floating drawer, mostly black).
# Reads P drawer (window FX FY FW FH) and DRAWERL <cols> <rows> <rows shown> ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: floating drawer fits its content Test ==="
dk_begin
dk_scr
dk_move drawer float $(( CAN_LX + 80 )) $(( DOCK_TOP + 40 ))
dk_expect_floating drawer
dk_park; dk_settle
dk_p drawer; W0=$P_FW; H0=$P_FH; FX=$P_FX; FY=$P_FY
info "floating drawer $FX,$FY ${W0}x$H0"

CX=$(( FX + W0 - 2 )); CY=$(( FY + H0 - 2 ))
TX=$(( CAN_RX - 6 )); TY=$(( DOCK_BOT - 6 ))
dk_drag "$CX" "$CY" "$TX" "$TY"
dk_park; dk_settle
dk_p drawer; W1=$P_FW; H1=$P_FH
read -r _ COLS ROWS SHOWN _ <<< "$(grep '^DRAWERL' "$DK_DUMP")"
info "dragged the corner to $TX,$TY: window ${W1}x$H1, bins $COLS cols x $ROWS rows, $SHOWN rows showing"
WANTW=$(( TX - FX + 1 )); WANTH=$(( TY - FY + 1 ))
if (( W1 > W0 )); then pass "the drawer widens ($W0 -> $W1)"; else fail "the drawer did not widen ($W0 -> $W1)"; fi
if (( W1 < WANTW - 20 )); then pass "it stops at its widest content ($W1 px, the mouse asked $WANTW)"; else fail "the window followed the mouse to $W1 px wide (black beside the bins)"; fi
if (( H1 < WANTH - 20 )); then pass "it stops at its content's height ($H1 px, the mouse asked $WANTH)"; else fail "the window followed the mouse to $H1 px tall (black under the bins)"; fi
if (( SHOWN == ROWS )); then pass "every bin row shows ($ROWS)"; else fail "only $SHOWN of $ROWS bin rows show"; fi
screenshot "dock-float-drawer-wide"

# shorter than its content is fine: the bins scroll
dk_p drawer
CX=$(( P_FX + P_FW - 2 )); CY=$(( P_FY + P_FH - 2 ))
dk_drag "$CX" "$CY" "$CX" $(( CY - P_FH / 3 ))
dk_park; dk_settle
dk_p drawer; H2=$P_FH
read -r _ COLS ROWS SHOWN _ <<< "$(grep '^DRAWERL' "$DK_DUMP")"
if (( H2 < H1 )); then pass "it can be made shorter ($H1 -> $H2, $SHOWN of $ROWS rows show)"; else fail "it did not get shorter ($H1 -> $H2)"; fi
assert_window_exists
info "=== Dock: floating drawer fits its content Test PASSED ==="
