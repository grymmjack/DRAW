#!/bin/bash
# =============================================================================
# tool-options-fill.sh — QA test: the Tool Options bar for the fill, the spray and the
# picker (GUI/SEL-BAR; PLANS/TOOL-OPTIONS-BAR.md phase 3 - settings with no home before):
#   - fill: SAMPLE chips, TOLERANCE, CONTIGUOUS, GRID CELL, ADJUST, BLEND chips. CONTIGUOUS
#     off fills the matching pixels outside a closed rectangle too; on, only inside
#   - spray: SPREAD / DENSITY, AIRBRUSH (the spray's AA) brings FLOW; a wide SPREAD reaches
#     pixels a narrow one does not
#   - picker: SAMPLE chips, AREA 1 / 3X3 / 5X5, LOUPE; a 5X5 pick on a 1 px line averages it
#     with what is beside it (a different colour from the 1 px pick)
# Dump: SELBARF fillsample tol contig gridcell adjust blend spread density flow picksample
# picksize loupe; STCHIP x y transparent FGHEX; SELBARC id x y w trackX. Ids: GUI/SEL-BAR.BI.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_BAR=TRUE ANTIALIAS=FALSE FILL_SAMPLE=LAYER FILL_TOLERANCE=0 FILL_CONTIGUOUS=TRUE SPRAY_SPREAD=100 SPRAY_DENSITY=100 PICKER_SAMPLE=MERGED PICKER_SAMPLE_SIZE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14 # THEME.TEXT_BAR_ROW_HEIGHT (the stock theme)
ID_SIZE=24; ID_AA=33
ID_FS0=118; ID_FTOL=122; ID_FCONTIG=123; ID_FGRID=124; ID_FADJ=125; ID_FB0=127
ID_SPREAD=131; ID_DENSITY=132; ID_FLOW=133; ID_PS0=134; ID_PSZ0=138; ID_LOUPE=141

sb_read() { read -r _ S_ON S_X S_Y S_W S_H S_LN _ _ _ _ _ _ _ _ _ _ _ _ S_TOOL _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; }
sf_read() { read -r _ F_SAMP F_TOL F_CONTIG F_GRID F_ADJ F_BLEND P_SPREAD P_DENS P_FLOW K_SAMP K_SIZE K_LOUPE _ <<< "$(grep -m1 '^SELBARF ' "$DK_DUMP")"; }
fg_read() { FG=$(grep -m1 '^STCHIP ' "$DK_DUMP" | awk '{print $NF}'); }
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
settle() { wait_for 0.4 "$1"; dk_park; dk_settle; sb_read; sf_read; fg_read; }
sb_click() { if sbc "$1"; then click $(( C_X + C_W / 2 )) $(( C_Y + ROW_H / 2 )); settle "$2"; else fail "no control $1 ($2) on the bar"; fi; }
sb_track() { if sbc "$1"; then click $(( C_TX + ($2 > 0 ? $2 : -1) )) $(( C_Y + ROW_H / 2 )); settle "$3"; else fail "no slider $1 ($3) on the bar"; fi; }
sb_middle() { if sbc "$1"; then middle_click $(( C_TX + 20 )) $(( C_Y + ROW_H / 2 )); settle "$2"; else fail "no slider $1 ($2) on the bar"; fi; }
sb_inside() {
    local why="" id x y w tx
    while read -r _ id x y w tx; do
        (( x >= S_X && x + w <= S_X + S_W && y >= S_Y && y + ROW_H <= S_Y + S_H )) || why+=" control $id at $x,$y w $w"
    done < <(grep '^SELBARC ' "$DK_DUMP")
    [[ -z "$why" ]] && pass "$1: every control inside the bar ($S_LN lines)" || fail "$1:$why"
}
has_all() {
    local miss="" id
    for id in "${@:2}"; do sbc "$id" || miss+=" $id"; done
    [[ -z "$miss" ]] && pass "$1" || fail "$1: missing$miss"
}

info "=== Tool Options: the fill, the spray, the picker ==="
dk_begin

# a closed 1 px rectangle: the same colour inside and out, not joined
key r; settle "rectangle"
sb_track $ID_SIZE 0 "a 1 px line"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 20 )); settle "the rectangle"

