#!/bin/bash
# =============================================================================
# drawer-quick-look-off.sh — QA test: with Bin Quick Look turned off
# (PREVIEW_BIN_QUICK_LOOK=0; View > Preview menu / Settings > Panels > Preview)
# hovering a stored bin leaves the Preview on the canvas.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DEFAULT_DSET_BRUSHES_FILE=QA/fixtures/drawer-40.dset DRAWER_MINI_PALETTE=0 PREVIEW_VISIBLE=1 PREVIEW_BIN_QUICK_LOOK=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
ql_read() { read -r _ QL_ON QL_SLOT _ <<< "$(grep '^PVQL ' "$DK_DUMP")"; }
info "=== Bin Quick Look off ==="
dk_begin
if ! grep -q '^PVQL ' "$DK_DUMP"; then fail "no PVQL line in the dock dump"; fi
read -r _ _ _ _ _ _ _ CX CY BW BH _ <<< "$(grep '^DRAWERL ' "$DK_DUMP")"
hover $(( CX + BW / 2 )) $(( CY + BH / 2 )); sleep 0.3; hover $(( CX + BW / 2 + 1 )) $(( CY + BH / 2 )); dk_settle; ql_read
if [[ "$QL_ON" == 0 ]]; then pass "quick look off: hovering slot 1 leaves the Preview alone"; else fail "quick look off, but previewing slot $QL_SLOT"; fi
dk_park; dk_settle
assert_window_exists
info "=== Bin Quick Look off PASSED ==="
