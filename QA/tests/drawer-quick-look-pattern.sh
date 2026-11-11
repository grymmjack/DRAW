#!/bin/bash
# =============================================================================
# drawer-quick-look-pattern.sh — QA test: Bin Quick Look in pattern mode (F3):
# a .draw whose drAx chunk holds pattern slot 35 (4x4); scroll to it, hover:
# the Preview tiles the pattern (PVQL mode 2, source 4x4). Brush slot 40 of the
# same file previews in brush mode after F1.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0 PREVIEW_VISIBLE=1 PREVIEW_BIN_QUICK_LOOK=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
ql_read() { read -r _ QL_ON QL_SLOT QL_MODE QL_SW QL_SH QL_DW QL_DH <<< "$(grep '^PVQL ' "$DK_DUMP")"; }
dl_read() { read -r _ DL_COLS DL_ROWS DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY _ <<< "$(grep '^DRAWERL ' "$DK_DUMP")"
            read -r _ DL_ROW0 DL_MODE <<< "$(grep '^DRAWERR ' "$DK_DUMP")"; }
bin_xy() {
    dl_read
    local i=$(( $1 - 1 )) r c
    r=$(( i / DL_COLS - DL_ROW0 )); c=$(( i % DL_COLS ))
    (( r >= 0 && r < DL_VIS )) || return 1
    BX=$(( DL_CX + c * (DL_BW + DL_GX) + DL_BW / 2 )); BY=$(( DL_CY + r * (DL_BH + DL_GY) + DL_BH / 2 ))
}
scroll_to() { # SLOT
    local n=0 sx sy
    dl_read; sx=$(( DL_CX + DL_BW / 2 )); sy=$(( DL_CY + DL_BH / 2 ))
    until bin_xy "$1" || (( n >= 30 )); do with_mods shift scroll_down "$sx" "$sy"; dk_settle; n=$((n + 1)); done
    bin_xy "$1"
}
ql_hover() { hover "$1" "$2"; sleep 0.3; hover $(( $1 + 1 )) "$2"; dk_settle; ql_read; }

info "=== Bin Quick Look: patterns ==="
RT_FILE="${RESULTS_DIR:-/tmp}/quick-look-$$.draw"
cp "$DRAW_ROOT/QA/fixtures/drawer-40.draw" "$RT_FILE" || fail "could not stage $RT_FILE"
draw_quit
DRAW_EXTRA_ARGS="$RT_FILE"
draw_launch 15
wait_for 1.5 "drawer-40.draw loaded"
dk_begin

wake_draw; key F3; dk_settle; dl_read
if [[ "$DL_MODE" == 2 ]]; then pass "F3: pattern mode"; else fail "F3: drawer mode $DL_MODE, want 2"; fi
if scroll_to 35; then pass "pattern slot 35 in view"; else fail "could not scroll to pattern slot 35"; fi
ql_hover "$BX" "$BY"
if [[ "$QL_ON" == 1 && "$QL_SLOT" == 35 && "$QL_MODE" == 2 ]]; then pass "hovering pattern slot 35 previews it (mode 2)"; else fail "pattern slot 35: active=$QL_ON slot=$QL_SLOT mode=$QL_MODE"; fi
if [[ "$QL_SW" == 4 && "$QL_SH" == 4 ]]; then pass "source is the 4x4 pattern"; else fail "pattern source ${QL_SW}x$QL_SH"; fi
screenshot "quick-look-pattern"
dk_park; dk_settle

wake_draw; key F1; dk_settle
if scroll_to 40; then pass "brush slot 40 in view"; else fail "could not scroll to brush slot 40"; fi
ql_hover "$BX" "$BY"
if [[ "$QL_ON" == 1 && "$QL_SLOT" == 40 && "$QL_MODE" == 1 && "$QL_SW" == 7 ]]; then pass "F1 then brush slot 40 previews the 7x5 brush"; else fail "brush slot 40: active=$QL_ON slot=$QL_SLOT mode=$QL_MODE src=${QL_SW}x$QL_SH"; fi
dk_park; dk_settle

rm -f "$RT_FILE"
draw_quit
DRAW_EXTRA_ARGS=""
draw_launch 15
wait_for 0.8 "Default instance restored"
assert_window_exists
info "=== Bin Quick Look: patterns PASSED ==="
