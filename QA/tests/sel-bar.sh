#!/bin/bash
# =============================================================================
# sel-bar.sh — QA test: the Selection Bar (GUI/SEL-BAR, a dock panel like the
# text bar; Rick 2026-11-18: "a new panel too for selection properties (layout
# similar to text properties) where we can have feathering / threshold sliders
# for magic wand, etc.") and the soft selections behind it
# (PLANS/AA-SELECTIONS.md):
#   - shows with a selection tool (a top row of its own), gone with a tool that has
#     nothing on it
#   - its controls inside the bar; the wand gets TOLERANCE etc., the marquee the
#     shape group
#   - mode chips (ADD / INTERSECT) set the mode with no modifier held
#   - FEATHER slider: a new rectangle selection comes out soft and wider
#   - INTERSECT keeps only the overlap
#   - GROW (by AMOUNT) widens the selection; Ctrl+Z undoes it
#   - the wand with a TOLERANCE takes the native path (a mask)
#   - in a left column its controls wrap into more lines, all inside
# Dump: SELBAR vis x y w h lines mode feather tol contig merged aa shape sw sh
# center smooth grow; SELM has soft x1 y1 x2 y2 mask (canvas px); SELBARC id x y
# w trackX (units = viewport px at Auto).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_FEATHER=0 SELECTION_MODE=REPLACE SELECTION_GROW=1 WAND_TOLERANCE=0 SELECTION_BAR=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14 # THEME.TEXT_BAR_ROW_HEIGHT (the stock theme)
sb_read() { read -r _ S_ON S_X S_Y S_W S_H S_LN S_MODE S_FEA S_TOL S_CON S_MRG S_AA S_SHP S_SW S_SH S_CEN S_SMO S_GRO _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; }
sm_read() { read -r _ M_HAS M_SOFT M_X1 M_Y1 M_X2 M_Y2 M_MASK _ <<< "$(grep -m1 '^SELM ' "$DK_DUMP")"; }
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
sb_click() { # sb_click ID WHAT — the control's middle
    if sbc "$1"; then click $(( C_X + C_W / 2 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$2"; dk_park; dk_settle; else fail "no control $1 ($2) on the bar"; fi
}
sb_track() { # sb_track ID DX WHAT — press the slider's track DX px from its left end (0 = 1 px left of it, inside the slider's 2 px slack: a Retina click 1-3 px off still means "the left end")
    if sbc "$1"; then click $(( C_TX + ($2 > 0 ? $2 : -1) )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$3"; dk_park; dk_settle; else fail "no slider $1 ($3) on the bar"; fi
}
sb_inside() {
    local why="" id x y w tx
    while read -r _ id x y w tx; do
        (( x >= S_X && x + w <= S_X + S_W && y >= S_Y && y + ROW_H <= S_Y + S_H )) || why+=" control $id at $x,$y w $w"
    done < <(grep '^SELBARC ' "$DK_DUMP")
    (( S_H == S_LN * ROW_H )) || why+=" h $S_H != $S_LN lines"
    [[ -z "$why" ]] && pass "$1: every control inside the bar ($S_LN lines, ${S_W}x$S_H)" || fail "$1:$why"
}
sel_rect() { # sel_rect X1 Y1 X2 Y2 — a marquee drag (viewport px)
    drag "$1" "$2" "$3" "$4"; wait_for 0.5 "selection"; dk_park; dk_settle; sm_read
}

info "=== Selection Bar ==="
dk_begin

# --- shows with a selection tool ------------------------------------------------
key m; wait_for 0.6 "marquee"; dk_park; dk_settle; sb_read
[[ -n "$S_ON" && "$S_ON" != 0 ]] && pass "the bar shows with the marquee" || { fail "no Selection Bar (SELBAR: $(grep -m1 '^SELBAR ' "$DK_DUMP"))"; assert_no_crash; exit 0; }
dk_p selbar; dk_slot "$P_SLOT"; dk_col "$S_COL"
(( P_SLOT > 0 && C_SIDE == 3 )) && pass "a top row (y $S_Y)" || fail "not in a top row (slot $P_SLOT side $C_SIDE) [$(dk_tree)]"
sb_inside "in its row"
sbc 11 && pass "the marquee gets the shape chips" || fail "no FREE chip with the marquee"
sbc 7 && fail "TOLERANCE shown with the marquee" || pass "no wand controls with the marquee"
screenshot "selbar-row"
# (every tool you stay in has options now - PLANS/TOOL-OPTIONS-BAR.md phase 3; the text
# tool's are the Text Bar, in the same place: Tool Options itself is not shown)
key t; wait_for 0.6 "text tool"; dk_park; dk_settle; sb_read
(( S_ON == 0 )) && pass "the text tool: the Text Bar instead of the bar" || fail "text tool: SELBAR on=$S_ON"
key m; wait_for 0.6 "marquee"; dk_park; dk_settle
dk_check "the selection bar in its row"

# --- a plain rectangle ---------------------------------------------------------
sel_rect $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 ))
W0=$(( M_X2 - M_X1 )); X1_0=$M_X1; X2_0=$M_X2
(( M_HAS != 0 && M_SOFT == 0 && W0 > 4 )) && pass "a hard rectangle ($M_X1,$M_Y1 - $M_X2,$M_Y2)" || fail "rectangle: SELM $M_HAS $M_SOFT $M_X1 $M_Y1 $M_X2 $M_Y2"

# --- mode chips ----------------------------------------------------------------
sb_click 2 "ADD chip"; sb_read
(( S_MODE == 1 )) && pass "ADD chip: the mode is add" || fail "ADD chip: mode $S_MODE"
sb_click 1 "REPLACE chip"; sb_read
(( S_MODE == 0 )) && pass "REPLACE chip: back to replace" || fail "REPLACE chip: mode $S_MODE"

# --- feather: a new selection comes out soft ---------------------------------------
sb_track 5 3 "feather ~4"; sb_read
(( S_FEA >= 2 && S_FEA <= 8 )) && pass "FEATHER slider set ($S_FEA)" || fail "FEATHER slider: $S_FEA"
key ctrl+d; wait_for 0.4 "deselect"
sel_rect $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 ))
(( M_HAS != 0 && M_SOFT != 0 && M_MASK != 0 )) && pass "feathered: a soft mask" || fail "feathered: SELM $M_HAS soft $M_SOFT mask $M_MASK"
(( M_X2 - M_X1 >= W0 + S_FEA )) && pass "feathered: wider ($W0 -> $(( M_X2 - M_X1 )))" || fail "feathered width $(( M_X2 - M_X1 )) (hard $W0, feather $S_FEA)"
screenshot "selbar-feathered"
sb_track 5 0 "feather 0"; sb_read
(( S_FEA == 0 )) && pass "FEATHER back to 0" || fail "FEATHER: $S_FEA"

