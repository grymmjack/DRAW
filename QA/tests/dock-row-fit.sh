#!/bin/bash
# =============================================================================
# dock-row-fit.sh — QA test: panels in a top / bottom dock row (Rick 2026-11-16)
#  1 the organizer beside the toolbox in a top row fits the row's height: the
#    stack tops side by side, each stack's last widget moved into a 2-row grid
#    to their right ("fit the height by stacking the stuff to the right") - the
#    row stays as tall as the toolbox alone
#  2 the edit bar in a row is one even grid: every column full but the last,
#    no column break at its dividers ("without breaks and weird columns")
#  3 a row slot's right edge drags its width along the row (saved as @px in
#    the tree); a double-click on the edge puts it back to auto
#  4 the drawer in a bottom row zooms: Ctrl+wheel sets the bin rows in the
#    row's height (DRAWER_ROW_BIN_ROWS)
#  5 the organizer alone in a top row, dragged down to one button high, lies
#    flat: every widget in one line, Opacity and Brush Size sideways
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt DRAWER_MINI_PALETTE=0
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

row_of() { dk_p "$1" || return 1; dk_slot "$P_SLOT"; dk_col "$S_COL"; }

info "=== Dock rows: organizer fit, bar grid, slot width, drawer zoom ==="
dk_begin

# --- 1: the organizer fits a top row beside the toolbox ----------------------
dk_move toolbox band-top
if row_of toolbox && (( C_SIDE == 3 )); then pass "toolbox in a top row (h $C_H)"; else fail "toolbox not in a top row [$(dk_tree)]"; fi
H0=$C_H
dk_move organizer right toolbox
dk_expect_tree 'TOP\.[0-9]+: toolbox \| organizer' "organizer beside the toolbox"
row_of organizer
if (( C_H == H0 )); then pass "the row keeps the toolbox's height ($C_H)"; else fail "the row grew $H0 -> $C_H for the organizer"; fi
dk_p organizer
bad=""; n=0
while read -r _ wi wx wy ww wh; do
    (( ww > 0 && wh > 0 )) || continue
    n=$(( n + 1 ))
    if (( wy < P_Y || wy + wh > P_Y + P_H || wx < P_X || wx + ww > P_X + P_W )); then bad+=" w$wi($wx,$wy ${ww}x$wh)"; fi
done < <(grep '^ORGW ' "$DK_DUMP")
if (( n >= 8 )) && [[ -z "$bad" ]]; then pass "all $n organizer widgets inside its rect ($P_X,$P_Y ${P_W}x$P_H)"; else fail "organizer widgets outside its rect ($P_X,$P_Y ${P_W}x$P_H):$bad (n $n)"; fi
dk_check "organizer in the row"
dk_seams "organizer in the row"

# --- 2: the edit bar is one even grid in the row -----------------------------
dk_move editbar right organizer
dk_expect_tree 'TOP\.[0-9]+: toolbox \| organizer \| editbar' "edit bar beside the organizer"
read -r nb cols rws <<< "$(awk '$1=="BTN" && $2=="editbar" && $9>0 {n++; xs[$7]=1; ys[$8]=1} END {c=0; for (k in xs) c++; r=0; for (k in ys) r++; print n+0, c, r}' "$DK_DUMP")"
info "edit bar: $nb buttons in $cols columns x $rws rows"
if (( nb > 0 && rws > 0 && cols == (nb + rws - 1) / rws )); then pass "one even grid: $nb buttons fill $cols columns of $rws"; else fail "edit bar grid: $nb buttons in $cols columns x $rws rows (want $(( (nb + rws - 1) / rws )) columns)"; fi

# --- 3: drag the edit bar's right edge -----------------------------------------
row_of editbar
W0=$S_W; EX=$(( S_X + S_W - 1 )); EY=$(( S_Y + S_H / 2 ))
dk_drag "$EX" "$EY" $(( EX + 40 )) "$EY"; dk_park; dk_settle
row_of editbar
if (( S_W >= W0 + 36 && S_W <= W0 + 44 )); then pass "edge drag: edit bar slot $W0 -> $S_W px"; else fail "edge drag: edit bar slot $W0 -> $S_W px (want ~$(( W0 + 40 )))"; fi
if grep -qE '^DOCK_TOP_[0-9]+=.*editbar@' "$QA_CFG"; then pass "saved: $(grep -E '^DOCK_TOP_[0-9]+=' "$QA_CFG")"; else fail "width not saved ($(grep -E '^DOCK_TOP_[0-9]+=' "$QA_CFG"))"; fi
EX=$(( S_X + S_W - 1 ))
double_click "$EX" "$EY"; dk_park; dk_settle
row_of editbar
if (( S_W == W0 )); then pass "double-click the edge: auto again ($S_W px)"; else fail "double-click: edit bar slot $S_W px, want $W0"; fi
dk_check "after the slot width"