# --- fill ----------------------------------------------------------------------------------
key f; settle "fill"
(( S_ON != 0 )) && pass "the fill shows the bar" || { fail "fill: no bar"; assert_no_crash; exit 0; }
has_all "fill: SAMPLE chips, TOLERANCE, CONTIGUOUS, GRID CELL, ADJUST, BLEND chips" \
    $ID_FS0 $(( ID_FS0 + 3 )) $ID_FTOL $ID_FCONTIG $ID_FGRID $ID_FADJ $ID_FB0 $(( ID_FB0 + 3 ))
sb_inside "fill"
sb_click $(( ID_FS0 + 1 )) "MERGED"
(( F_SAMP == 1 )) && pass "MERGED chip: FILL_SAMPLE 1" || fail "MERGED: $F_SAMP"
sb_click $(( ID_FS0 + 3 )) "REPLACE ALL"
(( F_SAMP == 3 )) || fail "REPLACE ALL: $F_SAMP"
sb_click $ID_FS0 "LAYER"
(( F_SAMP == 0 )) || fail "LAYER: $F_SAMP"
sb_track $ID_FTOL 22 "TOLERANCE: the middle"
(( F_TOL > 80 && F_TOL < 180 )) && pass "TOLERANCE track middle: $F_TOL" || fail "TOLERANCE track: $F_TOL"
sb_middle $ID_FTOL "middle-click TOLERANCE"
(( F_TOL == 0 )) && pass "middle-click TOLERANCE: 0" || fail "middle-click TOLERANCE: $F_TOL"
sb_click $(( ID_FB0 + 3 )) "PIGMENT"
(( F_BLEND == 3 )) && pass "PIGMENT chip: blend space 3" || fail "PIGMENT: $F_BLEND"
sb_click $(( ID_FB0 + 1 )) "OKLAB"
(( F_BLEND == 1 )) || fail "OKLAB: $F_BLEND"
G0=$F_GRID; sb_click $ID_FGRID "GRID CELL"
(( F_GRID != G0 )) && pass "GRID CELL toggles ($G0 -> $F_GRID)" || fail "GRID CELL: $G0 -> $F_GRID"
sb_click $ID_FGRID "GRID CELL back"
A0=$F_ADJ; sb_click $ID_FADJ "ADJUST"
(( F_ADJ != A0 )) && pass "ADJUST toggles ($A0 -> $F_ADJ)" || fail "ADJUST: $A0 -> $F_ADJ"
sb_click $ID_FADJ "ADJUST back"

# CONTIGUOUS on: a click inside fills inside only
snap_region $(( CANVAS_CX + 45 )) $(( CANVAS_CY - 4 )) 8 8 "topt-fill-out-before"
OUT0="$SNAP_RESULT"
snap_region $(( CANVAS_CX - 4 )) $(( CANVAS_CY - 4 )) 8 8 "topt-fill-in-before"
IN0="$SNAP_RESULT"
click "$CANVAS_CX" "$CANVAS_CY"; settle "fill inside"
snap_region $(( CANVAS_CX - 4 )) $(( CANVAS_CY - 4 )) 8 8 "topt-fill-in-after"
assert_regions_differ "$IN0" "$SNAP_RESULT" "a fill inside the rectangle"
snap_region $(( CANVAS_CX + 45 )) $(( CANVAS_CY - 4 )) 8 8 "topt-fill-out-after"
assert_regions_same "$OUT0" "$SNAP_RESULT" "CONTIGUOUS: the outside, not joined, stays"
key ctrl+z; settle "undo the fill"
# CONTIGUOUS off: the outside matches too
sb_click $ID_FCONTIG "CONTIGUOUS off"
(( F_CONTIG == 0 )) && pass "CONTIGUOUS off" || fail "CONTIGUOUS: $F_CONTIG"
click "$CANVAS_CX" "$CANVAS_CY"; settle "fill, not contiguous"
snap_region $(( CANVAS_CX + 45 )) $(( CANVAS_CY - 4 )) 8 8 "topt-fill-out-noncontig"
assert_regions_differ "$OUT0" "$SNAP_RESULT" "CONTIGUOUS off: the matching outside fills too"
key ctrl+z; settle "undo"
sb_click $ID_FCONTIG "CONTIGUOUS on"

