#!/bin/bash
# =============================================================================
# actions-palette.sh — QA test: the Actions palette (GUI/ACTIONS-PANEL + TOOLS/ACTIONS;
# Rick 2026-11-22: "where i can record actions stop then replay? like photoshop actions" /
# "need a new macro palette" / "the palettes need scale, resize, dock, etc.").
#   1. View > Actions shows a docked panel; Reload Action Sets on an empty folder writes
#      the starter set (Default Actions: Mirror Both Ways, Rotate 180, Gray Negative)
#   2. PLAY Mirror Both Ways moves a dab; it is ONE undo step, named "Action: ..." in the
#      History palette; one Ctrl+Z puts the dab back
#   3. NEW ACTION asks a name and records: a palette command (Invert) is a step, a View
#      command is not; STOP; the step is in the set's file
#   4. PLAY the recorded action: the picture inverts back; again: inverted again
#   5. a step's ON box off: PLAY runs nothing; its DIALOG box toggles; both saved
#   6. a set's triangle folds it; again opens it
#   7. right-click Duplicate; DELETE (asks) removes the copy
#   8. NEW SET writes its file; Delete... (asks) removes it and the file
#   9. Reload Action Sets: what was recorded is read back from the files
#  10. Scale 1x from the handle menu (saved); floated it still lists; [x] closes; View: Actions
# Dump: ACTP vis x y w h rowH rowsFit rowsAll scroll sel recording playing listY listH
# lastRun lastSkip; ACTPB b x y w; ACTPR row node depth on dlg open cmd name (its units).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ACTIONS_PANEL=TRUE HISTORY_PANEL=TRUE ANTIALIAS=FALSE ACTIONS_DIR=QA/.actions-qa
# (ACTIONS_DIR: the sets go to a scratch folder, never the user's data folder)
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ACTDIR="$DRAW_ROOT/QA/.actions-qa"
SETF="$ACTDIR/Default Actions.dact"
DP_ACTIONS=$(awk '$1=="CONST" && $2=="DP_ACTIONS" {print $4; exit}' "$DRAW_ROOT/GUI/DOCK.BI")
ap_read() { dk_settle; read -r _ A_VIS A_X A_Y A_W A_H A_RH A_RF A_RA A_SC A_SEL A_REC A_PLAY A_LY A_LH A_RUN A_SKIP <<< "$(grep -m1 '^ACTP ' "$DK_DUMP")"; }
surf() { read -r _ _ S_ON S_K S_VX S_VY S_VW S_VH S_UW S_UH S_RDY <<< "$(grep "^PSURF $1 " "$DK_DUMP")"; }
vx() { surf "$DP_ACTIONS"; if [[ "$S_ON" == -1 && "$S_UW" -gt 0 ]]; then echo $(( S_VX + ($1 - S_VX) * S_VW / S_UW )); else echo "$1"; fi; }
vy() { surf "$DP_ACTIONS"; if [[ "$S_ON" == -1 && "$S_UH" -gt 0 ]]; then echo $(( S_VY + ($1 - S_VY) * S_VH / S_UH )); else echo "$1"; fi; }
# ap_find NAME [DEPTH]: R_ROW / R_NODE / R_DEP / R_ON / R_DLG / R_OPEN / R_CMD of the first row named NAME
ap_find() {
    R_ROW=""; R_NODE=""; R_DEP=""; R_ON=x; R_DLG=x; R_OPEN=x; R_CMD=x; read -r _ R_ROW R_NODE R_DEP R_ON R_DLG R_OPEN R_CMD _ <<< "$(awk -v n="$1" -v d="${2:-}" '$1=="ACTPR" { nm=$0; sub(/^ACTPR( +[-0-9]+){7} /, "", nm); if (nm==n && (d=="" || $4==d)) { print; exit } }' "$DK_DUMP")"
    [[ -n "$R_ROW" ]]
}
# ap_click ROW PART: click a part of row ROW (name / on / dlg / fold)
ap_click() {
    if [[ -z "$1" ]]; then fail "ap_click: no such row (ap_find missed)"; return 1; fi
    ap_read
    local ry=$(( A_LY + 1 + ($1 - 1 - A_SC) * A_RH + A_RH / 2 )) dep x
    dep=$(awk -v r="$1" '$1=="ACTPR" && $2==r {print $4; exit}' "$DK_DUMP")
    case $2 in
        on)   x=$(( A_X + 9 )) ;;
        dlg)  x=$(( A_X + 21 )) ;;
        fold) x=$(( A_X + 33 + dep * 10 )) ;;
        *)    x=$(( A_X + 50 + dep * 10 )) ;;
    esac
    click "$(vx "$x")" "$(vy "$ry")"; wait_for 0.6 "row $1 $2"; dk_park
}
ap_btn() { # B (1 STOP 2 REC 3 PLAY 4 NEW SET 5 NEW ACTION 6 DELETE)
    local bx by bw
    ap_read
    read -r _ _ bx by bw <<< "$(grep -m1 "^ACTPB $1 " "$DK_DUMP")"
    click "$(vx $(( bx + bw / 2 )))" "$(vy $(( by + A_RH / 2 + 1 )))"; wait_for 0.8 "button $1"; dk_park
}
ap_menu() { # VALUE LABEL [ROW]: right-click (on row ROW, else the list's top) and pick VALUE
    ap_read
    local ry=$(( A_LY + 4 ))
    [[ -n "${3:-}" ]] && ry=$(( A_LY + 1 + ($3 - 1 - A_SC) * A_RH + A_RH / 2 ))
    right_click "$(vx $(( A_X + A_W / 2 )))" "$(vy "$ry")"; wait_for 0.6 "actions menu"; dk_settle
    read -r _ M_OPEN M_PANEL _ M_X M_Y M_W M_N <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"
    if dk_menu_has "$1"; then dk_pick "$1" "$2"; else fail "its menu has no '$2' [$(grep '^DMENUR ' "$DK_DUMP" | tr '\n' '|')]"; key Escape; fi
    dk_park; dk_settle
}
ap_name() { wait_for 1.0 "the name box"; key ctrl+a; type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 1.0 "named"; dk_park; dk_settle; }
setf() { tr -d '\r' < "$SETF"; } # (the file as text: QB64-PE's PRINT # may end lines CRLF)
steps_of() { # NAME: the steps listed under action NAME
    awk -v n="$1" '$1=="ACTPR" { nm=$0; sub(/^ACTPR( +[-0-9]+){7} /, "", nm); if ($4==1) { on=(nm==n) } else if ($4==2 && on) c++ ; if ($4==0) on=0 } END { print c+0 }' "$DK_DUMP"
}
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; dk_park; dk_settle; }
pick_scale() { # VALUE: the handle menu's Scale row (20 Auto, 20+k = kx)
    local ry rh
    dk_settle
    if ! dk_grab_point actions; then fail "actions has no handle"; return 1; fi
    right_click "$GX" "$GY"; wait_for 0.6 "the handle menu"; dk_settle
    read -r _ MO MP _ MX _ <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"
    if [[ "$MO" != -1 || "$MP" != "$DP_ACTIONS" ]]; then fail "no handle menu (open '$MO' panel '$MP')"; key Escape; return 1; fi
    read -r ry rh _ <<< "$(awk -v v="$1" '$1=="DMENUR" && $3==v {print $4" "$5; exit}' "$DK_DUMP")"
    if [[ -z "$ry" ]]; then fail "no Scale row $1 in its menu"; key Escape; return 1; fi
    click $(( MX + 12 )) $(( ry + rh / 2 )); wait_for 0.8 "scale row $1"; dk_park; dk_settle
}

