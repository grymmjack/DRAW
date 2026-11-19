#!/bin/bash
# =============================================================================
# pen-control-tooltips.sh — QA test: the Pen Control panel's tooltips (Rick
# 2026-11-17: "can you add tooltips about what they do? and examples").
# Hovering a control shows a three-line tip - what it is, how it behaves,
# TRY: an example (PENP_tip$) - as TOOLTIP_SRC_PEN_PANEL (14) with idx
# ctl * 10 + segment + 1 (areas: PENP_TIP_* 40-44 the same way).
#   PRESSURE  tab chip, USE PEN PRESSURE, the CURVE slider, the meter, the graph
#   SMOOTHING each of the four mode chips (one tip per chip), AMOUNT, the hint box
#   SPEED     SPEED SCALING, the speed graph
#   the title bar (the dock handle) shows none
# Dump: TIP active source idx; PENPL / PENPC / PENPT (native px); WIN pen.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PEN_PANEL_VISIBLE=1 PEN_PANEL_TAB=0 TOOLTIPS_DISABLED=FALSE TOOLTIP_HOVER_DELAY_MS=300 HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

pp_read() {
    read -r _ PL_ROW PL_W PL_H PL_GX0 PL_GX1 PL_GY PL_GH _ <<< "$(grep -m1 '^PENPL ' "$DK_DUMP")"
    read -r _ _ WX WY WW WH _ <<< "$(grep -m1 '^WIN pen ' "$DK_DUMP")"
    read -r _ PT_TAB PT_TABH HB_X0 HB_Y0 HB_X1 HB_Y1 SG_X0 SG_Y0 SG_X1 SG_Y1 _ _ _ PT_SUBX PT_PAD <<< "$(grep -m1 '^PENPT ' "$DK_DUMP")"
}
pc() { read -r _ _ C_X0 C_X1 C_Y C_TX0 C_TX1 <<< "$(awk -v c="$1" '$1=="PENPC" && $2==c' "$DK_DUMP")"; }
vx() { echo $(( WX + $1 * WW / PL_W )); } # native -> viewport
vy() { echo $(( WY + $1 * WH / PL_H )); }
tip() { # NX NY (native) -> TIP_ACT TIP_SRC TIP_IDX after resting there
    hover "$(vx "$1")" "$(vy "$2")"; wait_for 0.3 "rest"
    hover $(( $(vx "$1") + 1 )) "$(vy "$2")"; wait_for 1.2 "tooltip delay"
    read -r _ TIP_ACT TIP_SRC TIP_IDX _ <<< "$(grep -m1 '^TIP ' "$DK_DUMP")"
}
want() { # IDX WHAT
    if [[ "$TIP_ACT" == -1 && "$TIP_SRC" == 14 && "$TIP_IDX" == "$1" ]]; then pass "$2 shows its tooltip"
    else fail "$2: TIP '$TIP_ACT $TIP_SRC $TIP_IDX' (wanted -1 14 $1)"; fi
}
seg_x() { # CTL I N -> native x of segment I's middle (TABS from the column's left, mode rows under the checkbox text)
    local x0
    pc "$1"
    if (( $1 == 24 )); then x0=$C_X0; else x0=$(( C_X0 + PT_SUBX - PT_PAD )); fi
    echo $(( x0 + (C_X1 - x0 + 1) * (2 * $2 + 1) / (2 * $3) ))
}
tab() { pc 24; click "$(vx "$(seg_x 24 "$1" 4)")" "$(vy $(( C_Y + PT_TABH / 2 )))"; wait_for 0.5 "tab $1"; dk_park; dk_settle; pp_read; }

info "=== Pen Control panel: tooltips ==="
dk_begin
dk_settle; pp_read
if [[ -z "$PL_W" || -z "$WW" ]]; then fail "no PENPL / WIN pen line (is the Pen Control panel up?)"; assert_no_crash; exit 0; fi
[[ "$PT_TAB" == 0 ]] || tab 0

# --- PRESSURE ------------------------------------------------------------------------
pc 24; tip "$(seg_x 24 0 4)" $(( C_Y + PT_TABH / 2 )); want 241 "the PRESSURE tab chip"
pc 1;  tip $(( C_X0 + 3 )) $(( C_Y + 3 )); want 11 "USE PEN PRESSURE"
screenshot "pen-tip-use-pressure"
pc 8;  tip $(( (C_TX0 + C_TX1) / 2 )) $(( C_Y + 2 )); want 81 "the CURVE slider"
screenshot "pen-tip-curve"
pc 3;  tip $(( (C_TX0 + C_TX1) / 2 )) $(( C_Y + 2 )); want 31 "the size LIGHT slider"
tip $(( (PL_GX0 + PL_GX1) / 2 )) $(( PL_GY + PL_GH / 2 )); want 411 "the RESPONSE graph"
screenshot "pen-tip-graph"

# --- the title bar: no tooltip ---------------------------------------------------------
hover $(( WX + WW / 3 )) $(( WY + 2 )); wait_for 1.2 "title bar"
read -r _ TIP_ACT TIP_SRC TIP_IDX _ <<< "$(grep -m1 '^TIP ' "$DK_DUMP")"
[[ "$TIP_SRC" != 14 ]] && pass "the title bar (dock handle) shows no Pen Control tip" || fail "title bar: TIP '$TIP_ACT $TIP_SRC $TIP_IDX'"

# --- SMOOTHING: one tip per mode chip --------------------------------------------------
dk_park; tab 1
[[ "$PT_TAB" == 1 ]] || fail "tab=$PT_TAB after clicking SMOOTHING"
pc 10; tip $(( C_X0 + 3 )) $(( C_Y + 3 )); want 101 "SMOOTH POSITION"
for i in 0 1 2 3; do
    pc 11; tip "$(seg_x 11 "$i" 4)" $(( C_Y + 3 )); want $(( 111 + i )) "smoothing mode chip $i"
    (( i == 0 )) && screenshot "pen-tip-string"
done
screenshot "pen-tip-inertia"
pc 12; tip $(( (C_TX0 + C_TX1) / 2 )) $(( C_Y + 2 )); want 121 "the smoothing AMOUNT slider"
pc 17; tip "$(seg_x 17 1 4)" $(( C_Y + 3 )); want 172 "the HOLD pressure chip"
screenshot "pen-tip-hold"
if (( HB_Y1 - HB_Y0 > 12 )); then
    tip $(( (HB_X0 + HB_X1) / 2 )) $(( (HB_Y0 + HB_Y1) / 2 )); want 441 "the mode hint box"
fi

# --- SPEED -------------------------------------------------------------------------------
dk_park; tab 2
[[ "$PT_TAB" == 2 ]] || fail "tab=$PT_TAB after clicking SPEED"
pc 19; tip $(( C_X0 + 3 )) $(( C_Y + 3 )); want 191 "SPEED SCALING"
tip $(( (SG_X0 + SG_X1) / 2 )) $(( (SG_Y0 + SG_Y1) / 2 )); want 421 "the SPEED > GAIN graph"
screenshot "pen-tip-speed-graph"
dk_park
tab 0
assert_no_crash
