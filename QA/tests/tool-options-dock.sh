#!/bin/bash
# =============================================================================
# tool-options-dock.sh — QA test: the Tool Options bar as a dock panel
# (PLANS/TOOL-OPTIONS-BAR.md decisions: "a normal dock panel: top / bottom / left / right /
# float, as a row or a column ... no dead gaps ... correct at display scales"):
#   - the brush's options in the top row; in a left column, a right column, a bottom row
#     and floating: every control inside the bar, the bar exactly as tall as its lines
#     (no dead gap, nothing scrolled), narrower places take more lines
#   - a control still works in each place (the AA toggle flips CFG.ANTIALIAS)
#   - at its own Scale 3x: laid out in its units, a click on the scaled AA toggle lands
#   - the Text Bar is the text tool's options (phase 2): moved with Tool Options - the
#     text tool shows it where Tool Options was (left column, floating, at its Scale)
# Dump: P selbar ...; SELBAR vis x y w h lines ... tool; SELBARV scroll contentH;
# SELBARP size px shape soft opacity pp aa sym; SELBARC id x y w trackX; PSURF 10 ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_BAR=TRUE ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
text_follows() { # the text tool: the Text Bar where Tool Options is ($1 = what, $2 = side / float)
    key t; wait_for 0.6 "text tool"; dk_park; dk_settle; sb_read
    dk_p textbar
    if [[ "$2" == float ]]; then
        (( P_FL != 0 )) && pass "$1: the Text Bar floats there too" || fail "$1: the Text Bar not floating [$(dk_tree)]"
    else
        dk_slot "$P_SLOT"; dk_col "$S_COL"
        (( P_SHOWN != 0 && C_SIDE == $2 )) && pass "$1: the Text Bar shows there (side $C_SIDE)" || fail "$1: Text Bar shown $P_SHOWN side $C_SIDE [$(dk_tree)]"
    fi
    (( S_ON == 0 )) || fail "$1: Tool Options still shown with the text tool"
    dk_check "$1, the text tool"
    key b; wait_for 0.6 "brush"; dk_park; dk_settle; sb_read
}

ROW_H=14 # THEME.TEXT_BAR_ROW_HEIGHT (the stock theme)
ID_AA=33

sb_read() {
    read -r _ S_ON S_X S_Y S_W S_H S_LN _ _ _ _ _ _ _ _ _ _ _ _ S_TOOL _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"
    read -r _ V_SCROLL V_CH _ <<< "$(grep -m1 '^SELBARV ' "$DK_DUMP")"
    read -r _ _ _ _ _ _ _ P_AA _ <<< "$(grep -m1 '^SELBARP ' "$DK_DUMP")"
}
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
sb_fits() { # every control inside; exactly as tall as its lines; nothing scrolled
    local why="" id x y w tx
    while read -r _ id x y w tx; do
        (( x >= S_X && x + w <= S_X + S_W && y >= S_Y && y + ROW_H <= S_Y + S_H + 1 )) || why+=" control $id at $x,$y w $w"
    done < <(grep '^SELBARC ' "$DK_DUMP")
    (( V_SCROLL == 0 )) || why+=" scrolled $V_SCROLL"
    (( S_H == S_LN * ROW_H )) || why+=" h $S_H for $S_LN lines (dead gap or cut)"
    (( V_CH == S_LN * ROW_H )) || why+=" content $V_CH for $S_LN lines"
    [[ -z "$why" ]] && pass "$1: every control inside, ${S_W}x$S_H = $S_LN lines" || fail "$1:$why"
}
aa_works() { # the AA toggle on the bar (viewport px, or scaled from the footprint by $2/$3)
    local before=$P_AA mul=${2:-1} div=${3:-1} ax ay
    if ! sbc $ID_AA; then fail "$1: no AA toggle"; return; fi
    ax=$(( C_X + C_W / 2 )); ay=$(( C_Y + ROW_H / 2 ))
    if (( mul != div )); then ax=$(( PVX + (ax - PVX) * mul / div )); ay=$(( PVY + (ay - PVY) * mul / div )); fi
    click "$ax" "$ay"; wait_for 0.4 "AA"; dk_park; dk_settle; sb_read
    [[ "$P_AA" != "$before" ]] && pass "$1: the AA toggle works ($before -> $P_AA)" || fail "$1: AA toggle at $ax,$ay did nothing ($before)"
    click "$ax" "$ay"; wait_for 0.4 "AA back"; dk_park; dk_settle; sb_read
}

