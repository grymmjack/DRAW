#!/bin/bash
# =============================================================================
# history-palette.sh — QA test: the History palette (GUI/HISTORY-PANEL; Rick 2026-11-22:
# "and a history palette for undo" / "the palettes need scale, resize, dock, etc." /
# "common red x to close, and recall support for workspaces, universal controls").
#   1. View > History shows a docked panel: one row (the document), UNDO / REDO / CLEAR
#   2. three brush dabs: four rows, the last one current
#   3. a click on row 1 goes back there (the 2nd and 3rd dabs gone from the canvas), a
#      click on row 3 forward again (they are back)
#   4. UNDO / REDO buttons step one state
#   5. right-click: its menu (Step Backward / Step Forward / Clear History); Step Backward works
#   6. the wheel scrolls the list (Shift: 10 rows) once it is longer than the panel
#   7. Scale 1x from the handle menu: its own surface, saved; a row click still lands
#   8. floated, it still lists; its [x] closes it; View: History brings it back
#   9. CLEAR (asks): one row left, the picture as it was
# Dump: HISTP vis x y w h rowH rowsFit rowsAll scroll cur listY listH btnY hover;
# HISTPB b x y w (buttons); HISTPR row last-record name (rows); all its units.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE HISTORY_PANEL=TRUE ANTIALIAS=FALSE
# (HISTORY_PANEL_SCALE is not pinned: --option keys are never saved, and 7. checks it is)
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

DP_HISTORY=$(awk '$1=="CONST" && $2=="DP_HISTORY" {print $4; exit}' "$DRAW_ROOT/GUI/DOCK.BI")
hp_read() { dk_settle; read -r _ H_VIS H_X H_Y H_W H_H H_RH H_RF H_RA H_SC H_CUR H_LY H_LH H_BY H_HOV <<< "$(grep -m1 '^HISTP ' "$DK_DUMP")"; }
surf() { read -r _ _ S_ON S_K S_VX S_VY S_VW S_VH S_UW S_UH S_RDY <<< "$(grep "^PSURF $1 " "$DK_DUMP")"; }
# units -> viewport (the panel's own surface at a Scale; 1:1 at Auto)
vx() { surf "$DP_HISTORY"; if [[ "$S_ON" == -1 && "$S_UW" -gt 0 ]]; then echo $(( S_VX + ($1 - S_VX) * S_VW / S_UW )); else echo "$1"; fi; }
vy() { surf "$DP_HISTORY"; if [[ "$S_ON" == -1 && "$S_UH" -gt 0 ]]; then echo $(( S_VY + ($1 - S_VY) * S_VH / S_UH )); else echo "$1"; fi; }
hp_row() { # R: click row R (0 = the document)
    hp_read
    local ry=$(( H_LY + 1 + ($1 - H_SC) * H_RH + H_RH / 2 ))
    click "$(vx $(( H_X + H_W / 2 )))" "$(vy "$ry")"; wait_for 0.8 "row $1"; dk_park
}
hp_btn() { # B (1 UNDO, 2 REDO, 3 CLEAR)
    local bx by bw
    read -r _ _ bx by bw <<< "$(grep -m1 "^HISTPB $1 " "$DK_DUMP")"
    click "$(vx $(( bx + bw / 2 )))" "$(vy $(( by + H_RH / 2 + 1 )))"; wait_for 0.8 "button $1"; dk_park
}
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; dk_park; dk_settle; }
pick_scale() { # VALUE: the handle menu's Scale row (20 Auto, 20+k = kx)
    local ry rh
    dk_settle
    if ! dk_grab_point history; then fail "history has no handle"; return 1; fi
    right_click "$GX" "$GY"; wait_for 0.6 "the handle menu"; dk_settle
    read -r _ MO MP _ MX _ <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"
    if [[ "$MO" != -1 || "$MP" != "$DP_HISTORY" ]]; then fail "no handle menu (open '$MO' panel '$MP')"; key Escape; return 1; fi
    read -r ry rh _ <<< "$(awk -v v="$1" '$1=="DMENUR" && $3==v {print $4" "$5; exit}' "$DK_DUMP")"
    if [[ -z "$ry" ]]; then fail "no Scale row $1 in its menu"; key Escape; return 1; fi
    click $(( MX + 12 )) $(( ry + rh / 2 )); wait_for 0.8 "scale row $1"; dk_park; dk_settle
}

info "=== History palette ==="
dk_begin

