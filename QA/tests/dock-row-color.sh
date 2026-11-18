#!/bin/bash
# =============================================================================
# dock-row-color.sh — QA test: the Advanced Color Picker and the Color Mixer in
# a top dock row beside the toolbox (Rick 2026-11-16: "size downward at the top
# of their widgets to fit in bars vertically", "keep it 2 buttons high", "get
# rid of the gap under the toolbox", "the sliders and controls flush right"):
#   - the row keeps the toolbox's height with either panel in it
#   - laid sideways: the wheel / SV field as tall as the row with the quantize
#     slider under the wheel; VARIATIONS is a little triangle (and the gear)
#     in a gutter right of the wheel ("instead of a big more gap", "the cog ...
#     always near the wheel", "quantize should always be under the wheel");
#     the mixer's MORE is a triangle in its title bar
#   - VARIATIONS open: shade rows in balanced columns that never overlap
#   - VARIATIONS / MORE open: the panel widens (rows go in columns to the
#     right), the row stays as tall; closed again: back to its width
#   - the moved controls still work: the hue bar + SV field pick, the
#     disclosure rows toggle
# Dump: ACPW x y w h side (the ACP wheel); ACPV x y w h open; CMXM x y w h open
# panelH side; CMIX <sv x y w h> <hue x y w h> <hex x y w h> <focused> FG ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_MIXER_VISIBLE=1 ADV_COLOR_PICKER_VISIBLE=1 ADV_COLOR_PICKER_VARIATIONS=FALSE COLOR_MIXER_MORE=FALSE TOOLTIPS_DISABLED=TRUE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

row_of() { dk_p "$1" || return 1; dk_slot "$P_SLOT"; dk_col "$S_COL"; }
acpw() { read -r _ WX WY WW WH WSIDE <<< "$(grep '^ACPW ' "$DK_DUMP")"; }
acpq() { read -r _ QX QY QW QH _ GX GY GW GH <<< "$(grep '^ACPQ' "$DK_DUMP")"; }
acpv() { read -r _ VX VY VW VH VOPEN <<< "$(grep '^ACPV ' "$DK_DUMP")"; }
cmxm() { read -r _ MX MY MW MH MOPEN MPH MSIDE <<< "$(grep '^CMXM ' "$DK_DUMP")"; }
cmix() { read -r _ SVX SVY SVW SVH HX HY HW HH XX XY XW XH _ FG _ <<< "$(grep '^CMIX' "$DK_DUMP")"; }

info "=== Dock rows: the color pickers lie sideways ==="
dk_begin

dk_move toolbox band-top
if row_of toolbox && (( C_SIDE == 3 )); then pass "toolbox in a top row (h $C_H)"; else fail "toolbox not in a top row [$(dk_tree)]"; fi
H0=$C_H

