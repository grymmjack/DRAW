#!/bin/bash
# =============================================================================
# tool-options-shapes.sh — QA test: the Tool Options bar for the line and the shapes
# (GUI/SEL-BAR; PLANS/TOOL-OPTIONS-BAR.md phase 3, decision 1: values set on the bar
# stick - each new shape starts with them, the keys while dragging change one shape):
#   - line: START / END cap chips, SPOKES, SNAP angle chips; an END ARROW set on the
#     bar draws an arrowhead and stays for the next line
#   - rectangle: DIVIDE | / DIVIDE -; ellipse: SLICES / RINGS (sticky, middle-click 0)
#   - polygon: SNAP chips, FINISH, CANCEL (CANCEL drops the polygon being drawn)
#   - bezier: HANDLES, COMMIT, CANCEL
# Dump: SELBARS spokes startcap endcap snapdeg snappx hdiv vdiv slices rings (the
# next shape's values); SELBARC id x y w trackX. Ids: GUI/SEL-BAR.BI.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_BAR=TRUE ANTIALIAS=FALSE ANGLE_SNAP_DEGREES=45 ANGLE_SNAP_PIXEL_ART=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ROW_H=14 # THEME.TEXT_BAR_ROW_HEIGHT (the stock theme)
ID_SIZE=24; ID_SC0=40; ID_EC0=45; ID_SPOKES=49; ID_SNAP15=51; ID_SNAP30=52; ID_SNAP45=53; ID_SNAPPX=55
ID_HDIV=56; ID_VDIV=57; ID_SLICES=58; ID_RINGS=59; ID_FINISH=60; ID_PCANCEL=61
ID_HANDLES=62; ID_COMMIT=63; ID_BCANCEL=64

sb_read() { read -r _ S_ON S_X S_Y S_W S_H S_LN _ _ _ _ _ _ _ _ _ _ _ _ S_TOOL _ <<< "$(grep -m1 '^SELBAR ' "$DK_DUMP")"; }
ss_read() { read -r _ Q_SPOKES Q_SC Q_EC Q_DEG Q_PX Q_HD Q_VD Q_SL Q_RI _ <<< "$(grep -m1 '^SELBARS ' "$DK_DUMP")"; }
sbc() { C_ID=""; read -r _ C_ID C_X C_Y C_W C_TX _ <<< "$(grep -m1 "^SELBARC $1 " "$DK_DUMP")"; [[ -n "$C_ID" ]]; }
sb_click() {
    if sbc "$1"; then click $(( C_X + C_W / 2 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$2"; dk_park; dk_settle; else fail "no control $1 ($2) on the bar"; fi
}
sb_track() {
    if sbc "$1"; then click $(( C_TX + ($2 > 0 ? $2 : -1) )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$3"; dk_park; dk_settle; else fail "no slider $1 ($3) on the bar"; fi
}
sb_middle() {
    if sbc "$1"; then middle_click $(( C_TX + 20 )) $(( C_Y + ROW_H / 2 )); wait_for 0.4 "$2"; dk_park; dk_settle; else fail "no slider $1 ($2) on the bar"; fi
}
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
tool() { key "$1"; wait_for 0.6 "$2"; dk_park; dk_settle; sb_read; ss_read; }

info "=== Tool Options: the line and the shapes ==="
dk_begin

# --- line ------------------------------------------------------------------------------
tool l "line"
(( S_ON != 0 )) && pass "the line shows the bar" || { fail "line: no bar"; assert_no_crash; exit 0; }
has_all "line: start caps, end caps, SPOKES, the snap chips" $ID_SC0 $(( ID_SC0 + 3 )) $ID_EC0 $(( ID_EC0 + 3 )) $ID_SPOKES $ID_SNAP15 $ID_SNAP45 $ID_SNAPPX
sb_inside "line"
sb_track $ID_SIZE 0 "a 1 px line"
# a plain line, then one with the bar's END ARROW: the ends differ
drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) $(( CANVAS_CX - 10 )) $(( CANVAS_CY - 40 )); wait_for 0.5 "plain line"; dk_park; dk_settle
snap_region $(( CANVAS_CX - 18 )) $(( CANVAS_CY - 48 )) 16 16 "topt-line-plain-end"
PLAIN="$SNAP_RESULT"
sb_click $(( ID_EC0 + 1 )) "END ARROW chip"; ss_read
(( Q_EC == 1 )) && pass "END ARROW chip: the next line's end cap" || fail "END ARROW: end cap $Q_EC"
drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX - 10 )) $(( CANVAS_CY - 10 )); wait_for 0.5 "arrow line"; dk_park; dk_settle
snap_region $(( CANVAS_CX - 18 )) $(( CANVAS_CY - 18 )) 16 16 "topt-line-arrow-end"
assert_regions_differ "$PLAIN" "$SNAP_RESULT" "the bar's END ARROW draws an arrowhead"
ss_read
(( Q_EC == 1 )) && pass "the end cap sticks after a line (decision 1)" || fail "after a line: end cap $Q_EC"
sb_click $ID_EC0 "END NONE chip"; ss_read
(( Q_EC == 0 )) || fail "END NONE: end cap $Q_EC"
sb_track $ID_SPOKES 30 "SPOKES"; ss_read
(( Q_SPOKES > 0 )) && pass "SPOKES track: $Q_SPOKES" || fail "SPOKES track: $Q_SPOKES"
sb_middle $ID_SPOKES "middle-click SPOKES"; ss_read
(( Q_SPOKES == 0 )) && pass "middle-click SPOKES: 0" || fail "middle-click SPOKES: $Q_SPOKES"
sb_click $ID_SNAP30 "SNAP 30"; ss_read
(( Q_DEG == 30 && Q_PX == 0 )) && pass "SNAP 30: Ctrl+Shift snaps to 30 degrees" || fail "SNAP 30: $Q_DEG px $Q_PX"
sb_click $ID_SNAPPX "SNAP PIXEL"; ss_read
(( Q_PX != 0 )) && pass "SNAP PIXEL: pixel-art angles" || fail "SNAP PIXEL: px $Q_PX"
sb_click $ID_SNAP45 "SNAP 45"; ss_read
(( Q_DEG == 45 && Q_PX == 0 )) || fail "SNAP 45: $Q_DEG px $Q_PX"

