#!/bin/bash
# =============================================================================
# tool-options-smart.sh — QA test: the Tool Options bar for the smart shapes
# (GUI/SEL-BAR; PLANS/TOOL-OPTIONS-BAR.md phase 3 - "every option of every kind,
# especially the dice"; decision 2 - OUTLINE / FILLED on the bar):
#   - KIND chips switch between the ten kinds; each kind shows its own options
#   - polygon SIDES (track, wheel, middle-click), GRID SNAP
#   - FILLED: a left-drag draws the shape filled (its centre gets paint), OUTLINE does not
#   - dice: the die chips, TILT (a signed slider), LIGHT POWER; tab FLAT side; bevel OUTER
#   - arrow THICK: a thick filled arrow covers a point beside its axis, a thin one does not
# Dump: SELBARSS filled sides pdepth snap lock slices piehole rrrad tabrad flat round segs
# mouth pachole dice cdepth ctilt cturn tdepth ttilt tturn laz lel lint bevel border style
# stem head flare thick; SELBARC id x y w trackX. Ids: GUI/SEL-BAR.BI.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_BAR=TRUE ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14 # THEME.TEXT_BAR_ROW_HEIGHT (the stock theme)
ID_SIZE=24; ID_K0=66; ID_OUTLINE=76; ID_FILLED=77; ID_SIDES=78; ID_PDEPTH=79; ID_SNAPV=80; ID_LOCKROT=81
ID_SLICES=82; ID_PIEHOLE=83; ID_RADIUS=84; ID_FLAT0=86; ID_ROUND=90; ID_SEGS=91; ID_MOUTH=92; ID_PACHOLE=93
ID_D0=95; ID_ZDEPTH=102; ID_TILT=103; ID_TURN=104; ID_LAZ=106; ID_LEL=107; ID_LINT=108
ID_BEVEL=109; ID_BORDER=110; ID_INNER=111; ID_OUTER=112; ID_STEM=113; ID_HEAD=114; ID_FLARE=115; ID_THICK=116
TOOL_SS=100 # TOOL_SS_POLYGON; the kinds are 100-109 in chip order

sb_read() { read -r _ S_ON S_X S_Y S_W S_H S_LN _ _ _ _ _ _ _ _ _ _ _ _ S_TOOL _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; }
ss_read() {
    read -r _ Q_FILLED Q_SIDES Q_PDEPTH Q_SNAP Q_LOCK Q_SLICES Q_PIEHOLE Q_RRRAD Q_TABRAD Q_FLAT Q_ROUND Q_SEGS \
        Q_MOUTH Q_PACHOLE Q_DICE Q_CDEPTH Q_CTILT Q_CTURN Q_TDEPTH Q_TTILT Q_TTURN Q_LAZ Q_LEL Q_LINT \
        Q_BEVEL Q_BORDER Q_STYLE Q_STEM Q_HEAD Q_FLARE Q_THICK _ <<< "$(grep -m1 '^SELBARSS ' "$DK_DUMP")"
}
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
settle() { wait_for 0.4 "$1"; dk_park; dk_settle; sb_read; ss_read; }
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
kind() { # kind <0-9> <name> <ids it must show...>
    sb_click $(( ID_K0 + $1 )) "KIND $2"
    (( S_TOOL == TOOL_SS + $1 )) && pass "KIND $2 chip: tool $S_TOOL" || fail "KIND $2 chip: tool $S_TOOL (wanted $(( TOOL_SS + $1 )))"
    has_all "$2: its options" "${@:3}"
    sb_inside "$2"
}

info "=== Tool Options: the smart shapes ==="
dk_begin

key s; settle "smart shapes"
(( S_ON != 0 && S_TOOL == TOOL_SS )) && pass "S: the polygon smart shape, with the bar" || { fail "smart shapes: bar $S_ON tool $S_TOOL"; assert_no_crash; exit 0; }
has_all "polygon: KIND chips, OUTLINE / FILLED, SIDES, POINTS, GRID SNAP, NO SPIN, SIZE" \
    $ID_K0 $(( ID_K0 + 9 )) $ID_OUTLINE $ID_FILLED $ID_SIDES $ID_PDEPTH $ID_SNAPV $ID_LOCKROT $ID_SIZE
sb_inside "polygon"

# --- polygon values -----------------------------------------------------------------------
sb_track $ID_SIDES 43 "SIDES: the right end"
(( Q_SIDES == 30 )) && pass "SIDES track right: 30" || fail "SIDES track right: $Q_SIDES"
sb_middle $ID_SIDES "middle-click SIDES"
(( Q_SIDES == 5 )) && pass "middle-click SIDES: 5 (the default)" || fail "middle-click SIDES: $Q_SIDES"
sbc $ID_SIDES && { scroll_up $(( C_TX + 20 )) $(( C_Y + ROW_H / 2 )); settle "wheel up on SIDES"; }
(( Q_SIDES == 6 )) && pass "wheel up on SIDES: 6" || fail "wheel up on SIDES: $Q_SIDES"
sb_click $ID_SNAPV "GRID SNAP"
(( Q_SNAP != 0 )) && pass "GRID SNAP on" || fail "GRID SNAP: $Q_SNAP"
sb_click $ID_SNAPV "GRID SNAP off"
(( Q_SNAP == 0 )) || fail "GRID SNAP off: $Q_SNAP"

