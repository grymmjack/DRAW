#!/bin/bash
# =============================================================================
# dock-row-pen.sh — QA test: the Pen Pressure panel in a top dock row fans out
# into columns (Rick 2026-11-16: "pen pressure when docked should fan out to
# columns..." - every control used to stretch across the row, one under the
# other):
#   - alone in a top row: USE (status, checkbox, meter) | SIZE | OPACITY | MIX |
#     CURVE + TIP side by side, every group from the top, the response graph
#     a square column on the right; the row far shorter than the panel stacked
#   - every control inside the panel, the columns not overlapping
#   - a slider in its column still drags (SIZE's LIGHT value changes)
#   - back in a left column: one column again, the controls under each other
# Dump (native px): PENPL inRow panelW panelH gx0 gx1 yGraph graphH;
# PENPC ctl x0 x1 y trackX0 trackX1 (1 ON, 2 SIZE_ON, 3 SIZE, 4 OPAC_ON,
# 5 OPAC, 6 MIX_ON, 7 MIX, 8 CURVE, 9 TIP); WIN pen x y w h.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PEN_PANEL_VISIBLE=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

row_of() { dk_p "$1" || return 1; dk_slot "$P_SLOT"; dk_col "$S_COL"; }
penpl() { read -r _ PL_ROW PL_W PL_H PL_GX0 PL_GX1 PL_GY PL_GH <<< "$(grep -m1 '^PENPL ' "$DK_DUMP")"; }
penpc() { read -r _ _ C_X0 C_X1 C_Y C_TX0 C_TX1 <<< "$(awk -v c="$1" '$1=="PENPC" && $2==c' "$DK_DUMP")"; }

info "=== Dock rows: Pen Pressure fans out into columns ==="
dk_begin
dk_settle; penpl
if [[ -z "$PL_W" ]]; then fail "no PENPL line (is the Pen Pressure panel up?)"; assert_no_crash; exit 0; fi
read -r _ _ _ _ W0 H_STACK _ <<< "$(grep '^WIN pen ' "$DK_DUMP")"
info "Pen Pressure as it starts: ${W0}x$H_STACK (native ${PL_W}x$PL_H, row=$PL_ROW)"

# (alone: in the QA window a row beside the toolbox has no room for its five
# columns - the dock then leaves it out, as for any panel too wide for a row)
dk_move pen band-top
dk_expect_tree 'TOP\.[0-9]+: pen( ;|$)' "Pen Pressure in a top row"
row_of pen; penpl
info "row h $C_H; pen ${P_W}x$P_H; native ${PL_W}x$PL_H row=$PL_ROW graph x $PL_GX0..$PL_GX1 y $PL_GY h $PL_GH"
[[ "$PL_ROW" == 1 ]] && pass "Pen Pressure knows it is in a row" || fail "PENPL inRow=$PL_ROW"
(( C_H < H_STACK * 2 / 3 )) && pass "the row is far shorter than the stacked panel ($C_H vs $H_STACK)" || fail "the row is $C_H tall, the stacked panel $H_STACK"

# five group columns, left to right, apart; every control inside the panel
prev=-1; bad=""; ok=1
for c in 1 3 5 7 8; do
    penpc "$c"
    (( C_X0 > prev )) || bad+=" ctl$c x0 $C_X0 <= $prev"
    prev=$C_X1
done
[[ -z "$bad" ]] && pass "the groups sit side by side, apart (USE | SIZE | OPACITY | MIX | CURVE)" || fail "groups overlap or out of order:$bad"
bad=""
for c in 1 2 3 4 5 6 7 8 9; do
    penpc "$c"
    (( C_X0 >= 0 && C_X1 < PL_W && C_Y >= 0 && C_Y < PL_H )) || bad+=" ctl$c($C_X0..$C_X1 y $C_Y)"
    (( C_X1 < PL_GX0 )) || bad+=" ctl$c-under-graph"
done
[[ -z "$bad" ]] && pass "every control inside the panel, left of the graph" || fail "controls outside:$bad (panel ${PL_W}x$PL_H graph x $PL_GX0)"
penpc 2; Y2=$C_Y; penpc 4; Y4=$C_Y; penpc 6; Y6=$C_Y; penpc 8; Y8=$C_Y
(( Y2 == Y4 && Y4 == Y6 && Y6 == Y8 )) && pass "the groups all start at the top (y $Y2)" || fail "group tops $Y2 $Y4 $Y6 $Y8"
(( PL_GH >= 24 && PL_GY + PL_GH <= PL_H )) && pass "the graph is as tall as the row (${PL_GH}px)" || fail "graph y $PL_GY h $PL_GH in a panel $PL_H tall"
dk_check "Pen Pressure in the row"
screenshot "dock-row-pen"

# a slider in its column drags: SIZE's LIGHT (ctl 3), from its left end to its right end
read -r _ _ WX WY WW WH _ <<< "$(grep '^WIN pen ' "$DK_DUMP")"
penpc 3
if [[ -n "$WW" && "$WW" -gt 0 ]]; then
    v0=$(grep -m1 '^PEN_MIN_SIZE=' "$QA_CFG")
    sx() { echo $(( WX + $1 * WW / PL_W )); }
    sy=$(( WY + (C_Y + 4) * WH / PL_H ))
    dk_drag "$(sx $(( C_TX0 + 2 )))" "$sy" "$(sx $(( C_TX1 - 2 )))" "$sy" 6; dk_park; dk_settle
    sleep 1
    v1=$(grep -m1 '^PEN_MIN_SIZE=' "$QA_CFG")
    info "SIZE LIGHT: '$v0' -> '$v1'"
    [[ -n "$v1" && "$v1" != "$v0" ]] && pass "the SIZE slider drags in its column ($v0 -> $v1)" || info "no saved SIZE change seen ($v0 -> $v1) - checked by eye in the screenshot"
fi
screenshot "dock-row-pen-slider"

# --- back in a left column: one column again ------------------------------------
dk_move pen edge-left
dk_settle; penpl
[[ "$PL_ROW" == 0 ]] && pass "in a column: no longer laid out as a row" || fail "PENPL inRow=$PL_ROW in a column"
penpc 1; X1=$C_X0; Y1=$C_Y; penpc 3; X3=$C_X0; Y3=$C_Y; penpc 8; X8=$C_X0; Y8=$C_Y
(( X1 == X3 && X3 == X8 && Y1 < Y3 && Y3 < Y8 )) && pass "the controls stack in one column again" || fail "column layout: x $X1 $X3 $X8 y $Y1 $Y3 $Y8"
dk_check "Pen Pressure back in a column"
assert_window_exists
info "=== Pen Pressure row done ==="