# --- intersect -------------------------------------------------------------------
key ctrl+d; wait_for 0.4 "deselect"
sel_rect $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 20 ))
sb_click 4 "INTERSECT chip"
sel_rect "$CANVAS_CX" $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY + 20 ))
(( M_HAS != 0 && M_X1 > X1_0 + W0 / 4 && M_X2 <= X2_0 + 1 )) && pass "INTERSECT: only the overlap ($M_X1 - $M_X2 of $X1_0 - $X2_0)" || fail "INTERSECT: SELM $M_HAS $M_X1 - $M_X2 (first $X1_0 - $X2_0)"
sb_click 1 "REPLACE chip"

# --- grow + undo --------------------------------------------------------------------
GX1=$M_X1; GX2=$M_X2
sb_click 19 "GROW"; sm_read
(( M_X1 == GX1 - 1 && M_X2 == GX2 + 1 )) && pass "GROW by 1 ($GX1-$GX2 -> $M_X1-$M_X2)" || fail "GROW: $GX1-$GX2 -> $M_X1-$M_X2"
key ctrl+z; wait_for 0.5 "undo"; dk_park; dk_settle; sm_read
(( M_X1 == GX1 && M_X2 == GX2 )) && pass "Ctrl+Z: the grow undone" || fail "Ctrl+Z after GROW: $M_X1-$M_X2 (want $GX1-$GX2)"

# --- the wand ------------------------------------------------------------------------
key ctrl+d; wait_for 0.4 "deselect"
key w; wait_for 0.6 "wand"; dk_park; dk_settle; sb_read
(( S_ON != 0 )) && sbc 7 && pass "the wand gets TOLERANCE" || fail "wand: SELBAR on $S_ON, no TOLERANCE"
sbc 11 && fail "shape chips shown with the wand" || pass "no shape chips with the wand"
sb_track 7 22 "tolerance ~half"; sb_read
(( S_TOL >= 100 && S_TOL <= 160 )) && pass "TOLERANCE slider ($S_TOL)" || fail "TOLERANCE: $S_TOL"
click "$CANVAS_CX" "$CANVAS_CY"; wait_for 0.6 "wand click"; dk_park; dk_settle; sm_read
(( M_HAS != 0 && M_MASK != 0 )) && pass "wand with a tolerance: a mask ($M_X1,$M_Y1 - $M_X2,$M_Y2)" || fail "wand: SELM $M_HAS mask $M_MASK"
sb_track 7 0 "tolerance 0"
key ctrl+d; wait_for 0.4 "deselect"
dk_check "the selection bar with the wand"

# --- a left column: wrapped into more lines ---------------------------------------------
sb_read; L_ROW=$S_LN; W_ROW=$S_W
dk_move selbar edge-left
dk_p selbar; dk_slot "$P_SLOT"; dk_col "$S_COL"; sb_read
(( C_SIDE == 1 )) && pass "in a left column" || fail "not in a left column [$(dk_tree)]"
(( S_W < W_ROW && S_LN > L_ROW )) && pass "narrower, more lines ($L_ROW -> $S_LN)" || fail "column: w $S_W lines $S_LN (row $W_ROW / $L_ROW)"
sb_inside "in the column"
screenshot "selbar-column"
dk_check "the selection bar in a column"

assert_no_crash
assert_window_exists
info "=== Selection Bar test done ==="
