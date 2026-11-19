#!/bin/bash
# =============================================================================
# brush-palette-float.sh — QA test: the brush palette floating narrow and tall: one column
# of thumbnails (Rick 2026-11-18: "docked down to 1 column, 2 columns, tall, wide").
#   1. a 64-wide float (its minimum): a column or two, its cells inside the window, the sliders stacked
#   2. the wheel over the grid scrolls it (more sizes than fit)
#   3. the cells stretch to fill the width (Rick 2026-11-18: "the brushes should resize/tile
#      to fit the width if possible" - a 64-wide float left half of it blank)
#   4. 51 sizes, 1 .. 101 px ("we should have bigger brushes than that ... up to 100 at least")
#   5. dropped into a new dock column it keeps the narrow width it floated at (Rick
#      2026-11-18: "i have the bar resized tiny, but when i dock it, it's much wider")
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BRUSH_PANEL=TRUE BRUSH_PANEL_SCALE=0 BRUSH_PANEL_CELL=28 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;layers DOCK_LEFT_2=AUTO;editbar DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_2=AUTO;advbar DOCK_FLOAT_BRUSHES=420,40,40,420
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

bsp_read() { dk_settle; read -r _ P_VIS P_X P_Y P_W P_H P_CELL P_COLS P_RF P_RA P_SC P_GX P_GY P_HOV P_SHAPE P_SOFT P_SIZE <<< "$(grep -m1 '^BSP ' "$DK_DUMP")"; }

info "=== Brush palette floating narrow ==="
dk_begin
bsp_read
info "BSP: ${P_W}x$P_H at $P_X,$P_Y - $P_COLS cols x $P_RA rows ($P_RF fit), cell $P_CELL"
(( P_VIS != 0 && P_H > P_W * 2 )) && pass "the palette floats tall and narrow (${P_W}x$P_H)" || fail "not tall: vis '$P_VIS' ${P_W}x$P_H"
(( P_COLS >= 1 && P_COLS <= 2 )) && pass "one or two narrow columns of sizes ($P_COLS)" || fail "$P_COLS columns (want 1 or 2)"
(( P_GX >= P_X && P_GX + P_CELL <= P_X + P_W + 1 )) && pass "the column is inside the window" || fail "cells at x $P_GX (cell $P_CELL), window $P_X w $P_W"
read -r _ _ S1X S1Y _ <<< "$(grep -m1 '^BSPS 10 ' "$DK_DUMP")"; read -r _ _ S2X S2Y _ <<< "$(grep -m1 '^BSPS 11 ' "$DK_DUMP")"
(( S2Y > S1Y )) && pass "SIZE and SOFT stacked" || fail "sliders at $S1X,$S1Y and $S2X,$S2Y"
LEFT=$(( P_W - 8 - (P_COLS * (P_CELL + 2) - 2) ))
(( LEFT >= 0 && LEFT <= P_COLS )) && pass "the cells fill the width ($P_COLS x $P_CELL in $P_W, $LEFT left over)" || fail "cells $P_COLS x $P_CELL leave $LEFT of $P_W"
(( P_RA * P_COLS >= 51 && P_RA * P_COLS < 51 + P_COLS )) && pass "51 sizes ($P_RA rows of $P_COLS)" || fail "$P_RA rows of $P_COLS (want 51 sizes)"
screenshot "brush-palette-float"
SC0=$P_SC
if (( P_RA > P_RF )); then
    scroll_down $(( P_GX + P_CELL / 2 )) $(( P_GY + P_CELL / 2 )); wait_for 0.4 "scroll"
    bsp_read
    (( P_SC > SC0 )) && pass "the wheel scrolls the column ($SC0 -> $P_SC)" || fail "no scroll: $SC0 -> $P_SC"
else
    fail "all $P_RA rows fit a 420-tall window ($P_RF) - nothing to scroll"
fi
W_FL=$P_W
dk_move brushes newcol layers
if dk_docked brushes; then
    pass "dropped into a new column: docked"
    bsp_read
    (( P_W >= W_FL - 4 && P_W <= W_FL + 4 )) && pass "the column keeps its floating width ($W_FL -> $P_W, not the 160 it asks)" || fail "docked ${P_W} wide (floated $W_FL)"
    screenshot "brush-palette-float-docked"
else
    fail "not docked after the drop [$(grep -m1 '^P brushes ' "$DK_DUMP")]"
fi
assert_no_crash