# --- the Advanced Color Picker -------------------------------------------------
dk_move advcolorpicker right toolbox
dk_expect_tree 'TOP\.[0-9]+: toolbox \| advcolorpicker' "the ACP beside the toolbox"
row_of advcolorpicker
if (( C_H == H0 )); then pass "the row keeps the toolbox's height ($C_H)"; else fail "the row is $C_H tall with the ACP, $H0 with the toolbox alone"; fi
dk_p advcolorpicker; acpw; acpv
info "ACP ${P_W}x$P_H at $P_X,$P_Y; wheel ${WW}x$WH at $WX,$WY side=$WSIDE; VARIATIONS $VX,$VY ${VW}x$VH open=$VOPEN"
[[ "$WSIDE" == 1 ]] && pass "the ACP lies sideways in the row" || fail "the ACP is not sideways (side=$WSIDE)"
(( WY + WH <= P_Y + P_H + 1 )) && pass "the wheel fits the row (bottom $(( WY + WH )) <= $(( P_Y + P_H )))" || fail "the wheel ends at $(( WY + WH )), the panel at $(( P_Y + P_H ))"
(( VX >= WX + WW && VW <= 24 )) && pass "VARIATIONS is a little triangle right of the wheel ($VX >= $(( WX + WW )), ${VW}px)" || fail "VARIATIONS at x $VX ${VW}px wide, the wheel ends at $(( WX + WW ))"
acpq
(( QY >= WY + WH - 1 && QX >= WX && QX + QW <= WX + WW + 24 )) && pass "quantize under the wheel ($QX,$QY ${QW}x$QH)" || fail "quantize at $QX,$QY ${QW}x$QH, the wheel $WX,$WY ${WW}x$WH"
(( GX >= WX + WW && GX < WX + WW + 30 )) && pass "the gear beside the wheel (x $GX)" || fail "the gear at x $GX, the wheel ends at $(( WX + WW ))"
dk_check "ACP in the row"
dk_seams "ACP in the row"
# the Alt eyedropper over the docked picker (Rick 2026-11-16: "i can't pick
# colors or use the loupe over the docked vertical bars ... hold alt to zoom in
# and drag"): Alt held over the wheel shows the loupe over it (drawn after the
# docked panels) sampling the ring itself, not the dock under it. (Under Xvfb a
# press made while Alt is down never arrives - memory qa-xvfb-alt-press-lost -
# so the press / drag pick, which reads the same frame copy, is Rick's to try.)
loupe() { read -r _ L_OK L_X1 L_Y1 L_X2 L_Y2 L_C <<< "$(grep -m1 '^LOUPE ' "$DK_DUMP")"; }
sat_of() { local h=$1 r g b mx mn v; r=$((16#${h:0:2})); g=$((16#${h:2:2})); b=$((16#${h:4:2})); mx=$r; mn=$r; for v in $g $b; do (( v > mx )) && mx=$v; (( v < mn )) && mn=$v; done; echo $(( mx - mn )); }
RX=$(( WX + 2 )); RY=$(( WY + WH / 2 ))
hover "$RX" "$RY"; sleep 0.3
raw_key down alt; sleep 0.2; hover $(( RX + 1 )) "$RY"; sleep 0.5; hover "$RX" "$RY"; sleep 0.6
dk_settle; loupe
raw_key up alt; sleep 0.3; key Escape; dk_park; dk_settle
info "Alt over the ring ($RX,$RY): LOUPE ok=$L_OK box $L_X1,$L_Y1-$L_X2,$L_Y2 colour $L_C"
(( L_OK == 1 && L_X2 > L_X1 )) && pass "Alt held over the docked wheel: the loupe shows" || fail "no loupe over the docked wheel (LOUPE $L_OK $L_X1 $L_Y1 $L_X2 $L_Y2)"
[[ -n "$L_C" ]] && (( $(sat_of "$L_C") > 80 )) && pass "the loupe samples the ring ($L_C), not the dock under it" || fail "the loupe samples $L_C (want a saturated ring colour)"
W0=$P_W
click $(( VX + VW / 2 )) $(( VY + VH / 2 )); dk_park; dk_settle
acpv; dk_p advcolorpicker; row_of advcolorpicker
[[ "$VOPEN" == 1 ]] && pass "a click opens VARIATIONS" || fail "VARIATIONS open=$VOPEN after a click"
if [[ "$P_SHOWN" != 0 && "$P_LIVE" != 0 ]] && (( P_W > W0 )); then pass "open, the ACP widens: $W0 -> $P_W"; else fail "open, the ACP is ${P_W} wide (was $W0; shown $P_SHOWN live $P_LIVE)"; fi
(( C_H == H0 )) && pass "open, the row stays $C_H tall" || fail "open, the row is $C_H tall (want $H0)"
# the shade rows: every patch inside the panel, no two rows' patches overlap
read -r nr ov out <<< "$(awk -v px="$P_X" -v py="$P_Y" -v pw="$P_W" -v ph="$P_H" '$1=="ACPR" {n++; x1[n]=$2; y1[n]=$3; x2[n]=$2+$4; y2[n]=$3+$5; if ($2<px || $3<py || $2+$4>px+pw || $3+$5>py+ph) o++} END {v=0; for (i=1;i<=n;i++) for (j=i+1;j<=n;j++) if (x1[i]<x2[j] && x1[j]<x2[i] && y1[i]<y2[j] && y1[j]<y2[i]) v++; print n+0, v, o+0}' "$DK_DUMP")"
if (( nr == 0 )); then info "(no ACPR rows in the dump - skipped the overlap check)"
elif (( ov == 0 && out == 0 )); then pass "$nr shade rows: none overlap, all inside the panel"
else fail "$nr shade rows: $ov overlapping pairs, $out outside the panel"; fi
screenshot "dock-row-acp-open"
acpv
click $(( VX + VW / 2 )) $(( VY + VH / 2 )); dk_park; dk_settle
acpv; dk_p advcolorpicker
[[ "$VOPEN" == 0 ]] && pass "a second click closes VARIATIONS" || fail "VARIATIONS open=$VOPEN after the second click"
(( P_W == W0 )) && pass "closed, back to $P_W wide" || fail "closed, ${P_W} wide (was $W0)"
dk_check "ACP after VARIATIONS"

# --- the Color Mixer (alone beside the toolbox: the QA window is too narrow for both)
dk_move advcolorpicker float
dk_move colormixer right toolbox
dk_expect_tree 'TOP\.[0-9]+: toolbox \| colormixer' "the mixer beside the toolbox"
row_of colormixer
if (( C_H == H0 )); then pass "the row keeps the toolbox's height with the mixer ($C_H)"; else fail "the row is $C_H tall with the mixer (want $H0)"; fi
dk_p colormixer; cmxm; cmix
info "mixer ${P_W}x$P_H at $P_X,$P_Y; SV ${SVW}x$SVH at $SVX,$SVY; MORE $MX,$MY ${MW}x$MH open=$MOPEN side=$MSIDE"
[[ "$MSIDE" == 1 ]] && pass "the mixer lies sideways in the row" || fail "the mixer is not sideways (side=$MSIDE)"
(( SVY + SVH <= P_Y + P_H && HY + HH <= P_Y + P_H )) && pass "the SV field and hue bar fit the row" || fail "the SV field ends at $(( SVY + SVH )), the hue bar at $(( HY + HH )), the panel at $(( P_Y + P_H ))"
(( MX >= HX + HW && MY >= P_Y && MY + MH <= SVY && MW <= 24 )) && pass "MORE is a little triangle in the title bar" || fail "MORE at $MX,$MY ${MW}x$MH; hue bar ends at x $(( HX + HW )); SV top $SVY; panel $P_X,$P_Y ${P_W}x$P_H"
dk_check "mixer in the row"
dk_seams "mixer in the row"

# the field still picks: the hue bar's top (red), then the field's top-right corner
click $(( HX + HW / 2 )) $(( HY + 1 )); sleep 0.4
click $(( SVX + SVW - 2 )) $(( SVY + 1 )); dk_park; dk_settle; cmix
(( 16#${FG:0:2} > 200 && 16#${FG:2:2} < 110 && 16#${FG:4:2} < 60 )) && pass "the field picks in the row (FG $FG)" || fail "a pick in the row gave FG $FG, want red"

# MORE opens: wider, as tall; the hex box lands inside the panel. Open it is
# ~850 px wide: in the 958 px QA window that only fits alone in the row (a
# crowded row drops the slot that does not fit), so the toolbox goes first
H1=$C_H
dk_move toolbox edge-left
dk_expect_tree 'TOP\.[0-9]+: colormixer( ;|$)' "the mixer alone in the row"
dk_p colormixer; row_of colormixer; H0=$C_H; cmxm
W1=$P_W
cmxm
click $(( MX + MW / 2 )) $(( MY + MH / 2 )); dk_park; dk_settle
cmxm; cmix; dk_p colormixer; row_of colormixer
[[ "$MOPEN" == 1 ]] && pass "a click opens MORE" || fail "MORE open=$MOPEN after a click"
if [[ "$P_SHOWN" != 0 ]] && (( P_W > W1 )); then pass "open, the mixer widens: $W1 -> $P_W"; else fail "open, the mixer is $P_W wide (was $W1, shown $P_SHOWN)"; fi
(( C_H == H0 )) && pass "open, the row stays $C_H tall" || fail "open, the row is $C_H tall (want $H0)"
# (open in a short row the strips take a column each: what does not fit the
# room the row gives is left out - the panel never runs off the window)
if (( XX >= P_X && XX + XW <= P_X + P_W && XY >= P_Y && XY + XH <= P_Y + P_H )); then pass "the hex box is inside the panel ($XX,$XY ${XW}x$XH)"
elif (( P_X >= 0 && P_X + P_W <= 958 )); then pass "the hex strip is left out for room; the open mixer fits the window ($P_X..$(( P_X + P_W )))"
else fail "the open mixer runs off the window ($P_X,$P_Y ${P_W}x$P_H), hex box $XX,$XY"; fi
screenshot "dock-row-mixer-open"
cmxm
click $(( MX + MW / 2 )) $(( MY + MH / 2 )); dk_park; dk_settle
cmxm; dk_p colormixer
[[ "$MOPEN" == 0 ]] && pass "a second click closes MORE" || fail "MORE open=$MOPEN after the second click"
(( P_W == W1 )) && pass "closed, back to $P_W wide" || fail "closed, $P_W wide (was $W1)"
dk_check "mixer after MORE"

# floating again: back to the stacked layout
dk_move colormixer float
cmxm
[[ "$MSIDE" == 0 ]] && pass "floating, the mixer is stacked again" || fail "floating, the mixer is still sideways"
acpw
[[ "$WSIDE" == 0 ]] && pass "floating, the ACP is stacked again" || fail "floating, the ACP is still sideways"
dk_check "both floating"

screenshot "dock-row-color"
assert_window_exists
info "=== Dock rows: color pickers done ==="