# --- 1. the panel -----------------------------------------------------------------------
hp_read
(( H_VIS != 0 && H_W > 0 )) && pass "the palette shows (${H_W}x$H_H at $H_X,$H_Y)" || fail "the palette is not shown (HISTP '$H_VIS')"
dk_docked history && pass "docked (slot $P_SLOT)" || fail "not docked [$(grep -m1 '^P history ' "$DK_DUMP")]"
(( $(grep -c '^HISTPB ' "$DK_DUMP") == 3 )) && pass "3 buttons" || fail "$(grep -c '^HISTPB ' "$DK_DUMP") buttons"
R0=$H_RA
info "rows at start: $R0 (current $H_CUR)"
(( H_CUR == H_RA - 1 )) && pass "the last row is the current state" || fail "current $H_CUR of $H_RA rows"
screenshot "history-palette"

# --- 2. three dabs ------------------------------------------------------------------------
key b; wait_for 0.3 "brush tool"
DX=$CANVAS_CX; DY=$CANVAS_CY
park_mouse; wait_for 0.3 "settle"
for i in 0 1 2; do snap_region $(( DX - 40 + i * 40 - 4 )) $(( DY - 4 )) 9 9 "hp-blank-$i"; BL[$i]="$SNAP_RESULT"; done
for i in 0 1 2; do click $(( DX - 40 + i * 40 )) "$DY"; wait_for 0.4 "dab $i"; done
dk_park
for i in 0 1 2; do snap_region $(( DX - 40 + i * 40 - 4 )) $(( DY - 4 )) 9 9 "hp-dab-$i"; DB[$i]="$SNAP_RESULT"; done
hp_read
(( H_RA == R0 + 3 && H_CUR == H_RA - 1 )) && pass "three dabs: three more rows, the last current ($H_RA rows)" || fail "after 3 dabs: $H_RA rows (want $(( R0 + 3 ))), current $H_CUR"
info "rows: $(grep '^HISTPR ' "$DK_DUMP" | cut -d' ' -f2,4- | tr '\n' '|')"
grep -q '^HISTPR [0-9]* [0-9]* .*[A-Za-z]' "$DK_DUMP" && pass "the rows are named" || fail "no row names"
screenshot "history-palette-3"

# --- 3. click a state ------------------------------------------------------------------------
B1=$(( R0 )) # the first dab's row
hp_row "$B1"; hp_read
(( H_CUR == B1 )) && pass "a click on row $B1: it is the current state" || fail "after the click on row $B1: current $H_CUR"
snap_region $(( DX + 40 - 4 )) $(( DY - 4 )) 9 9 "hp-back-2"
assert_regions_same "${BL[2]}" "$SNAP_RESULT" "the 3rd dab is undone"
snap_region $(( DX - 40 - 4 )) $(( DY - 4 )) 9 9 "hp-back-0"
assert_regions_same "${DB[0]}" "$SNAP_RESULT" "the 1st dab stays"
screenshot "history-palette-back"
hp_row $(( R0 + 2 )); hp_read
(( H_CUR == R0 + 2 )) && pass "a click on the last row: forward again" || fail "after the click on the last row: current $H_CUR"
snap_region $(( DX + 40 - 4 )) $(( DY - 4 )) 9 9 "hp-fwd-2"
assert_regions_same "${DB[2]}" "$SNAP_RESULT" "the 3rd dab is back"

# --- 4. the buttons -----------------------------------------------------------------------------
hp_btn 1; hp_read
(( H_CUR == R0 + 1 )) && pass "UNDO: one state back" || fail "UNDO: current $H_CUR (want $(( R0 + 1 )))"
hp_btn 2; hp_read
(( H_CUR == R0 + 2 )) && pass "REDO: one state forward" || fail "REDO: current $H_CUR (want $(( R0 + 2 )))"

# --- 5. right-click menu ------------------------------------------------------------------------
right_click "$(vx $(( H_X + H_W / 2 )))" "$(vy $(( H_LY + 4 )))"; wait_for 0.6 "history menu"; dk_settle
read -r _ M_OPEN M_PANEL _ M_X M_Y M_W M_N <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"
if [[ "$M_OPEN" == -1 ]] && dk_menu_has 9001 && dk_menu_has 9002 && dk_menu_has 9003; then
    pass "right-click: Step Backward / Step Forward / Clear History"
    screenshot "history-palette-menu"
    dk_pick 9001 "Step Backward"; hp_read
    (( H_CUR == R0 + 1 )) && pass "Step Backward from the menu" || fail "Step Backward: current $H_CUR"
