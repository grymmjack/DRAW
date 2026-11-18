#!/bin/bash
# =============================================================================
# sel-bar-tips.sh — QA test: the Selection Bar's tooltips (GUI/SEL-BAR
# SELBAR_tip$ / SELBAR_tip_at%, TOOLTIP_SRC_SEL_BAR = 15): resting on a control
# shows its tip (what it is and does), for a chip, a slider and a button; off
# the bar there is none.
# Dump: TIP active source index; SELBARC id x y w trackX.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=FALSE HELP_CARD_ENABLED=FALSE SELECTION_BAR=TRUE SELECTION_MODE=REPLACE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14
SRC_SEL_BAR=15
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
tip_at() { # X Y -> TIP_ACT TIP_SRC TIP_IDX after resting there
    hover "$1" "$2"; wait_for 0.3 "rest"; hover $(( $1 + 1 )) "$2"; wait_for 2.0 "tooltip delay"
    dk_settle
    read -r _ TIP_ACT TIP_SRC TIP_IDX _ <<< "$(grep -m1 '^TIP ' "$DK_DUMP")"
}
tip_on() { # tip_on ID WHAT
    if ! sbc "$1"; then fail "no control $1 ($2) on the bar"; return; fi
    tip_at $(( C_X + C_W / 2 )) $(( C_Y + ROW_H / 2 ))
    if (( TIP_ACT != 0 && TIP_SRC == SRC_SEL_BAR && TIP_IDX == $1 )); then pass "$2: its tooltip shows"; else fail "$2: TIP '$TIP_ACT $TIP_SRC $TIP_IDX' (want active, $SRC_SEL_BAR $1)"; fi
}

info "=== Selection Bar tooltips ==="
dk_begin
key m; wait_for 0.6 "marquee"; dk_park; dk_settle

tip_on 2 "the ADD chip"
screenshot "sel-bar-tip-add"
tip_on 5 "the FEATHER slider"
tip_on 16 "the FROM CENTER toggle"
tip_on 19 "the GROW button"
# off the bar: none from it
dk_park; wait_for 2.0 "rest on the canvas"; dk_settle
read -r _ TIP_ACT TIP_SRC TIP_IDX _ <<< "$(grep -m1 '^TIP ' "$DK_DUMP")"
(( TIP_SRC != SRC_SEL_BAR || TIP_ACT == 0 )) && pass "off the bar: no Selection Bar tip" || fail "a Selection Bar tip off the bar (TIP $TIP_ACT $TIP_SRC $TIP_IDX)"

assert_no_crash
assert_window_exists
info "=== Selection Bar tooltips test done ==="