info "=== Tool Options: docking and scale ==="
dk_begin

key b; wait_for 0.6 "brush"; dk_park; dk_settle; sb_read
(( S_ON != 0 )) && pass "the brush shows Tool Options" || { fail "no Tool Options bar"; assert_no_crash; exit 0; }
dk_p selbar; dk_slot "$P_SLOT"; dk_col "$S_COL"
(( P_SLOT > 0 && C_SIDE == 3 )) && pass "a top row" || fail "not in a top row (slot $P_SLOT side $C_SIDE) [$(dk_tree)]"
sb_fits "top row"; W_ROW=$S_W; L_ROW=$S_LN
aa_works "top row"
screenshot "topt-dock-row"

dk_move selbar edge-left
dk_p selbar; dk_slot "$P_SLOT"; dk_col "$S_COL"; sb_read
(( C_SIDE == 1 )) && pass "in a left column" || fail "not in a left column [$(dk_tree)]"
(( S_W < W_ROW && S_LN > L_ROW )) && pass "narrower, more lines ($L_ROW -> $S_LN)" || fail "column: w $S_W lines $S_LN (row $W_ROW / $L_ROW)"
sb_fits "left column"
aa_works "left column"
screenshot "topt-dock-left"
dk_check "Tool Options in a left column"
text_follows "left column" 1

dk_move selbar edge-right
dk_p selbar; dk_slot "$P_SLOT"; dk_col "$S_COL"; sb_read
(( C_SIDE == 2 )) && pass "in a right column" || fail "not in a right column [$(dk_tree)]"
sb_fits "right column"
aa_works "right column"
dk_check "Tool Options in a right column"

dk_move selbar float
dk_p selbar; sb_read
(( P_FL != 0 )) && pass "floating (${P_FW}x$P_FH)" || fail "not floating [$(dk_tree)]"
sb_fits "floating"
(( P_FH <= S_H + 12 )) && pass "the window as tall as its lines (window $P_FH, bar $S_H)" || fail "floating window $P_FH tall for a bar $S_H tall"
aa_works "floating"
screenshot "topt-dock-float"
dk_check "Tool Options floating"
text_follows "floating" float

dk_move selbar band-bottom
dk_p selbar; dk_slot "$P_SLOT"; dk_col "$S_COL"; sb_read
(( C_SIDE == 4 )) && pass "in a bottom row" || fail "not in a bottom row [$(dk_tree)]"
sb_fits "bottom row"
aa_works "bottom row"
dk_check "Tool Options in a bottom row"

dk_move selbar band-top
dk_p selbar; dk_slot "$P_SLOT"; dk_col "$S_COL"; sb_read
(( C_SIDE == 3 )) && pass "back in a top row" || fail "not back in a top row [$(dk_tree)]"
dk_rmenu selbar
if (( M_OPEN != 0 )) && dk_menu_has 23; then
    dk_pick 23 "Scale: 3x"; sb_read
    read -r _ _ _ PK PVX PVY PVW PVH PUW PUH PRDY <<< "$(grep -m1 '^PSURF 10 ' "$DK_DUMP")"
    info "at 3x: PSURF k $PK footprint $PVX,$PVY ${PVW}x$PVH units ${PUW}x$PUH; bar ${S_W}x$S_H lines $S_LN"
    [[ "$PK" == 3 && "$PRDY" != 0 ]] && pass "drawn into its own surface at 3x" || fail "no 3x surface (PSURF: $(grep '^PSURF 10 ' "$DK_DUMP"))"
    (( S_W == PUW )) && pass "it lays out in its units ($S_W = $PUW)" || fail "bar w $S_W, surface units $PUW"
    sb_fits "at 3x"
    aa_works "at 3x" 3 2
    screenshot "topt-dock-3x"
    key t; wait_for 0.6 "text tool"; dk_park; dk_settle
    read -r _ _ _ TK _ <<< "$(grep -m1 '^PSURF 9 ' "$DK_DUMP")"
    [[ "$TK" == 3 ]] && pass "the Text Bar takes Tool Options' Scale (3x)" || fail "Text Bar scale: PSURF 9 k $TK"
    key b; wait_for 0.6 "brush"; dk_park; dk_settle
    dk_rmenu selbar; dk_pick 20 "Scale: Auto"
else
    fail "no Scale 3x in the Tool Options handle menu (open $M_OPEN)"
    key Escape
fi
dk_check "Tool Options at the end"
assert_no_crash
assert_window_exists
info "=== Tool Options: docking and scale done ==="
