#!/bin/bash
# =============================================================================
# dock-textbar.sh — QA test: the text tool's bar is a dock panel (Rick
# 2026-11-16: "should be scaleable, like the other panels" + "it should be
# dockable left, right, top, bottom etc."):
#   - with the text tool it is a top row of its own (where the fixed strip was);
#     with another tool it is gone and the row with it
#   - in a left column: as wide as the column, its controls wrapped into more
#     lines, the bar as tall as they are; the font button still opens its list
#   - floating: a window as tall as its lines
#   - in a bottom row: its lists open upward
#   - back in a top row; at its own Scale (3x, the viewport's is 2): its rect
#     in units, the font list opens from the scaled button
# Dump: P textbar ...; TEXTBAR vis x y w h topbarH fontBtnX fontBtnW lines
# fontLineY aaLineY aaX (units: viewport px at Auto); PSURF id -1 k vx vy vw vh
# uw uh ready; POPUP textbar x y w h.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14 # THEME.TEXT_BAR_ROW_HEIGHT (the stock theme)
tb_read() { read -r _ T_ON T_X T_Y T_W T_H _ T_FX T_FW T_LN T_FY T_AY T_AX _ <<< "$(grep -m1 '^TEXTBAR ' "$DK_DUMP")"; }
tb_inside() { # every control inside the bar: the AA button (the last) in its width, on its last line
    local why=""
    (( T_AX >= T_X && T_AX < T_X + T_W )) || why+=" AA x $T_AX not in $T_X..$(( T_X + T_W ))"
    # (+1: in a bottom row its lines start one below the row's seam, its first pixel row)
    (( T_AY >= T_Y && T_AY + ROW_H <= T_Y + T_H + 1 )) || why+=" AA line $T_AY not in $T_Y..$(( T_Y + T_H ))"
    (( T_H == T_LN * ROW_H )) || why+=" h $T_H != $T_LN lines"
    [[ -z "$why" ]] && pass "$1: every control inside the bar ($T_LN lines, ${T_W}x$T_H)" || fail "$1:$why"
}
popup_textbar() { read -r _ _ PX PY PW PH _ <<< "$(grep -m1 '^POPUP textbar ' "$DK_DUMP")"; [[ -n "$PW" ]]; }

info "=== Dock: the text bar as a dock panel ==="
dk_begin

# --- the text tool: a top row of its own -----------------------------------------
key t; wait_for 0.6 "text tool"; dk_park; dk_settle; tb_read
[[ -n "$T_ON" && "$T_ON" != 0 ]] && pass "the text bar shows with the text tool" || { fail "no text bar (TEXTBAR: $(grep -m1 '^TEXTBAR ' "$DK_DUMP"))"; assert_no_crash; exit 0; }
dk_p textbar; dk_slot "$P_SLOT"; dk_col "$S_COL"
(( P_SLOT > 0 && C_SIDE == 3 )) && pass "a top row (y $C_Y h $C_H)" || fail "not in a top row (slot $P_SLOT side $C_SIDE) [$(dk_tree)]"
(( T_Y >= 12 && T_Y <= 14 )) && pass "under the menu bar, where the strip was (y $T_Y)" || fail "text bar y $T_Y"
tb_inside "in the top row"
W_ROW=$T_W; L_ROW=$T_LN
screenshot "textbar-row"
key b; wait_for 0.6 "brush"; dk_park; dk_settle; dk_rows; tb_read
dk_p textbar
(( T_ON == 0 && P_SHOWN == 0 )) && pass "another tool: the bar is gone" || fail "brush tool: TEXTBAR on=$T_ON shown=$P_SHOWN"
(( R_TOPH == 0 )) && pass "... and its row with it (rows top h 0)" || fail "the top rows still $R_TOPH tall without the text bar"
key t; wait_for 0.6 "text tool"; dk_park; dk_settle
dk_check "the text bar in its row"

# --- a left column: wrapped into more lines -----------------------------------------
dk_move textbar edge-left
dk_p textbar; dk_slot "$P_SLOT"; dk_col "$S_COL"; tb_read
info "column: side $C_SIDE w $C_W; bar ${T_W}x$T_H lines $T_LN (row: $L_ROW lines, $W_ROW wide)"
(( C_SIDE == 1 )) && pass "in a left column" || fail "not in a left column [$(dk_tree)]"
(( T_W < W_ROW && T_LN > L_ROW )) && pass "narrower, more lines ($L_ROW -> $T_LN)" || fail "column: w $T_W lines $T_LN (row $W_ROW / $L_ROW)"
tb_inside "in the column"
screenshot "textbar-column"
click $(( T_FX + T_FW / 2 )) $(( T_FY + 6 )); wait_for 0.8 "font list"; dk_settle
popup_textbar && pass "the font button opens its list in the column (at $PX,$PY)" || fail "no font list from the column ($(grep '^POPUP' "$DK_DUMP" | tr '\n' ' '))"
screenshot "textbar-column-fontlist"
key Escape; wait_for 0.4 "closed"; dk_park; dk_settle
dk_check "the text bar in a column"