# --- rectangle -----------------------------------------------------------------------------
tool r "rectangle"
has_all "rectangle: DIVIDE | and DIVIDE -" $ID_HDIV $ID_VDIV
sb_inside "rectangle"
sb_track $ID_HDIV 6 "DIVIDE |"; ss_read
HD=$Q_HD
(( HD > 0 )) && pass "DIVIDE | track: $HD" || fail "DIVIDE | track: $HD"
drag $(( CANVAS_CX + 10 )) $(( CANVAS_CY - 50 )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY - 20 )); wait_for 0.5 "rectangle"; dk_park; dk_settle; ss_read
(( Q_HD == HD )) && pass "DIVIDE | sticks after a rectangle" || fail "after a rectangle: DIVIDE | $Q_HD (was $HD)"
sb_middle $ID_HDIV "middle-click DIVIDE |"; ss_read
(( Q_HD == 0 )) || fail "middle-click DIVIDE |: $Q_HD"

# --- ellipse --------------------------------------------------------------------------------
tool c "ellipse"
has_all "ellipse: SLICES and RINGS" $ID_SLICES $ID_RINGS
sb_track $ID_RINGS 10 "RINGS"; ss_read
(( Q_RI > 0 )) && pass "RINGS track: $Q_RI" || fail "RINGS track: $Q_RI"
sb_middle $ID_RINGS "middle-click RINGS"; ss_read
(( Q_RI == 0 )) || fail "middle-click RINGS: $Q_RI"

# --- polygon ---------------------------------------------------------------------------------
tool p "polygon"
has_all "polygon: the snap chips, FINISH, CANCEL" $ID_SNAP45 $ID_FINISH $ID_PCANCEL
sb_inside "polygon"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY + 10 )) 60 50 "topt-poly-before"
PB="$SNAP_RESULT"
click $(( CANVAS_CX - 55 )) $(( CANVAS_CY + 15 )); wait_for 0.3 "poly 1"
click $(( CANVAS_CX - 10 )) $(( CANVAS_CY + 20 )); wait_for 0.3 "poly 2"
click $(( CANVAS_CX - 30 )) $(( CANVAS_CY + 50 )); wait_for 0.4 "poly 3"; dk_park; dk_settle
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY + 10 )) 60 50 "topt-poly-drawn"
assert_regions_differ "$PB" "$SNAP_RESULT" "a polygon being drawn"
sb_click $ID_PCANCEL "CANCEL"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY + 10 )) 60 50 "topt-poly-cancelled"
assert_regions_same "$PB" "$SNAP_RESULT" "CANCEL drops the polygon (the canvas as before)" 3
# FINISH = a right-click finish: the polygon stays, and one Ctrl+Z takes it away (POLY_LINE_reset
# alone, as first built, left it with no undo)
click $(( CANVAS_CX - 55 )) $(( CANVAS_CY + 15 )); wait_for 0.3 "poly 1"
click $(( CANVAS_CX - 10 )) $(( CANVAS_CY + 20 )); wait_for 0.3 "poly 2"
click $(( CANVAS_CX - 30 )) $(( CANVAS_CY + 50 )); wait_for 0.4 "poly 3"; dk_park; dk_settle
sb_click $ID_FINISH "FINISH"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY + 10 )) 60 50 "topt-poly-finished"
assert_regions_differ "$PB" "$SNAP_RESULT" "FINISH keeps the polygon"
key ctrl+z; wait_for 0.5 "undo the polygon"; dk_park; dk_settle
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY + 10 )) 60 50 "topt-poly-undone"
assert_regions_same "$PB" "$SNAP_RESULT" "Ctrl+Z after FINISH takes the polygon away" 3

# --- bezier ------------------------------------------------------------------------------------
tool q "bezier"
has_all "bezier: HANDLES, COMMIT, CANCEL" $ID_HANDLES $ID_COMMIT $ID_BCANCEL
sb_inside "bezier"
assert_no_crash
assert_window_exists
info "=== Tool Options: the line and the shapes PASSED ==="
