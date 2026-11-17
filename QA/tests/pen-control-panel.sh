#!/bin/bash
# =============================================================================
# pen-control-panel.sh — QA test: the Pen Control panel's tabs (Rick
# 2026-11-17: stabilization like Lazy Nezumi; Pen Pressure renamed Pen Control)
#   1 the panel opens on PRESSURE; the tab strip switches to SMOOTHING
#   2 SMOOTH POSITION, a mode chip (EMA) and the AMOUNT slider set and save
#     PEN_STAB / PEN_STAB_MODE / PEN_STAB_AMOUNT
#   3 SPEED: SPEED SCALING saves PEN_SPEED; the graph redraws (dim -> lit curve)
#   4 the tab survives a restart (PEN_PANEL_TAB)
#   5 the command palette's "Pen Control: Next Smoothing Mode" steps the mode
# Dump (native px): PENPL inRow panelW panelH ...; PENPC ctl x0 x1 y tx0 tx1;
# PENPT tab tabH hint(4) graph(4) readout(3) subX pad; WIN pen x y w h.
# (the keys under test stay out of QA-OPTIONS: --option values are never saved)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PEN_PANEL_VISIBLE=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

pp_read() {
    read -r _ PL_ROW PL_W PL_H _ <<< "$(grep -m1 '^PENPL ' "$DK_DUMP")"
    read -r _ _ WX WY WW WH _ <<< "$(grep -m1 '^WIN pen ' "$DK_DUMP")"
    read -r _ PT_TAB PT_TABH _ _ _ _ SG_X0 SG_Y0 SG_X1 SG_Y1 _ _ _ PT_SUBX PT_PAD <<< "$(grep -m1 '^PENPT ' "$DK_DUMP")"
}
pc() { read -r _ _ C_X0 C_X1 C_Y C_TX0 C_TX1 <<< "$(awk -v c="$1" '$1=="PENPC" && $2==c' "$DK_DUMP")"; }
vx() { echo $(( WX + $1 * WW / PL_W )); } # native -> viewport
vy() { echo $(( WY + $1 * WH / PL_H )); }
cfgv() { grep -m1 "^$1=" "$QA_CFG" | cut -d= -f2 | tr -d '[:space:]'; }
pclick() { click "$(vx "$1")" "$(vy "$2")"; wait_for 0.5 "click"; dk_park; dk_settle; pp_read; }
seg() { # CTL I N - click segment I (0-based) of N in a tab strip / mode row
    local x0 h
    pc "$1"
    if (( $1 == 24 )); then x0=$C_X0; h=$PT_TABH; else x0=$(( C_X0 + PT_SUBX - PT_PAD )); h=6; fi
    pclick $(( x0 + (C_X1 - x0 + 1) * (2 * $2 + 1) / (2 * $3) )) $(( C_Y + h / 2 ))
}
box() { pc "$1"; pclick $(( C_X0 + 3 )) $(( C_Y + 4 )); } # a checkbox

info "=== Pen Control panel: tabs ==="
dk_begin
dk_settle; pp_read
if [[ -z "$PL_W" || -z "$PT_TAB" ]]; then fail "no PENPL / PENPT line (is the Pen Control panel up?)"; assert_no_crash; exit 0; fi
[[ "$PT_TAB" == 0 ]] && pass "the panel opens on PRESSURE" || fail "PENPT tab=$PT_TAB at start"

# --- 1: SMOOTHING ------------------------------------------------------------------
seg 24 1 3
[[ "$PT_TAB" == 1 ]] && pass "the tab strip switches to SMOOTHING" || fail "tab=$PT_TAB after clicking SMOOTHING"
[[ "$(cfgv PEN_PANEL_TAB)" == 1 ]] && pass "PEN_PANEL_TAB=1 saved" || fail "PEN_PANEL_TAB=$(cfgv PEN_PANEL_TAB)"
screenshot "pen-control-smoothing"

# --- 2: smoothing on, EMA, amount ------------------------------------------------------
box 10
[[ "$(cfgv PEN_STAB)" == TRUE ]] && pass "SMOOTH POSITION turns smoothing on" || fail "PEN_STAB=$(cfgv PEN_STAB)"
seg 11 2 4
[[ "$(cfgv PEN_STAB_MODE)" == 3 ]] && pass "the EMA chip picks Exponential MA" || fail "PEN_STAB_MODE=$(cfgv PEN_STAB_MODE)"
pc 12
dk_drag "$(vx $(( C_TX0 + 2 )))" "$(vy $(( C_Y + 3 )))" "$(vx $(( C_TX1 + 2 )))" "$(vy $(( C_Y + 3 )))" 6; dk_park; dk_settle
A=$(cfgv PEN_STAB_AMOUNT)
(( ${A:-0} >= 95 )) && pass "the AMOUNT slider drags to the top ($A)" || fail "PEN_STAB_AMOUNT=$A after a drag to the right end"

# --- 3: SPEED ------------------------------------------------------------------------
seg 24 2 3
[[ "$PT_TAB" == 2 ]] && pass "the tab strip switches to SPEED" || fail "tab=$PT_TAB after clicking SPEED"
snap_region "$(vx $(( SG_X0 + 2 )))" "$(vy $(( SG_Y0 + 2 )))" $(( (SG_X1 - SG_X0 - 4) * WW / PL_W )) $(( (SG_Y1 - SG_Y0 - 4) * WH / PL_H )) "speed-graph-off"; G0=$SNAP_RESULT
box 19
[[ "$(cfgv PEN_SPEED)" == TRUE ]] && pass "SPEED SCALING turns speed scaling on" || fail "PEN_SPEED=$(cfgv PEN_SPEED)"
snap_region "$(vx $(( SG_X0 + 2 )))" "$(vy $(( SG_Y0 + 2 )))" $(( (SG_X1 - SG_X0 - 4) * WW / PL_W )) $(( (SG_Y1 - SG_Y0 - 4) * WH / PL_H )) "speed-graph-on"; G1=$SNAP_RESULT
assert_regions_differ "$G0" "$G1" "the speed graph's curve lights up with speed scaling on"
screenshot "pen-control-speed"

# --- 4: the tab survives a restart ---------------------------------------------------------
draw_quit; draw_settle
draw_launch 15; wait_for 1.5 "DRAW up again"
dk_begin; pp_read
[[ "$PT_TAB" == 2 ]] && pass "the SPEED tab is still up after a restart" || fail "tab=$PT_TAB after a restart"

# --- 5: the command palette ------------------------------------------------------------------
park_mouse; key question; wait_for 1.0 "palette"
type_text "next smoothing mode"; wait_for 2.0 "filtered"
key Return; wait_for 1.0 "ran"
dk_settle
[[ "$(cfgv PEN_STAB_MODE)" == 4 ]] && pass "Next Smoothing Mode steps EMA -> Inertia" || fail "PEN_STAB_MODE=$(cfgv PEN_STAB_MODE) after Next Smoothing Mode"
assert_no_crash
info "=== Pen Control panel done ==="