# --- floating -----------------------------------------------------------------
dk_move textbar float
dk_p textbar; tb_read
(( P_FL != 0 )) && pass "floating (${P_FW}x$P_FH)" || fail "not floating [$(dk_tree)]"
tb_inside "floating"
(( P_FH <= T_H + 12 )) && pass "the window as tall as its lines (window $P_FH, bar $T_H)" || fail "floating window $P_FH tall for a bar $T_H tall"
screenshot "textbar-float"
dk_check "the text bar floating"

# --- a bottom row: its lists open upward (toward the canvas) -----------------------
dk_move textbar band-bottom
dk_p textbar; dk_slot "$P_SLOT"; dk_col "$S_COL"; tb_read
(( C_SIDE == 4 )) && pass "in a bottom row (y $T_Y)" || fail "not in a bottom row [$(dk_tree)]"
tb_inside "in the bottom row"
click $(( T_FX + T_FW / 2 )) $(( T_FY + 6 )); wait_for 0.8 "font list"; dk_settle
if popup_textbar; then
    (( PY + PH <= T_FY + 1 && PY >= 0 )) && pass "the font list opens upward, above the bar ($PY..$(( PY + PH )), the bar at $T_FY)" || fail "font list $PY..$(( PY + PH )) from a bottom bar at $T_FY"
else
    fail "no font list from the bottom row"
fi
screenshot "textbar-bottom-fontlist"
key Escape; wait_for 0.4 "closed"; dk_park; dk_settle
dk_check "the text bar in a bottom row"

# --- back in a top row, at its own Scale ------------------------------------------
dk_move textbar band-top
dk_p textbar; dk_slot "$P_SLOT"; dk_col "$S_COL"; tb_read
(( C_SIDE == 3 )) && pass "back in a top row" || fail "not back in a top row [$(dk_tree)]"
dk_rmenu textbar
if (( M_OPEN != 0 )) && dk_menu_has 23; then
    dk_pick 23 "Scale: 3x"
    tb_read
    read -r _ _ _ PK PVX PVY PVW PVH PUW PUH PRDY <<< "$(grep -m1 '^PSURF 9 ' "$DK_DUMP")"
    info "at 3x: PSURF k $PK footprint $PVX,$PVY ${PVW}x$PVH units ${PUW}x$PUH; bar ${T_W}x$T_H lines $T_LN"
    [[ "$PK" == 3 && "$PRDY" != 0 ]] && pass "drawn into its own surface at 3x" || fail "no 3x surface (PSURF: $(grep '^PSURF 9 ' "$DK_DUMP"))"
    (( T_W == PUW )) && pass "it lays out in its units (${T_W} = ${PUW})" || fail "bar w $T_W, surface units $PUW"
    tb_inside "at 3x"
    screenshot "textbar-3x"
    # the font button: units -> viewport (x 3 / 2 from the footprint's corner)
    FX=$(( PVX + (T_FX + T_FW / 2 - PVX) * 3 / 2 )); FY=$(( PVY + (T_FY + 6 - PVY) * 3 / 2 ))
    FL=$(( PVX + (T_FX - PVX) * 3 / 2 )) # the scaled button's left edge: the list starts there
    click "$FX" "$FY"; wait_for 0.8 "font list"; dk_settle
    if popup_textbar; then
        info "font list at $PX,$PY ${PW}x$PH"
        (( PX >= FL - 3 && PX <= FL + 3 && PY >= FY )) && pass "the font list opens under the scaled button ($PX,$PY; button from $FL)" || fail "font list at $PX,$PY, the button from $FL (centre $FX,$FY)"
        snap_region "$PX" "$PY" "$PW" "$PH" "fontlist-3x"
        N=$(convert "$SNAP_RESULT" -format %k info: 2>/dev/null)
        (( N > 2 )) && pass "the list is drawn there ($N colours)" || fail "the list's box is blank ($N colours)"
    else
        fail "no font list from the scaled button ($(grep '^POPUP' "$DK_DUMP" | tr '\n' ' '))"
    fi
    screenshot "textbar-3x-fontlist"
    key Escape; wait_for 0.4 "closed"; dk_park; dk_settle
    dk_rmenu textbar; dk_pick 20 "Scale: Auto"
else
    fail "no Scale 3x in the text bar's handle menu (open $M_OPEN)"
    key Escape
fi
dk_check "the text bar at the end"
assert_window_exists
info "=== Dock: text bar panel done ==="
