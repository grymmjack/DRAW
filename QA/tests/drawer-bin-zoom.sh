#!/bin/bash
# =============================================================================
# drawer-bin-zoom.sh — QA test: the Drawer's bins fill its width (no strip left
# on the right - Rick, 2026-11-11: "so they fit elegantly under the organizer
# with no wasted space"), and Ctrl+wheel over the bins zooms them: wheel up =
# fewer, bigger bins per row; wheel down = more. The zoom is saved
# (DRAWER_BIN_COLS) and the bins still fill the width at every step.
# DRAWERL: cols rows vis palY palH panelY2 contentX contentY binW binH gapX gapY ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

dl_read() { read -r _ DL_COLS DL_ROWS DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX _ <<< "$(grep '^DRAWERL ' "$DK_DUMP")"; }
# the bins span the drawer: what is left at the right is no more than the
# padding + an odd pixel, and no wider than what is left at the left + 1
dl_fills() {
    dl_read; dk_p drawer
    local used=$(( DL_COLS * DL_BW + (DL_COLS - 1) * DL_GX )) left right
    left=$(( DL_CX - P_X )); right=$(( P_X + P_W - DL_CX - used ))
    info "$1: $DL_COLS cols of ${DL_BW}x$DL_BH, drawer x=$P_X w=$P_W, left $left right $right"
    if (( right <= left + 1 && right <= 4 )); then pass "$1: the bins fill the width (left $left, right $right)"; else fail "$1: a ${right}px strip at the right (left $left)"; fi
    if (( DL_BW == DL_BH )); then pass "$1: square bins"; else fail "$1: bins ${DL_BW}x$DL_BH"; fi
}

info "=== Drawer: bins fill the width, Ctrl+wheel zooms ==="
dk_begin
dl_fills "auto"
C0=$DL_COLS; B0=$DL_BW
BX=$(( DL_CX + DL_BW / 2 )); BY=$(( DL_CY + DL_BH / 2 ))

with_mods ctrl scroll_up "$BX" "$BY"; dk_park; dk_settle
dl_fills "Ctrl+wheel up"
if (( DL_COLS == C0 - 1 && DL_BW > B0 )); then pass "zoomed in: $C0 -> $DL_COLS per row, bins $B0 -> $DL_BW"; else fail "zoom in: $C0 -> $DL_COLS per row, bins $B0 -> $DL_BW"; fi
if grep -q "^DRAWER_BIN_COLS=$DL_COLS" "$QA_CFG"; then pass "saved DRAWER_BIN_COLS=$DL_COLS"; else fail "DRAWER_BIN_COLS not saved ($(grep '^DRAWER_BIN_COLS' "$QA_CFG"))"; fi

dl_read; BX=$(( DL_CX + DL_BW / 2 )); BY=$(( DL_CY + DL_BH / 2 ))
with_mods ctrl scroll_down "$BX" "$BY"; with_mods ctrl scroll_down "$BX" "$BY"; dk_park; dk_settle
dl_fills "Ctrl+wheel down x2"
if (( DL_COLS == C0 + 1 )); then pass "zoomed out: $DL_COLS per row"; else fail "zoom out: $DL_COLS per row, want $(( C0 + 1 ))"; fi
dk_check "after zooming"
screenshot "drawer-bin-zoom"
assert_window_exists
info "=== Drawer bin zoom PASSED ==="
