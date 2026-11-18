#!/bin/bash
# =============================================================================
# dock-rows.sh — QA test: the top / bottom docks (rows of panels, 2026-11-16).
# Rick: "can we allow the toolbox to dock to top/bottom - and also the editbar,
# advanced bar? and organizer, and drawer? ... multiple things docked to top
# arrange them above/below each other, side by side if it fits ... for bottom
# it would appear above the color strip".
#   menu      Toolbox handle menu > Dock Along the Top: a top row, wide and short
#   beside    Edit Bar dropped on the toolbox's right third: beside it, sideways
#   bottom    Advanced Bar to the bottom edge: a bottom row, the canvas shifts
#   left      Organizer dropped on the toolbox's left third: before it
#   height    drag the top row's inner edge down: taller (HEIGHT: saved), the
#             toolbox reflows to fewer columns
#   new row   Drawer below the top row (its inner edge zone): a second top row
#   full      DOCK_ROWSPAN=FULL (Settings > Panels > Top/Bottom Docks) +
#             restart: the rows span the window, the side columns between them
#   back      Toolbox to the left edge again; a short fuzz with rows in it
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: top / bottom rows Test ==="
dk_begin
dk_check "start"

# --- the handle menu: Dock Along the Top (DOCK_ACT_BAND_TOP = 7) -------------
dk_rmenu toolbox
if [[ "$M_OPEN" == -1 ]] && dk_menu_has 7 && dk_menu_has 8; then pass "toolbox menu offers Dock Along the Top / Bottom"; else fail "toolbox menu: open '$M_OPEN', rows: $(grep '^DMENUR' "$DK_DUMP" | awk '{print $3}' | paste -sd,)"; fi
dk_pick 7 "Dock Along the Top"
dk_expect_row toolbox 3
dk_p toolbox
if (( P_W > P_H * 2 )); then pass "toolbox in a row is wide and short (${P_W}x$P_H)"; else fail "toolbox in a row: ${P_W}x$P_H"; fi
grep -qE '^DOCK_TOP_[0-9]+=.*toolbox' "$QA_CFG" && pass "saved as DOCK_TOP_1" || fail "no DOCK_TOP_1 with the toolbox: $(grep '^DOCK_' "$QA_CFG" | paste -sd' ')"
dk_check "toolbox along the top"
screenshot "dock-rows-toolbox-top"

# --- beside it: the edit bar, sideways ------------------------------------------
dk_move_expect editbar right toolbox
dk_p editbar
if (( P_W > P_H )); then pass "edit bar in a row lies sideways (${P_W}x$P_H)"; else fail "edit bar in a row: ${P_W}x$P_H"; fi
dk_check "edit bar beside the toolbox"

# --- the bottom row -------------------------------------------------------------
dk_move_expect advbar band-bottom
dk_check "advanced bar along the bottom"
dk_rows
if (( R_TOPH > 0 && R_BOTH > 0 )); then pass "rows top ${R_TOPH}px + bottom ${R_BOTH}px"; else fail "rows: top $R_TOPH bottom $R_BOTH"; fi
screenshot "dock-rows-bottom"

dk_move_expect organizer left toolbox
dk_check "organizer before the toolbox"

# --- the row's height by its inner edge -------------------------------------------
dk_p toolbox; W0=$P_W
TC=$(awk '$1=="COL" && $3==3 && $4==1 {print $2; exit}' "$DK_DUMP"); dk_col "$TC"; H0=$C_H
EX=$(( C_X + C_W - 30 )); EY=$(( C_Y + C_H - 1 ))
dk_drag "$EX" "$EY" "$EX" $(( EY + 40 )) 5; dk_park; dk_settle
dk_col "$TC"; dk_p toolbox
if (( C_H >= H0 + 30 )); then pass "top row taller by its edge ($H0 -> $C_H)"; else fail "row edge drag: $H0 -> $C_H"; fi
if (( P_W < W0 )); then pass "the toolbox reflows narrower in the taller row ($W0 -> $P_W)"; else fail "toolbox width $W0 -> $P_W in a taller row"; fi
grep -qE "^DOCK_TOP_[0-9]+=HEIGHT:$C_H;" "$QA_CFG" && pass "row height saved (HEIGHT:$C_H)" || fail "row height not saved: $(grep -E '^DOCK_TOP_[0-9]+=' "$QA_CFG")"
dk_check "top row resized"

# --- a second top row, under the first -----------------------------------------
dk_move_expect drawer band-top
TOPN=$(awk '$1=="COL" && $3==3 && $9!=0' "$DK_DUMP" | wc -l)
(( TOPN == 2 )) && pass "two top rows" || fail "$TOPN top rows [$(dk_tree)]"
dk_check "drawer in a second top row"
screenshot "dock-rows-two-top"

# --- full width (saved with the arrangement) -------------------------------------
draw_quit
echo "DOCK_ROWSPAN=FULL" >> "$QA_CFG"
rm -f "$DK_DUMP"
draw_launch 15
dk_begin
dk_rows; dk_scr
TC=$(awk '$1=="COL" && $3==3 && $4==1 {print $2; exit}' "$DK_DUMP"); dk_col "$TC"
if (( R_FULL != 0 && C_X == 0 && C_W == SCR_W )); then pass "full width: the top row spans the window (0..$C_W)"; else fail "full width: ROWS full=$R_FULL, row x $C_X w $C_W (screen $SCR_W)"; fi
LC=$(awk '$1=="COL" && $3==2 && $9!=0 {print $2; exit}' "$DK_DUMP")
if [[ -n "$LC" ]]; then
    dk_col "$LC"
    if (( C_Y >= R_Y1 - 1 && C_Y + C_H - 1 <= R_Y2 + 1 )); then pass "a side column sits between the rows (y $C_Y..$(( C_Y + C_H - 1 )), rows end $R_Y1 / start $R_Y2)"; else fail "side column y $C_Y h $C_H overlaps the rows ($R_Y1..$R_Y2)"; fi
fi
grep -q '^DOCK_ROWSPAN=FULL' "$QA_CFG" && pass "ROWSPAN kept" || fail "ROWSPAN lost on save"
dk_check "full width after restart"
screenshot "dock-rows-full"

# --- back to the side ---------------------------------------------------------------
dk_move_expect toolbox edge-left
dk_check "toolbox back on the left"
dk_fuzz 11 6 toolbox editbar advbar organizer layers
assert_window_exists
info "=== Dock: top / bottom rows Test PASSED ==="