# --- 4: the drawer zooms in a bottom row ---------------------------------------
dl_read() { read -r _ DL_COLS DL_ROWS DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX _ <<< "$(grep '^DRAWERL ' "$DK_DUMP")"; }
dk_move drawer band-bottom
if row_of drawer && (( C_SIDE == 4 )); then pass "drawer in a bottom row (h $C_H)"; else fail "drawer not in a bottom row [$(dk_tree)]"; fi
dl_read; B0=$DL_BW; V0=$DL_VIS
info "drawer: $DL_COLS cols, $DL_VIS rows of ${DL_BW}px"
BX=$(( DL_CX + DL_BW / 2 )); BY=$(( DL_CY + DL_BH / 2 ))
with_mods ctrl scroll_down "$BX" "$BY"; dk_park; dk_settle
dl_read
if (( DL_BW < B0 * 2 / 3 && DL_VIS == 2 )); then pass "Ctrl+wheel down: 2 rows of ${DL_BW}px (were $V0 of ${B0}px)"; else fail "Ctrl+wheel down: $DL_VIS rows of ${DL_BW}px (were $V0 of ${B0}px)"; fi
if grep -q '^DRAWER_ROW_BIN_ROWS=2' "$QA_CFG"; then pass "saved DRAWER_ROW_BIN_ROWS=2"; else fail "DRAWER_ROW_BIN_ROWS not saved ($(grep '^DRAWER_ROW_BIN_ROWS' "$QA_CFG"))"; fi
BX=$(( DL_CX + DL_BW / 2 )); BY=$(( DL_CY + DL_BH / 2 ))
with_mods ctrl scroll_up "$BX" "$BY"; dk_park; dk_settle
dl_read
if (( DL_BW == B0 )); then pass "Ctrl+wheel up: bins back to ${DL_BW}px"; else fail "Ctrl+wheel up: bins ${DL_BW}px, want $B0"; fi
dk_check "drawer in the row"

# --- 5: down to one button high: the organizer lies flat, Opacity and Brush
#     Size turned sideways ("get down to 1 button in this bar") ---------------
# (alone in the row: in the QA window a one-row toolbox takes the whole width)
dk_move toolbox edge-left; dk_move editbar edge-left
dk_expect_tree 'TOP\.[0-9]+: organizer( ;|$)' "the organizer alone in the top row"
row_of organizer; H0=$C_H
EX=$(( C_X + C_W / 2 )); EY=$(( C_Y + C_H - 1 )) # (a top row's edge zone: its last 3 px + 1 below)
if (( H0 > 30 )); then
    dk_drag "$EX" "$EY" "$EX" $(( EY - 80 )) 5; dk_park; dk_settle
    row_of organizer
    info "row after the edge drag up: $H0 -> $C_H"
    if (( C_H < H0 * 2 / 3 )); then pass "the row shrinks to $C_H (was $H0)"; else fail "the row is still $C_H tall (was $H0)"; fi
else
    pass "alone, the row is already one button high ($H0)"
fi
dk_p organizer
bad=""; n=0; flat=""
while read -r _ wi wx wy ww wh; do
    (( ww > 0 && wh > 0 )) || continue
    n=$(( n + 1 ))
    if (( wy < P_Y || wy + wh > P_Y + P_H || wx < P_X || wx + ww > P_X + P_W )); then bad+=" w$wi($wx,$wy ${ww}x$wh)"; fi
    if (( wi == 1 || wi == 2 )) && (( ww <= wh )); then flat+=" w$wi(${ww}x$wh)"; fi
done < <(grep '^ORGW ' "$DK_DUMP")
if (( n >= 8 )) && [[ -z "$bad" ]]; then pass "one line: all $n widgets inside its rect ($P_X,$P_Y ${P_W}x$P_H)"; else fail "one line: widgets outside its rect ($P_X,$P_Y ${P_W}x$P_H):$bad (n $n)"; fi
if [[ -z "$flat" ]]; then pass "Opacity and Brush Size lie sideways (wider than tall)"; else fail "not sideways:$flat"; fi
screenshot "dock-row-organizer-flat"
dk_check "organizer one button high"
# back to the toolbox's height: drag the edge down by what it went up
row_of organizer; EY=$(( C_Y + C_H - 1 ))
dk_drag "$EX" "$EY" "$EX" $(( EY + H0 - C_H )) 5; dk_park; dk_settle
row_of organizer
info "row after the edge drag down: $C_H"

screenshot "dock-row-fit"
assert_window_exists
info "=== Dock row fit done ==="