# --- spray ---------------------------------------------------------------------------------
key k; settle "spray"
has_all "spray: SIZE, SPREAD, DENSITY, AIRBRUSH" $ID_SIZE $ID_SPREAD $ID_DENSITY $ID_AA
sbc $ID_FLOW && fail "FLOW shown with the airbrush off" || pass "no FLOW without the airbrush"
sb_click $ID_AA "AIRBRUSH"
sbc $ID_FLOW && pass "AIRBRUSH on: FLOW shows" || fail "AIRBRUSH on: no FLOW"
sb_click $ID_AA "AIRBRUSH off"
sb_inside "spray"
sb_track $ID_SIZE 0 "the smallest spray"
SX=$(( CANVAS_CX - 50 )); SY=$(( CANVAS_CY + 45 ))
sb_track $ID_SPREAD 0 "SPREAD: the left end"
(( P_SPREAD == 25 )) && pass "SPREAD track left: 25 %" || fail "SPREAD track left: $P_SPREAD"
snap_region $(( SX + 7 )) $(( SY - 12 )) 6 24 "topt-spray-narrow-before"
NB="$SNAP_RESULT"
mouse_down "$SX" "$SY"; wait_for 0.8 "spraying, narrow"; mouse_up; settle "narrow spray"
snap_region $(( SX + 7 )) $(( SY - 12 )) 6 24 "topt-spray-narrow-after"
assert_regions_same "$NB" "$SNAP_RESULT" "a 25 % spray does not reach 7 px out"
sb_track $ID_SPREAD 43 "SPREAD: the right end"
(( P_SPREAD == 400 )) && pass "SPREAD track right: 400 %" || fail "SPREAD track right: $P_SPREAD"
SX=$(( CANVAS_CX + 50 ))
snap_region $(( SX + 7 )) $(( SY - 12 )) 6 24 "topt-spray-wide-before"
WB="$SNAP_RESULT"
mouse_down "$SX" "$SY"; wait_for 0.8 "spraying, wide"; mouse_up; settle "wide spray"
snap_region $(( SX + 7 )) $(( SY - 12 )) 6 24 "topt-spray-wide-after"
assert_regions_differ "$WB" "$SNAP_RESULT" "a 400 % spray reaches 7 px out"
sb_middle $ID_SPREAD "middle-click SPREAD"
(( P_SPREAD == 100 )) && pass "middle-click SPREAD: 100 %" || fail "middle-click SPREAD: $P_SPREAD"

# --- picker ----------------------------------------------------------------------------------
key i; settle "picker"
(( S_ON != 0 )) && pass "the picker shows the bar" || fail "picker: no bar"
has_all "picker: SAMPLE chips, AREA chips, LOUPE" $ID_PS0 $(( ID_PS0 + 2 )) $ID_PSZ0 $(( ID_PSZ0 + 2 )) $ID_LOUPE
sb_inside "picker"
sb_click $(( ID_PS0 + 1 )) "LAYER"
(( K_SAMP == 1 )) && pass "LAYER chip: PICKER_SAMPLE 1" || fail "LAYER: $K_SAMP"
sb_click $ID_PS0 "MERGED"
sb_track $ID_LOUPE 0 "LOUPE: the left end"
(( K_LOUPE == 1 )) && pass "LOUPE track left: 1x" || fail "LOUPE track left: $K_LOUPE"
sb_track $ID_LOUPE 43 "LOUPE: the right end"
(( K_LOUPE == 8 )) || fail "LOUPE track right: $K_LOUPE"
# the rectangle's left edge (the drag's start column): 1 px there, then 5x5 round it
click $(( CANVAS_CX - 15 )) "$CANVAS_CY"; settle "pick inside"
INSIDE="$FG"
click $(( CANVAS_CX - 30 )) "$CANVAS_CY"; settle "pick the line, 1 px"
LINE1="$FG"
[[ "$LINE1" != "$INSIDE" ]] && pass "1 px on the line: its colour ($LINE1, inside $INSIDE)" || fail "1 px pick on the line = the inside ($LINE1)"
sb_click $(( ID_PSZ0 + 2 )) "5X5"
(( K_SIZE == 5 )) && pass "5X5 chip: PICKER_SAMPLE_SIZE 5" || fail "5X5: $K_SIZE"
click $(( CANVAS_CX - 30 )) "$CANVAS_CY"; settle "pick the line, 5x5"
[[ "$FG" != "$LINE1" ]] && pass "5X5 on the 1 px line: an average ($FG, not $LINE1)" || fail "5X5 pick = the 1 px pick ($FG)"
sb_click $ID_PSZ0 "1 px again"

dk_check "the Tool Options bar with the fill / spray / picker"
assert_no_crash
assert_window_exists
info "=== Tool Options: the fill, the spray, the picker PASSED ==="