info "=== Actions palette ==="
dk_begin

# --- 1. the panel, the starter set ------------------------------------------------------------
ap_read
(( A_VIS != 0 && A_W > 0 )) && pass "the palette shows (${A_W}x$A_H at $A_X,$A_Y)" || fail "the palette is not shown (ACTP '$A_VIS')"
dk_docked actions && pass "docked (slot $P_SLOT)" || fail "not docked [$(grep -m1 '^P actions ' "$DK_DUMP")]"
(( $(grep -c '^ACTPB ' "$DK_DUMP") == 6 )) && pass "6 buttons" || fail "$(grep -c '^ACTPB ' "$DK_DUMP") buttons"
rm -rf "$ACTDIR"
ap_menu 9109 "Reload Action Sets"
ap_read
[[ -f "$SETF" ]] && pass "Reload on an empty folder wrote the starter set" || fail "no '$SETF' [$(ls -A "$ACTDIR" 2>&1)]"
info "rows: $(grep '^ACTPR ' "$DK_DUMP" | cut -d' ' -f4,9- | tr '\n' '|')"
if ap_find "Default Actions" 0 && ap_find "Mirror Both Ways" 1 && ap_find "Rotate 180" 1 && ap_find "Gray Negative" 1; then
    pass "Default Actions: Mirror Both Ways, Rotate 180, Gray Negative"
