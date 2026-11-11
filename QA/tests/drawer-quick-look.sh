#!/bin/bash
# =============================================================================
# drawer-quick-look.sh — QA test: Bin Quick Look (hover a Drawer bin, the
# Preview shows it). A small brush grows by whole steps so pixel art stays
# crisp (2.8; before, a brush was never scaled up, so a 3x3 brush showed as
# 3x3 pixels in a 200px pane). An empty bin and leaving the drawer give the
# canvas back; a bin past the first rows (Shift+wheel) works too.
# Fixture: QA/fixtures/drawer-40.dset (slot 1 = 3x3 brush, slot 40 = 7x5).
# PVQL: active slot mode srcW srcH drawnW drawnH · DRAWERR: row0 mode
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEFAULT_DSET_BRUSHES_FILE=QA/fixtures/drawer-40.dset DRAWER_MINI_PALETTE=0 PREVIEW_VISIBLE=1 PREVIEW_BIN_QUICK_LOOK=1 PREVIEW_W=200 PREVIEW_H=200
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ql_read() { read -r _ QL_ON QL_SLOT QL_MODE QL_SW QL_SH QL_DW QL_DH <<< "$(grep '^PVQL ' "$DK_DUMP")"; }
dl_read() { read -r _ DL_COLS DL_ROWS DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY _ <<< "$(grep '^DRAWERL ' "$DK_DUMP")"
            read -r _ DL_ROW0 DL_MODE <<< "$(grep '^DRAWERR ' "$DK_DUMP")"; }
# centre of bin $1 (1-based) as it is laid out now; returns 1 when that row is not showing
bin_xy() {
    dl_read
    local i=$(( $1 - 1 )) r c
    r=$(( i / DL_COLS - DL_ROW0 )); c=$(( i % DL_COLS ))
    (( r >= 0 && r < DL_VIS )) || return 1
    BX=$(( DL_CX + c * (DL_BW + DL_GX) + DL_BW / 2 )); BY=$(( DL_CY + r * (DL_BH + DL_GY) + DL_BH / 2 ))
}
ql_hover() { hover "$1" "$2"; sleep 0.3; hover $(( $1 + 1 )) "$2"; dk_settle; ql_read; }

info "=== Bin Quick Look ==="
dk_begin
if ! grep -q '^PVQL ' "$DK_DUMP"; then fail "no PVQL line in the dock dump"; fi
ql_read
if [[ "$QL_ON" == 0 ]]; then pass "nothing previewed at the start"; else fail "quick look active at the start (slot $QL_SLOT)"; fi

# slot 1: a 3x3 brush, shown several times bigger, square, a whole multiple
bin_xy 1 || fail "slot 1 not showing"
ql_hover "$BX" "$BY"
if [[ "$QL_ON" == 1 && "$QL_SLOT" == 1 && "$QL_MODE" == 1 ]]; then pass "hovering slot 1 previews it (brush mode)"; else fail "slot 1: active=$QL_ON slot=$QL_SLOT mode=$QL_MODE"; fi
if [[ "$QL_SW" == 3 && "$QL_SH" == 3 ]]; then pass "source is the 3x3 brush"; else fail "source ${QL_SW}x$QL_SH, want 3x3"; fi
if (( QL_DW >= 30 && QL_DW == QL_DH && QL_DW % 3 == 0 )); then pass "the 3x3 brush is drawn at ${QL_DW}x$QL_DH (x$(( QL_DW / 3 )), crisp)"; else fail "3x3 brush drawn at ${QL_DW}x$QL_DH (want a whole multiple, >= x10)"; fi
if (( QL_DW <= 200 )); then pass "it fits the 200px Preview (${QL_DW})"; else fail "drawn ${QL_DW}px, wider than the 200px Preview"; fi
screenshot "quick-look-slot1"

# an empty bin: the canvas again
bin_xy 2 || fail "slot 2 not showing"
ql_hover "$BX" "$BY"
if [[ "$QL_ON" == 0 ]]; then pass "an empty bin shows nothing"; else fail "empty slot 2: still previewing slot $QL_SLOT"; fi

# back on slot 1, then off the drawer
bin_xy 1; ql_hover "$BX" "$BY"
dk_park; dk_settle; ql_read
if [[ "$QL_ON" == 0 ]]; then pass "leaving the drawer gives the Preview back"; else fail "still previewing slot $QL_SLOT after leaving"; fi

# slot 40 (7x5) sits below the rows showing: Shift+wheel until it shows
bin_xy 1; SX=$BX; SY=$BY; n=0
until bin_xy 40 || (( n >= 30 )); do with_mods shift scroll_down "$SX" "$SY"; dk_settle; n=$((n + 1)); done
if bin_xy 40; then pass "slot 40 scrolled into view (first row $DL_ROW0)"; else fail "could not scroll slot 40 into view"; fi
ql_hover "$BX" "$BY"
if [[ "$QL_ON" == 1 && "$QL_SLOT" == 40 ]]; then pass "hovering scrolled slot 40 previews it"; else fail "slot 40: active=$QL_ON slot=$QL_SLOT"; fi
if (( QL_SW == 7 && QL_SH == 5 && QL_DW % 7 == 0 && QL_DW / 7 == QL_DH / 5 && QL_DH % 5 == 0 && QL_DW > 7 )); then
    pass "7x5 brush drawn at ${QL_DW}x$QL_DH (x$(( QL_DW / 7 )), same step both ways)"
else fail "7x5 brush: source ${QL_SW}x$QL_SH drawn ${QL_DW}x$QL_DH"; fi
screenshot "quick-look-slot40"
dk_park; dk_settle
assert_window_exists
info "=== Bin Quick Look PASSED ==="
