#!/bin/bash
# =============================================================================
# mypaint-settings.sh — QA test: the MyPaint Brush Settings panel (GUI/MYPAINT-SET;
# Rick 2026-11-18: MyPaint's Freehand panel - "make it a panel similar to pen control,
# ok? so it can be docked") and the universal value input on its sliders ("mousewheel
# +/-1 and if shift held +/-10 as well as middle click and double click on slider to
# reset - middle click on value box to reset, double click to edit").
#   1. View > MyPaint Brush Settings shows a docked panel of 8 sliders
#   2. the wheel on OPAQUE: +1 a notch, Shift +10; a middle-click resets it
#   3. a click on the track sets it; a double-click on the track resets it
#   4. a double-click on the PRESSURE value types one (80)
#   5. OPAQUE typed 0: a MyPaint stroke paints nothing; RESET: it paints again
#   6. the command hides the panel
# Dump: MPS vis x y w h cols sw lw vw rowH hover drag; MPSS k x y value reset; MPSB id x y w.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE MYPAINT_PANEL=FALSE MYPAINT_SETTINGS=TRUE MYPAINT_SETTINGS_SCALE=0 MYPAINT_BRUSH= MYPAINT_SIZE=0 MYPAINT_MOUSE_PRESSURE=50 MYPAINT_TWIST=0 ANTIALIAS=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

mps_read() { read -r _ S_VIS S_X S_Y S_W S_H S_COLS S_SW S_LW S_VW S_RH S_HOV S_DRAG <<< "$(grep -m1 '^MPS ' "$DK_DUMP")"; }
mpss() { read -r _ _ K_X K_Y K_V K_D <<< "$(grep -m1 "^MPSS $1 " "$DK_DUMP")"; }
mps_val() { dk_settle; mpss "$1"; echo "$K_V"; }
# the track's middle / its left end / the value text of slider K (one row, or stacked)
mps_track() { # K FRAC(0..100) -> TX TY
    mps_read; mpss "$1"
    local tx tw ty
    if (( S_SW < S_LW + S_VW + 40 )); then tx=$(( K_X + 2 )); tw=$(( S_SW - 4 )); ty=$(( K_Y + S_RH + 2 + (S_RH - 7) / 2 ))
    else tx=$(( K_X + S_LW )); tw=$(( S_SW - S_LW - S_VW )); ty=$(( K_Y + 3 + (S_RH - 7) / 2 )); fi
    TX=$(( tx + 1 + (tw - 3) * $2 / 100 )); TY=$ty
}
mps_value_xy() { mps_read; mpss "$1"; VX=$(( K_X + S_SW - S_VW / 2 )); VY=$(( K_Y + S_RH / 2 )); }
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; dk_park; dk_settle; }
myp_read() { read -r _ T_TOOL T_ACT T_READY T_STROKES T_STEPS _ <<< "$(grep -m1 '^MYP ' "$DK_DUMP")"; }

info "=== MyPaint Brush Settings ==="
dk_begin
# the tool first: choosing it shows the MyPaint brushes too, which moves the canvas
pcmd "MyPaint Brush Tool"

# --- 1. the panel ---------------------------------------------------------------------
mps_read
(( S_VIS != 0 && S_W > 0 && S_H > 0 )) && pass "the panel shows (${S_W}x$S_H at $S_X,$S_Y, $S_COLS column(s))" || fail "the panel is not shown (MPS '$S_VIS' ${S_W}x$S_H)"
N=$(grep -c '^MPSS ' "$DK_DUMP")
(( N == 8 )) && pass "8 sliders" || fail "$N sliders (want 8)"
mpss 8
(( K_Y > S_Y && K_Y < S_Y + S_H )) && pass "the last slider is inside the panel" || fail "TWIST at y $K_Y, panel $S_Y..$(( S_Y + S_H ))"
screenshot "mypaint-settings-panel"

# --- 2. the wheel and the middle button on OPAQUE ------------------------------------------
O0=$(mps_val 2); mpss 2; OD=$K_D
info "OPAQUE $O0 (its reset: $OD)"
mps_track 2 50
scroll_down "$TX" "$TY"; wait_for 0.4 "wheel down"
O1=$(mps_val 2)
(( O1 == O0 - 1 )) && pass "the wheel down: OPAQUE $O0 -> $O1" || fail "wheel down: $O0 -> $O1 (want $(( O0 - 1 )))"
shift_scroll_down "$TX" "$TY"; wait_for 0.4 "shift wheel down"
O2=$(mps_val 2)
(( O2 == O1 - 10 )) && pass "Shift + the wheel: 10 a notch ($O1 -> $O2)" || fail "shift wheel: $O1 -> $O2 (want $(( O1 - 10 )))"
middle_click "$TX" "$TY"; wait_for 0.4 "middle click"
O3=$(mps_val 2)
(( O3 == OD )) && pass "a middle-click resets it ($O3)" || fail "middle-click: $O3 (want $OD)"