else
    fail "the starter set's rows are not all listed"
fi
screenshot "actions-palette"

# --- 2. PLAY: one undo step -----------------------------------------------------------------------
key b; wait_for 0.3 "brush tool"
DX=$(( CANVAS_CX - 50 )); DY=$(( CANVAS_CY - 30 ))
park_mouse; wait_for 0.3 "settle"
snap_region $(( DX - 4 )) $(( DY - 4 )) 9 9 "ap-blank"; BLANK="$SNAP_RESULT"
click "$DX" "$DY"; wait_for 0.4 "dab"; dk_park
snap_region $(( DX - 4 )) $(( DY - 4 )) 9 9 "ap-dab"; DAB="$SNAP_RESULT"
assert_regions_differ "$BLANK" "$DAB" "a dab to mirror"
ap_find "Mirror Both Ways" 1; ap_click "$R_ROW" name
ap_read
(( A_SEL == R_NODE )) && pass "a click selects the action" || fail "selected node $A_SEL (want $R_NODE)"
ap_btn 3; ap_read
(( A_RUN == 2 && A_SKIP == 0 )) && pass "PLAY ran its 2 steps" || fail "PLAY: ran $A_RUN, skipped $A_SKIP"
park_mouse; snap_region $(( DX - 4 )) $(( DY - 4 )) 9 9 "ap-mirrored"
assert_regions_same "$BLANK" "$SNAP_RESULT" "the dab moved away (mirrored)"
grep -q '^HISTPR [0-9]* [0-9]* Action: Mirror Both Ways' "$DK_DUMP" && pass "History names the step 'Action: Mirror Both Ways'" || fail "History rows: $(grep '^HISTPR ' "$DK_DUMP" | cut -d' ' -f4- | tr '\n' '|')"
screenshot "actions-palette-played"
key ctrl+z; wait_for 0.8 "undo"; park_mouse
snap_region $(( DX - 4 )) $(( DY - 4 )) 9 9 "ap-undone"
assert_regions_same "$DAB" "$SNAP_RESULT" "ONE Ctrl+Z undoes the whole action"

# --- 3. record ---------------------------------------------------------------------------------------
ap_find "Default Actions" 0; ap_click "$R_ROW" name
ap_btn 5; screenshot "actions-palette-name"; ap_name "QA Invert"
ap_read
if ap_find "QA Invert" 1 && (( A_REC == R_NODE )); then pass "NEW ACTION: named, recording into it"; else fail "NEW ACTION: recording '$A_REC' [$(grep '^ACTPR ' "$DK_DUMP" | cut -d' ' -f4,9- | tr '\n' '|')]"; fi
park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-p0"; P0="$SNAP_RESULT"
pcmd "Invert"
pcmd "Toggle Char Grid"; pcmd "Toggle Char Grid" # (View: not recorded)
park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-p1"; P1="$SNAP_RESULT"
assert_regions_differ "$P0" "$P1" "Invert ran while recording"
(( $(steps_of "QA Invert") == 1 )) && pass "one step recorded (the View command was not)" || fail "$(steps_of "QA Invert") steps under QA Invert"
ap_find "Invert" 2 && (( R_CMD == 2007 )) && pass "the step is Invert (command 2007)" || fail "no Invert step [$(grep '^ACTPR ' "$DK_DUMP" | cut -d' ' -f4,8- | tr '\n' '|')]"
screenshot "actions-palette-recording"
ap_btn 1; ap_read
(( A_REC == 0 )) && pass "STOP: not recording" || fail "STOP: still recording $A_REC"
setf | grep -q '^ACTION 1 1 QA Invert$' && setf | grep -A1 '^ACTION 1 1 QA Invert$' | grep -q '^STEP 2007 1 0 Invert$' && pass "the set's file has the action and its step" || fail "file: $(setf | tr '\n' '|')"