# --- OUTLINE / FILLED: the polygon's centre (the press point) -------------------------------
sb_track $ID_SIZE 0 "a 1 px outline"
snap_region $(( CANVAS_CX - 43 )) $(( CANVAS_CY - 23 )) 6 6 "topt-ss-outline-before"
OB="$SNAP_RESULT"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 20 )); settle "outline polygon"
snap_region $(( CANVAS_CX - 43 )) $(( CANVAS_CY - 23 )) 6 6 "topt-ss-outline-after"
assert_regions_same "$OB" "$SNAP_RESULT" "OUTLINE: a left-drag leaves the polygon's middle empty"
sb_click $ID_FILLED "FILLED chip"
(( Q_FILLED != 0 )) && pass "FILLED chip: left-drags fill" || fail "FILLED chip: $Q_FILLED"
snap_region $(( CANVAS_CX + 27 )) $(( CANVAS_CY - 23 )) 6 6 "topt-ss-filled-before"
FB="$SNAP_RESULT"
drag $(( CANVAS_CX + 30 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 55 )) $(( CANVAS_CY - 20 )); settle "filled polygon"
snap_region $(( CANVAS_CX + 27 )) $(( CANVAS_CY - 23 )) 6 6 "topt-ss-filled-after"
assert_regions_differ "$FB" "$SNAP_RESULT" "FILLED: a left-drag fills the polygon"

# --- every kind shows its own options --------------------------------------------------------
kind 1 "PIE" $ID_SLICES $ID_PIEHOLE $ID_FILLED
kind 2 "ROUNDED" $ID_RADIUS $ID_FILLED
kind 3 "TAB" $ID_RADIUS $ID_FLAT0 $(( ID_FLAT0 + 3 ))
sb_click $(( ID_FLAT0 + 3 )) "FLAT LEFT"
(( Q_FLAT == 3 )) && pass "FLAT LEFT chip: the tab's flat side 3" || fail "FLAT LEFT: $Q_FLAT"
kind 4 "PILL" $ID_ROUND $ID_SEGS
kind 5 "PAC-MAN" $ID_MOUTH $ID_PACHOLE
sb_track $ID_MOUTH 0 "MOUTH: the left end"
(( Q_MOUTH == 0 )) && pass "MOUTH track left: 0" || fail "MOUTH track left: $Q_MOUTH"
sb_middle $ID_MOUTH "middle-click MOUTH"
(( Q_MOUTH == 60 )) || fail "middle-click MOUTH: $Q_MOUTH"
kind 6 "DICE" $ID_D0 $(( ID_D0 + 6 )) $ID_ZDEPTH $ID_TILT $ID_TURN $ID_LAZ $ID_LEL $ID_LINT $ID_OUTLINE $ID_FILLED
sb_click $(( ID_D0 + 5 )) "D20"
(( Q_DICE == 20 )) && pass "D20 chip: a 20-sided die" || fail "D20: dice $Q_DICE"
sb_track $ID_TILT 0 "TILT: the left end"
(( Q_CTILT == -180 )) && pass "TILT track left: -180 (a signed slider)" || fail "TILT track left: $Q_CTILT"
sb_middle $ID_TILT "middle-click TILT"
(( Q_CTILT == 25 )) && pass "middle-click TILT: 25 (the default)" || fail "middle-click TILT: $Q_CTILT"
sb_track $ID_LINT 43 "LIGHT POWER: the right end"
(( Q_LINT == 180 )) && pass "LIGHT POWER track right: 180 %" || fail "LIGHT POWER: $Q_LINT"
sb_middle $ID_LINT "middle-click LIGHT POWER"
(( Q_LINT == 100 )) || fail "middle-click LIGHT POWER: $Q_LINT"
kind 7 "BEVEL" $ID_BEVEL $ID_BORDER $ID_INNER $ID_OUTER
sb_click $ID_OUTER "OUTER"
(( Q_STYLE == 1 && Q_BORDER >= 1 )) && pass "OUTER chip: outer style, with a border ($Q_BORDER)" || fail "OUTER: style $Q_STYLE border $Q_BORDER"
kind 9 "3D TEXT" $ID_ZDEPTH $ID_TILT $ID_TURN $ID_LAZ $ID_LEL $ID_LINT
sbc $ID_OUTLINE && fail "OUTLINE / FILLED shown with the 3D text (always solid)" || pass "no OUTLINE / FILLED with the 3D text"

# --- arrow: THICK, drawn filled ---------------------------------------------------------------
kind 8 "ARROW" $ID_STEM $ID_HEAD $ID_FLARE $ID_THICK
sb_track $ID_THICK 0 "THICK: the left end"
(( Q_THICK == 4 )) && pass "THICK track left: 4 px" || fail "THICK track left: $Q_THICK"
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 33 )) 8 5 "topt-ss-thin-before"
TB="$SNAP_RESULT"
drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY + 25 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 25 )); settle "a thin arrow"
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 33 )) 8 5 "topt-ss-thin-after"
assert_regions_same "$TB" "$SNAP_RESULT" "a 4 px arrow misses a point 8 px beside it"
sb_track $ID_THICK 43 "THICK: the right end"
(( Q_THICK == 200 )) && pass "THICK track right: 200 px" || fail "THICK track right: $Q_THICK"
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 63 )) 8 5 "topt-ss-thick-before"
KB="$SNAP_RESULT"
drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY + 55 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 55 )); settle "a thick arrow"
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 63 )) 8 5 "topt-ss-thick-after"
assert_regions_differ "$KB" "$SNAP_RESULT" "a thick arrow covers a point 8 px beside it"
sb_click $ID_OUTLINE "OUTLINE again"
(( Q_FILLED == 0 )) || fail "OUTLINE: filled $Q_FILLED"

dk_check "the Tool Options bar with the smart shapes"
assert_no_crash
assert_window_exists
info "=== Tool Options: the smart shapes PASSED ==="