# --- 3. a click sets it, a double-click resets ---------------------------------------------
mps_track 2 10
click "$TX" "$TY"; wait_for 0.5 "click the track low"
O4=$(mps_val 2)
(( O4 < OD - 30 )) && pass "a click on the track sets it ($O4)" || fail "click on the track: $O4 (reset $OD)"
sleep 0.5
mps_track 2 10
double_click "$TX" "$TY"; wait_for 0.5 "double-click the track"
O5=$(mps_val 2)
(( O5 == OD )) && pass "a double-click on the track resets it ($O5)" || fail "double-click on the track: $O5 (want $OD)"

# --- 4. a double-click on a value types one ----------------------------------------------------
mps_value_xy 7
double_click "$VX" "$VY"; wait_for 1.0 "the number box"
key ctrl+a; type_text "80"; key Return; wait_for 0.8 "typed"
dk_park
P1=$(mps_val 7)
(( P1 == 80 )) && pass "a double-click on PRESSURE's value typed 80" || fail "PRESSURE after typing: '$P1' (want 80)"

# --- 5. OPAQUE 0 paints nothing; RESET paints again ---------------------------------------
mps_value_xy 2
double_click "$VX" "$VY"; wait_for 1.0 "the number box"
key ctrl+a; type_text "0"; key Return; wait_for 0.8 "typed"
dk_park
O6=$(mps_val 2)
(( O6 == 0 )) && pass "OPAQUE typed 0.0" || fail "OPAQUE after typing 0: '$O6'"
RX=$(( CANVAS_CX - 60 )); RY=$(( CANVAS_CY - 20 ))
snap_region "$RX" "$RY" 120 40 "mps-before"; BEFORE="$SNAP_RESULT"
drag $(( CANVAS_CX - 40 )) "$CANVAS_CY" $(( CANVAS_CX + 40 )) "$CANVAS_CY"; wait_for 0.6 "stroke at opaque 0"
dk_park; dk_settle
snap_region "$RX" "$RY" 120 40 "mps-opaque0"
D0=$(magick compare -metric AE "$BEFORE" "$SNAP_RESULT" null: 2>&1 | awk '{print int($1)}')
myp_read
(( D0 == 0 && T_STROKES >= 1 )) && pass "OPAQUE 0: the stroke ($T_STROKES) painted nothing" || fail "OPAQUE 0: $D0 px changed (strokes '$T_STROKES')"
key ctrl+z; wait_for 0.5 "undo the empty stroke"
mpsb() { B_X=""; read -r _ _ B_X B_Y B_W <<< "$(grep -m1 "^MPSB $1 " "$DK_DUMP")"; [[ -n "$B_X" ]]; }
if mpsb 20; then click $(( B_X + B_W / 2 )) $(( B_Y + S_RH / 2 )); wait_for 0.6 "RESET"; dk_park; fi
O7=$(mps_val 2); P2=$(mps_val 7)
(( O7 == OD && P2 == 50 )) && pass "RESET: OPAQUE $O7, PRESSURE $P2 (as the brush was made)" || fail "after RESET: OPAQUE $O7 (want $OD), PRESSURE $P2 (want 50)"
drag $(( CANVAS_CX - 40 )) "$CANVAS_CY" $(( CANVAS_CX + 40 )) "$CANVAS_CY"; wait_for 0.6 "stroke after reset"
dk_park; dk_settle
snap_region "$RX" "$RY" 120 40 "mps-reset"
D1=$(magick compare -metric AE "$BEFORE" "$SNAP_RESULT" null: 2>&1 | awk '{print int($1)}')
(( D1 > 40 )) && pass "after RESET the stroke paints ($D1 px)" || fail "after RESET only $D1 px changed"
screenshot "mypaint-settings-stroke"

# --- 6. hide ---------------------------------------------------------------------------------
pcmd "View: MyPaint Brush Settings"
mps_read
(( S_VIS == 0 )) && pass "the command hides the panel" || fail "still shown after the command (MPS '$S_VIS')"
assert_no_crash