# --- 4. play it -----------------------------------------------------------------------------------
ap_find "QA Invert" 1; ap_click "$R_ROW" name
ap_btn 3; park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-p2"
assert_regions_same "$P0" "$SNAP_RESULT" "PLAY QA Invert: inverted back"
ap_btn 3; park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-p3"
assert_regions_same "$P1" "$SNAP_RESULT" "PLAY again: inverted again"

# --- 5. the ON / DIALOG boxes ---------------------------------------------------------------------
ap_find "Invert" 2; ap_click "$R_ROW" on
ap_find "Invert" 2
[[ "$R_ON" == 0 ]] && pass "the step's ON box: off" || fail "ON box: on '$R_ON'"
ap_find "QA Invert" 1; ap_click "$R_ROW" name
ap_btn 3; ap_read
(( A_RUN == 0 )) && pass "PLAY with the step off runs nothing" || fail "PLAY ran $A_RUN steps"
park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-p4"
assert_regions_same "$P1" "$SNAP_RESULT" "the picture stays"
ap_find "Invert" 2; ap_click "$R_ROW" on
ap_find "Invert" 2; ap_click "$R_ROW" dlg
ap_find "Invert" 2
[[ "$R_ON" == -1 && "$R_DLG" == -1 ]] && pass "ON again, DIALOG on" || fail "on '$R_ON' dlg '$R_DLG'"
setf | grep -q '^STEP 2007 1 1 Invert$' && pass "saved: STEP 2007 1 1" || fail "file: $(setf | grep '^STEP 2007' | tr '\n' '|')"
ap_find "Invert" 2; ap_click "$R_ROW" dlg

# --- 5b. dialog values (phase 2): Posterize records its values, a cancel records nothing,
#         play runs it without the dialog ---------------------------------------------------
ap_find "Default Actions" 0; ap_click "$R_ROW" name
ap_btn 5; ap_name "QA Post"
pcmd "Posterize..."; screenshot "actions-palette-posterize-dialog"; key Return; wait_for 1.0 "posterized"; dk_park; dk_settle
(( $(steps_of "QA Post") == 1 )) && pass "Posterize OK'd: one step" || fail "$(steps_of "QA Post") steps under QA Post"
setf | grep -A4 '^ACTION 1 1 QA Post$' | tr '\n' ' ' | grep -q 'STEP 2009 1 0 Posterize... PARAM LEVELS=4 PARAM DITHER=[-0-9]* PARAM STRENGTH=50' \
    && pass "its values are saved (LEVELS / DITHER / STRENGTH)" || fail "file: $(setf | grep -A4 '^ACTION 1 1 QA Post$' | tr '\n' '|')"
pcmd "Posterize..."; key Escape; wait_for 1.0 "cancelled"; dk_park; dk_settle
(( $(steps_of "QA Post") == 1 )) && pass "a cancelled dialog records no step" || fail "$(steps_of "QA Post") steps after a cancel"
ap_btn 1
ap_find "QA Post" 1; ap_click "$R_ROW" name
ap_btn 3; ap_read
(( A_RUN == 1 && A_PLAY == 0 )) && pass "PLAY ran it with no dialog (ran $A_RUN)" || fail "PLAY: ran '$A_RUN' playing '$A_PLAY' (a dialog waiting?)"
screenshot "actions-palette-posterize-played"
key Escape; dk_park

# --- 6. fold -------------------------------------------------------------------------------------------
ap_read; RA0=$A_RA
ap_find "Default Actions" 0; ap_click "$R_ROW" fold; ap_read
(( A_RA == 1 )) && pass "the set's triangle folds it (1 row)" || fail "folded: $A_RA rows"
screenshot "actions-palette-folded"
ap_click 1 fold; ap_read
(( A_RA == RA0 )) && pass "and opens it ($A_RA rows)" || fail "opened: $A_RA rows (want $RA0)"

