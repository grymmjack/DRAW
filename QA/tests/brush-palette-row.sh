#!/bin/bash
# =============================================================================
# brush-palette-row.sh — QA test: the brush palette docked as a wide row along the bottom
# (Rick 2026-11-18: "that can be docked down to 1 column, 2 columns, tall, wide, whatever").
#   1. in a bottom row its grid goes wide: many columns, few rows, inside the panel
#   2. its sliders sit side by side, not stacked
#   3. a cell click still sets the size
# Dump: BSP vis x y w h cell cols rowsFit rowsAll scroll gridX gridY hover shape soft size;
# BSPS id x y w lw vw.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BRUSH_PANEL=TRUE BRUSH_PANEL_SCALE=0 BRUSH_PANEL_CELL=28 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;layers DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_2=AUTO;advbar DOCK_BOTTOM_1=AUTO;brushes
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

bsp_read() { dk_settle; read -r _ P_VIS P_X P_Y P_W P_H P_CELL P_COLS P_RF P_RA P_SC P_GX P_GY P_HOV P_SHAPE P_SOFT P_SIZE <<< "$(grep -m1 '^BSP ' "$DK_DUMP")"; }

info "=== Brush palette in a bottom row ==="
dk_begin
bsp_read
info "BSP: ${P_W}x$P_H at $P_X,$P_Y - $P_COLS cols x $P_RA rows ($P_RF fit), cell $P_CELL"
(( P_VIS != 0 && P_W > P_H * 2 )) && pass "the palette shows as a wide row (${P_W}x$P_H)" || fail "not a wide row: vis '$P_VIS' ${P_W}x$P_H"
(( P_COLS >= 8 && P_RA <= 4 )) && pass "the grid goes wide: $P_COLS columns, $P_RA rows" || fail "grid $P_COLS cols x $P_RA rows"
(( P_GX + P_COLS * (P_CELL + 2) <= P_X + P_W + 2 && P_GY + P_RF * (P_CELL + 2) <= P_Y + P_H + 2 )) && pass "the shown cells are inside the panel" || fail "grid at $P_GX,$P_GY ($P_COLS x $P_RF of $P_CELL) leaves the panel $P_X,$P_Y ${P_W}x$P_H"
read -r _ _ S1X S1Y _ <<< "$(grep -m1 '^BSPS 10 ' "$DK_DUMP")"; read -r _ _ S2X S2Y _ <<< "$(grep -m1 '^BSPS 11 ' "$DK_DUMP")"
(( S1Y == S2Y && S2X > S1X )) && pass "SIZE and SOFT side by side" || fail "sliders at $S1X,$S1Y and $S2X,$S2Y"
screenshot "brush-palette-row"
key b; wait_for 0.3 "brush tool"
bsp_read
c=3; r=$(( 0 - P_SC ))
(( r >= 0 )) || r=0
click $(( P_GX + c * (P_CELL + 2) + P_CELL / 2 )) $(( P_GY + r * (P_CELL + 2) + P_CELL / 2 )); wait_for 0.5 "cell 4"; dk_park
bsp_read
(( P_SIZE == 4 )) && pass "a cell click in the row: size 4" || fail "after the cell click: size $P_SIZE (want 4)"
assert_no_crash
