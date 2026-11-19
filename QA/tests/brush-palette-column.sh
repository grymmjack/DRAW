#!/bin/bash
# =============================================================================
# brush-palette-column.sh — QA test: the brush palette alone in a dock column can be
# narrower than the width it asks (Rick 2026-11-18: "here i have the bar resized tiny,
# but when i dock it, it's much wider -- why?" / "CANNOT SHRINK"). A column holding only
# panels that stretch (DOCK_col_min_w%) takes an own WIDTH down to their minimum.
#   1. WIDTH:110 (under BSP_COL_W 160): the column and the palette are 110 wide
#   2. its cells still fill that width, the sliders stacked
# Dump: BSP vis x y w h cell cols rowsFit rowsAll scroll gridX gridY hover shape soft size.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE BRUSH_PANEL=TRUE BRUSH_PANEL_SCALE=0 BRUSH_PANEL_CELL=28 DOCK_CUSTOM=1 DOCK_LEFT_1=WIDTH:110;brushes DOCK_LEFT_2=AUTO;layers DOCK_LEFT_3=AUTO;editbar DOCK_RIGHT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_2=AUTO;advbar
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

bsp_read() { dk_settle; read -r _ P_VIS P_X P_Y P_W P_H P_CELL P_COLS P_RF P_RA P_SC P_GX P_GY P_HOV P_SHAPE P_SOFT P_SIZE <<< "$(grep -m1 '^BSP ' "$DK_DUMP")"; }

info "=== Brush palette alone in a narrow column ==="
dk_begin
bsp_read
info "BSP: ${P_W}x$P_H at $P_X,$P_Y - $P_COLS cols x $P_RA rows ($P_RF fit), cell $P_CELL"
(( P_VIS != 0 )) && pass "the palette shows" || fail "not shown (BSP '$P_VIS')"
(( P_W >= 100 && P_W <= 112 )) && pass "the column keeps its own 110 width, under the 160 it asks (${P_W})" || fail "palette ${P_W} wide (want ~110: a stretch-only column may go under its natural width)"
LEFT=$(( P_W - 8 - (P_COLS * (P_CELL + 2) - 2) ))
(( LEFT >= 0 && LEFT <= P_COLS )) && pass "the cells fill the width ($P_COLS x $P_CELL, $LEFT left over)" || fail "cells $P_COLS x $P_CELL leave $LEFT of $P_W"
read -r _ _ S1X S1Y _ <<< "$(grep -m1 '^BSPS 10 ' "$DK_DUMP")"; read -r _ _ S2X S2Y _ <<< "$(grep -m1 '^BSPS 11 ' "$DK_DUMP")"
(( S2Y > S1Y )) && pass "SIZE and SOFT stacked" || fail "sliders at $S1X,$S1Y and $S2X,$S2Y"
screenshot "brush-palette-column"
assert_no_crash