else
    fail "right-click: menu open '$M_OPEN' [$(grep '^DMENUR ' "$DK_DUMP" | tr '\n' '|')]"
    key Escape
fi

# --- 6. the wheel ----------------------------------------------------------------------------------
for i in $(seq 1 $(( H_RF + 4 ))); do click $(( DX - 60 + (i % 12) * 10 )) $(( DY + 40 )); wait_for 0.15 "dab"; done
dk_park; hp_read
info "after more dabs: $H_RA rows, $H_RF fit, scroll $H_SC, current $H_CUR"
(( H_RA > H_RF && H_SC == H_RA - H_RF )) && pass "the list follows the current state (scrolled to $H_SC)" || fail "scroll $H_SC with $H_RA rows / $H_RF fit"
SC0=$H_SC
scroll_up "$(vx $(( H_X + H_W / 2 )))" "$(vy $(( H_LY + H_LH / 2 )))"; wait_for 0.4 "wheel up"; hp_read
(( H_SC == SC0 - 1 )) && pass "the wheel scrolls a row ($SC0 -> $H_SC)" || fail "wheel up: $SC0 -> $H_SC"
shift_scroll_up "$(vx $(( H_X + H_W / 2 )))" "$(vy $(( H_LY + H_LH / 2 )))"; wait_for 0.4 "shift wheel up"; hp_read
(( H_SC == (SC0 - 11 > 0 ? SC0 - 11 : 0) )) && pass "Shift + the wheel: 10 rows ($H_SC)" || fail "Shift wheel up: $H_SC (want $(( SC0 - 11 > 0 ? SC0 - 11 : 0 )))"

# --- 7. Scale 1x ------------------------------------------------------------------------------------
pick_scale 21
surf "$DP_HISTORY"
[[ "$S_ON" == -1 && "$S_K" == 1 ]] && pass "Scale 1x: its own surface (k $S_K, ${S_UW}x$S_UH units in ${S_VW}x$S_VH px)" || fail "Scale 1x: PSURF '$(grep "^PSURF $DP_HISTORY " "$DK_DUMP")'"
grep -q '^HISTORY_PANEL_SCALE=1\b' "$QA_CFG" && pass "HISTORY_PANEL_SCALE=1 saved" || fail "saved '$(grep '^HISTORY_PANEL_SCALE' "$QA_CFG")'"
screenshot "history-palette-1x"
hp_read; CUR0=$H_CUR
hp_row $(( H_SC + 1 )); hp_read
(( H_CUR == H_SC + 1 || H_CUR != CUR0 )) && pass "at 1x a row click lands (current $CUR0 -> $H_CUR)" || fail "at 1x: current stays $H_CUR"
pick_scale 20
hp_row $(( H_RA - 1 )); hp_read

# --- 8. float, [x], View: History --------------------------------------------------------------
dk_move_expect history float
hp_read
(( H_VIS != 0 && H_RA > 1 )) && pass "floating, it still lists ($H_RA rows)" || fail "floating: vis $H_VIS, $H_RA rows"
screenshot "history-palette-float"
dk_p history
click $(( P_FX + P_FW - 6 )) $(( P_FY + 5 )); wait_for 0.8 "close"; dk_park; dk_settle
dk_p history
(( P_SHOWN == 0 )) && pass "its [x] closes it" || fail "the [x] did not close it (shown $P_SHOWN)"
pcmd "View: History"
dk_p history
(( P_SHOWN != 0 )) && dk_floating history && pass "View: History brings it back, floating where it was" || fail "View: History: shown $P_SHOWN fl $P_FL"

# --- 9. CLEAR ------------------------------------------------------------------------------------------
park_mouse; snap_region $(( DX - 60 )) $(( DY - 10 )) 130 60 "hp-before-clear"; PC0="$SNAP_RESULT"
hp_read
hp_btn 3; wait_for 0.6 "the question"; screenshot "history-palette-clear-ask"
key Return; wait_for 1.0 "answered"; dk_park; hp_read
(( H_RA == 1 && H_CUR == 0 )) && pass "CLEAR: one row left (the document)" || fail "after CLEAR: $H_RA rows, current $H_CUR"
park_mouse; snap_region $(( DX - 60 )) $(( DY - 10 )) 130 60 "hp-after-clear"
assert_regions_same "$PC0" "$SNAP_RESULT" "the picture stays as it was"
assert_no_crash