# --- 7. duplicate / delete ----------------------------------------------------------------------------
ap_find "QA Invert" 1
ap_menu 9107 "Duplicate" "$R_ROW"
ap_find "QA Invert copy" 1 && pass "Duplicate: QA Invert copy" || fail "no copy [$(grep '^ACTPR ' "$DK_DUMP" | cut -d' ' -f4,9- | tr '\n' '|')]"
(( $(steps_of "QA Invert copy") == 1 )) && pass "the copy has the step" || fail "the copy has $(steps_of "QA Invert copy") steps"
ap_find "QA Invert copy" 1; ap_click "$R_ROW" name
ap_btn 6; screenshot "actions-palette-delete-ask"; key Return; wait_for 1.0 "answered"; dk_park; dk_settle
ap_find "QA Invert copy" 1 && fail "DELETE: the copy is still there" || pass "DELETE (asked): the copy is gone"
setf | grep -q 'QA Invert copy' && fail "the copy is still in the file" || pass "and out of the file"

# --- 8. new set / delete set ---------------------------------------------------------------------------
ap_btn 4; ap_name "QA Set"
[[ -f "$ACTDIR/QA Set.dact" ]] && ap_find "QA Set" 0 && pass "NEW SET: listed, its file written" || fail "NEW SET: [$(ls "$ACTDIR" | tr '\n' '|')]"
ap_find "QA Set" 0
ap_menu 9108 "Delete..." "$R_ROW"; key Return; wait_for 1.0 "answered"; dk_park; dk_settle
[[ ! -f "$ACTDIR/QA Set.dact" ]] && ! ap_find "QA Set" 0 && pass "Delete...: the set and its file are gone" || fail "the set stays [$(ls "$ACTDIR" | tr '\n' '|')]"

# --- 9. reload ----------------------------------------------------------------------------------------------
ap_menu 9109 "Reload Action Sets"
ap_find "QA Invert" 1 && (( $(steps_of "QA Invert") == 1 )) && pass "Reload: QA Invert and its step read back" || fail "after Reload: [$(grep '^ACTPR ' "$DK_DUMP" | cut -d' ' -f4,9- | tr '\n' '|')]"

# --- 10. scale, float, [x], View: Actions --------------------------------------------------------------
pick_scale 21
surf "$DP_ACTIONS"
[[ "$S_ON" == -1 && "$S_K" == 1 ]] && pass "Scale 1x: its own surface (k $S_K)" || fail "Scale 1x: PSURF '$(grep "^PSURF $DP_ACTIONS " "$DK_DUMP")'"
grep -q '^ACTIONS_PANEL_SCALE=1\b' "$QA_CFG" && pass "ACTIONS_PANEL_SCALE=1 saved" || fail "saved '$(grep '^ACTIONS_PANEL_SCALE' "$QA_CFG")'"
ap_click 1 fold; ap_read
(( A_RA == 1 )) && pass "at 1x a click lands (folded)" || fail "at 1x: $A_RA rows"
ap_click 1 fold
screenshot "actions-palette-1x"
pick_scale 20
dk_move_expect actions float
ap_read
(( A_VIS != 0 && A_RA > 1 )) && pass "floating, it still lists ($A_RA rows)" || fail "floating: vis $A_VIS, $A_RA rows"
screenshot "actions-palette-float"
dk_p actions
click $(( P_FX + P_FW - 6 )) $(( P_FY + 5 )); wait_for 0.8 "close"; dk_park; dk_settle
dk_p actions
(( P_SHOWN == 0 )) && pass "its [x] closes it" || fail "the [x] did not close it (shown $P_SHOWN)"
pcmd "View: Actions"
dk_p actions
(( P_SHOWN != 0 )) && dk_floating actions && pass "View: Actions brings it back, floating where it was" || fail "View: Actions: shown $P_SHOWN fl $P_FL"

rm -rf "$ACTDIR"
assert_no_crash
