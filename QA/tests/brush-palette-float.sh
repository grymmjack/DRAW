#!/bin/bash
# =============================================================================
# brush-palette-float.sh — QA test: the brush palette floating narrow and tall: one column
# of thumbnails (Rick 2026-11-18: "docked down to 1 column, 2 columns, tall, wide").
#   1. a 48-wide float: one column, its cells inside the window, the sliders stacked
#   2. the wheel over the grid scrolls it (more sizes than fit)
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BRUSH_PANEL=TRUE BRUSH_PANEL_SCALE=0 BRUSH_PANEL_CELL=28 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;layers DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_2=AUTO;advbar DOCK_FLOAT_BRUSHES=420,40,40,420
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

bsp_read() { dk_settle; read -r _ P_VIS P_X P_Y P_W P_H P_CELL P_COLS P_RF P_RA P_SC P_GX P_GY P_HOV P_SHAPE P_SOFT P_SIZE <<< "$(grep -m1 '^BSP ' "$DK_DUMP")"; }

info "=== Brush palette floating, one column ==="
dk_begin
bsp_read
info "BSP: ${P_W}x$P_H at $P_X,$P_Y - $P_COLS cols x $P_RA rows ($P_RF fit), cell $P_CELL"
(( P_VIS != 0 && P_H > P_W * 2 )) && pass "the palette floats tall and narrow (${P_W}x$P_H)" || fail "not tall: vis '$P_VIS' ${P_W}x$P_H"
(( P_COLS == 1 )) && pass "one column of sizes" || fail "$P_COLS columns (want 1)"
(( P_GX >= P_X && P_GX + P_CELL <= P_X + P_W + 1 )) && pass "the column is inside the window" || fail "cells at x $P_GX (cell $P_CELL), window $P_X w $P_W"
read -r _ _ S1X S1Y _ <<< "$(grep -m1 '^BSPS 10 ' "$DK_DUMP")"; read -r _ _ S2X S2Y _ <<< "$(grep -m1 '^BSPS 11 ' "$DK_DUMP")"
(( S2Y > S1Y )) && pass "SIZE and SOFT stacked" || fail "sliders at $S1X,$S1Y and $S2X,$S2Y"
screenshot "brush-palette-float"
SC0=$P_SC
if (( P_RA > P_RF )); then
    scroll_down $(( P_GX + P_CELL / 2 )) $(( P_GY + P_CELL / 2 )); wait_for 0.4 "scroll"
    bsp_read
    (( P_SC > SC0 )) && pass "the wheel scrolls the column ($SC0 -> $P_SC)" || fail "no scroll: $SC0 -> $P_SC"
else
    fail "all $P_RA rows fit a 420-tall window ($P_RF) - nothing to scroll"
fi
assert_no_crash
