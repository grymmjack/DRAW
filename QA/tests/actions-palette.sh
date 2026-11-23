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
#   5b. dialog values: Posterize / Pixelate / Remap record theirs and play silently; Rename
#      Layer records its name (a text value, ACTS_ask$) and play renames with no box
#   5c. Insert Stop... (its menu): on an action = at its end, on a step = after it; the file
#      has STEP -1 <msg>; play shows the message: CONTINUE goes on, STOP ends the play there
#      (what ran stays, one undo step each); a stop's row deletes without asking
#   5d. Assign Key... (its menu) opens the Rebind Key box: F9 + OK - the key plays the action
#      (a bind: DRAW.bindings row 2740 = action key 1; the set file has KEY 1), the row shows
#      F9, a Reload keeps it; Clear Key: the key is let go (file + bindings), F9 plays nothing
#   5e. Batch... (its menu): a folder, an output folder, PNG - every image there inverted into
#      the output folder (a .txt skipped), the document open before comes back as it was
#   5f. tool steps (phase 3): recording, a brush stroke, a line, a rectangle, an ellipse and a
#      fill (on a new layer) are 5 steps (STEP -2 + TOOL / X1.. / COLOR / SIZE / PTS); undone,
#      PLAY draws them again - the same picture - as one undo step
#   6. a set's triangle folds it; again opens it
#   7. right-click Duplicate; DELETE (asks) removes the copy
#   8. NEW SET writes its file; Delete... (asks) removes it and the file
#   9. Reload Action Sets: what was recorded is read back from the files
#  10. Scale 1x from the handle menu (saved), its title bar (its own header) smaller, at 3x
#      bigger; floated it still lists; [x] closes; View: Actions
# Dump: ACTP vis x y w h rowH rowsFit rowsAll scroll sel recording playing listY listH
# lastRun lastSkip halted batchFail; ACTPK node slot key (an action's key); ACTPB b x y w; ACTPR row node depth on dlg open cmd name (its units).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ACTIONS_PANEL=TRUE HISTORY_PANEL=TRUE ANTIALIAS=FALSE ACTIONS_DIR=QA/.actions-qa
# (ACTIONS_DIR: the sets go to a scratch folder, never the user's data folder)
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

ACTDIR="$DRAW_ROOT/QA/.actions-qa"
SETF="$ACTDIR/Default Actions.dact"
DP_ACTIONS=$(awk '$1=="CONST" && $2=="DP_ACTIONS" {print $4; exit}' "$DRAW_ROOT/GUI/DOCK.BI")
ap_read() { dk_settle; read -r _ A_VIS A_X A_Y A_W A_H A_RH A_RF A_RA A_SC A_SEL A_REC A_PLAY A_LY A_LH A_RUN A_SKIP A_HALT A_BFAIL <<< "$(grep -m1 '^ACTP ' "$DK_DUMP")"; }
surf() { read -r _ _ S_ON S_K S_VX S_VY S_VW S_VH S_UW S_UH S_RDY <<< "$(grep "^PSURF $1 " "$DK_DUMP")"; }
vx() { surf "$DP_ACTIONS"; if [[ "$S_ON" == -1 && "$S_UW" -gt 0 ]]; then echo $(( S_VX + ($1 - S_VX) * S_VW / S_UW )); else echo "$1"; fi; }
vy() { surf "$DP_ACTIONS"; if [[ "$S_ON" == -1 && "$S_UH" -gt 0 ]]; then echo $(( S_VY + ($1 - S_VY) * S_VH / S_UH )); else echo "$1"; fi; }
# ap_find NAME [DEPTH]: R_ROW / R_NODE / R_DEP / R_ON / R_DLG / R_OPEN / R_CMD of the first row named NAME
ap_find() {
    R_ROW=""; R_NODE=""; R_DEP=""; R_ON=x; R_DLG=x; R_OPEN=x; R_CMD=x; read -r _ R_ROW R_NODE R_DEP R_ON R_DLG R_OPEN R_CMD _ <<< "$(awk -v n="$1" -v d="${2:-}" '$1=="ACTPR" { nm=$0; sub(/^ACTPR( +[-0-9]+){7} /, "", nm); if (nm==n && (d=="" || $4==d)) { print; exit } }' "$DK_DUMP")"
    [[ -n "$R_ROW" ]]
}
# ap_reveal ROW: wheel the list until row ROW is on screen (the list follows the selection)
ap_reveal() {
    local i
    for i in 1 2 3 4 5 6 7 8; do
        ap_read
        if (( $1 - 1 < A_SC )); then scroll_up "$(vx $(( A_X + 60 )))" "$(vy $(( A_LY + 4 )))"
        elif (( $1 > A_SC + A_RF )); then scroll_down "$(vx $(( A_X + 60 )))" "$(vy $(( A_LY + 4 )))"
        else return 0; fi
        wait_for 0.3 "list scroll"; dk_park
    done
}
# ap_click ROW PART: click a part of row ROW (name / on / dlg / fold)
ap_click() {
    if [[ -z "$1" ]]; then fail "ap_click: no such row (ap_find missed)"; return 1; fi
    ap_reveal "$1"
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
    [[ -n "${3:-}" ]] && ap_reveal "$3"
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
# a dialog wired by the IMAGE-ADJ sweep (Pixelate: PIXSIZE) and Remap to Palette (DITHER / STRENGTH)
ap_find "QA Post" 1; ap_click "$R_ROW" name
ap_btn 2
pcmd "Pixelate..."; key Return; wait_for 1.0 "pixelated"; dk_park; dk_settle
pcmd "Remap to Palette..."; key Return; wait_for 1.0 "remapped"; dk_park; dk_settle
ap_btn 1
(( $(steps_of "QA Post") == 3 )) && setf | grep -A1 '^STEP 2010 1 0 Pixelate...$' | grep -q '^PARAM PIXSIZE=[0-9]' \
    && pass "REC added Pixelate with its value (PIXSIZE)" || fail "after REC: $(steps_of "QA Post") steps; file: $(setf | grep -A8 '^ACTION 1 1 QA Post$' | tr '\n' '|')"
setf | grep -A2 '^STEP 1516 1 0 Remap to Palette...$' | tr '\n' ' ' | grep -q 'PARAM DITHER=[-0-9]* PARAM STRENGTH=50' \
    && pass "REC added Remap to Palette with its values (DITHER / STRENGTH)" || fail "file: $(setf | grep -A8 '^ACTION 1 1 QA Post$' | tr '\n' '|')"
ap_find "QA Post" 1; ap_click "$R_ROW" name
ap_btn 3; ap_read
(( A_RUN == 3 && A_PLAY == 0 )) && pass "PLAY ran Posterize + Pixelate + Remap with no dialog" || fail "PLAY: ran '$A_RUN' playing '$A_PLAY'"
key Escape; dk_park
# a text value (Rename Layer: NAME, through ACTS_ask$), played silently
cur_name() { awk '$1=="LAYERN" && $3==-1 { sub(/^LAYERN +[0-9]+ +-1 /, ""); print; exit }' "$DK_DUMP"; }
rename_to() { pcmd "Rename Layer"; wait_for 0.6 "the name box"; key ctrl+a; type_text "$1"; wait_for 0.3 "typed"; key Return; wait_for 1.0 "renamed"; dk_park; dk_settle; }
ap_find "QA Post" 1; ap_click "$R_ROW" name
ap_btn 5; ap_name "QA Name"
rename_to "QA Renamed"
ap_btn 1
(( $(steps_of "QA Name") == 1 )) && setf | grep -A1 '^STEP 726 1 0 Rename Layer$' | tr -d '\r' | grep -qx 'PARAM NAME=QA Renamed' \
    && pass "Rename Layer records its name (PARAM NAME=QA Renamed)" || fail "QA Name: $(steps_of "QA Name") steps; file: $(setf | grep -A3 '^ACTION 1 1 QA Name$' | tr '\n' '|')"
rename_to "Something Else"
[[ "$(cur_name)" == "Something Else" ]] || fail "the layer is '$(cur_name)' after a rename by hand"
ap_find "QA Name" 1; ap_click "$R_ROW" name
ap_btn 3; ap_read
(( A_RUN == 1 && A_PLAY == 0 )) && [[ "$(cur_name)" == "QA Renamed" ]] && pass "PLAY renames it with no box ('$(cur_name)')" || fail "PLAY: ran '$A_RUN' playing '$A_PLAY', layer '$(cur_name)'"
key Escape; dk_park

# --- 5c. insert stop ---------------------------------------------------------------------------------
# ap_find_cmd CMD: R_ROW / R_NODE of the first row whose command is CMD
ap_find_cmd() { R_ROW=""; R_NODE=""; read -r _ R_ROW R_NODE _ <<< "$(awk -v c="$1" '$1=="ACTPR" && $4==2 && $8==c { print; exit }' "$DK_DUMP")"; [[ -n "$R_ROW" ]]; }
ap_find "Mirror Both Ways" 1
ap_menu 9110 "Insert Stop..." "$R_ROW"; ap_name "QA end"
if ap_find "QA end" 2 && (( R_CMD == -1 )); then pass "Insert Stop on an action: a stop step at its end"; else fail "no stop row [$(grep '^ACTPR ' "$DK_DUMP" | cut -d' ' -f4,8- | tr '\n' '|')]"; fi
if ap_find_cmd 1803; then
    ap_menu 9110 "Insert Stop..." "$R_ROW"; ap_name "QA pause"
    screenshot "actions-palette-stops"
fi
ORD=$(setf | awk '/^ACTION 1 [01] Mirror Both Ways$/ {on=1; next} /^(ACTION|SET) / {on=0} on && /^STEP / {printf "%s,", $2}')
[[ "$ORD" == "1803,-1,1804,-1," ]] && setf | grep -q '^STEP -1 1 0 QA pause$' && pass "the file: Flip H, STOP QA pause, Flip V, STOP QA end" || fail "steps in the file: '$ORD' [$(setf | grep -A6 'Mirror Both Ways' | tr '\n' '|')]"
ap_find "Mirror Both Ways" 1; ap_click "$R_ROW" name
park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-s0"; S0="$SNAP_RESULT"
ap_btn 3; screenshot "actions-palette-stop-message"
key Return; wait_for 1.0 "CONTINUE"
key Tab; wait_for 0.3 "STOP"; key Return; wait_for 1.0 "STOP"; dk_park
ap_read
(( A_RUN == 2 && A_HALT != 0 && A_PLAY == 0 )) && pass "CONTINUE at the first stop, STOP at the last: ran 2, halted" || fail "play 1: ran '$A_RUN' halted '$A_HALT' playing '$A_PLAY'"
park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-s1"
assert_regions_differ "$S0" "$SNAP_RESULT" "the steps before the STOP ran"
ap_btn 3; key Tab; wait_for 0.3 "STOP"; key Return; wait_for 1.0 "STOP"; dk_park
ap_read
(( A_RUN == 1 && A_HALT != 0 )) && pass "STOP at the first stop: ran 1 (Flip H only)" || fail "play 2: ran '$A_RUN' halted '$A_HALT'"
key ctrl+z; wait_for 0.8 "undo"; key ctrl+z; wait_for 0.8 "undo"; park_mouse
snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-s2"
assert_regions_same "$S0" "$SNAP_RESULT" "two Ctrl+Z undo both plays (a stopped play is one undo step)"
ap_find "QA pause" 2; ap_click "$R_ROW" name; ap_btn 6
ap_find "QA end" 2; ap_click "$R_ROW" name; ap_btn 6
! ap_find "QA pause" 2 && ! ap_find "QA end" 2 && ! setf | grep -q '^STEP -1 ' && pass "DELETE removes the stops (no asking), from the file too" || fail "stops left [$(setf | grep '^STEP -1' | tr '\n' '|')]"
ap_find "Mirror Both Ways" 1; ap_click "$R_ROW" fold # (fold it again: the rows below as before)

# --- 5d. action keys ----------------------------------------------------------------------------------
# the Rebind Key box is modal: it writes its buttons to DOCK_DUMP.ctrlkey (dialog px = viewport px here)
ak_ok() { local x y clr ok can by bw bh
    if [[ ! -s "$DK_DUMP.ctrlkey" ]]; then fail "the Rebind Key box wrote no geometry"; key Escape; wait_for 0.6 "closed"; return 1; fi
    read -r _ x y _ clr ok can by bw bh <<< "$(tr -d '\r' < "$DK_DUMP.ctrlkey")"
    click $(( x + ok + bw / 2 )) $(( y + by + bh / 2 )); wait_for 1.0 "OK"; dk_park; dk_settle; }
ak_line() { grep -m1 "^ACTPK " "$DK_DUMP"; }
BIND_F="${QA_CONFIG_DIR:-/nonexistent}/DRAW.bindings"
rm -f "$DK_DUMP.ctrlkey"
ap_find "QA Invert" 1
ap_menu 9111 "Assign Key..." "$R_ROW"
wait_for 0.6 "the Rebind Key box"; screenshot "actions-palette-key-box"
key F9; wait_for 0.5 "F9"
screenshot "actions-palette-key-f9"
ak_ok
ap_find "QA Invert" 1; QN=$R_NODE
read -r _ K_NODE K_SLOT K_TXT <<< "$(ak_line)"
[[ "$K_NODE" == "$QN" && "$K_SLOT" == 1 && "$K_TXT" == F9 ]] && pass "Assign Key...: QA Invert holds action key 1 = F9" || fail "ACTPK '$(ak_line)' (QA Invert is node $QN)"
setf | grep -A1 '^ACTION 1 1 QA Invert$' | grep -qx 'KEY 1' && pass "the set's file: KEY 1 after the action" || fail "file: $(setf | grep -A2 '^ACTION 1 1 QA Invert$' | tr '\n' '|')"
if [[ -n "${QA_CONFIG_DIR:-}" ]]; then
    grep -q '^2740 17152 ' "$BIND_F" && pass "the key is a bind: DRAW.bindings 2740 17152 (F9)" || fail "DRAW.bindings: $(tr '\n' '|' < "$BIND_F" 2>/dev/null)"
fi
screenshot "actions-palette-key-row"
park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-k0"; K0="$SNAP_RESULT"
ap_read; R0=$A_RUN
key F9; wait_for 1.0 "F9 plays"; dk_park
ap_read; park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-k1"; K1="$SNAP_RESULT"
assert_regions_differ "$K0" "$K1" "F9 played QA Invert (the picture inverted)"
grep -q '^HISTPR [0-9]* [0-9]* Action: QA Invert' "$DK_DUMP" && pass "an undo step 'Action: QA Invert'" || fail "History rows: $(grep '^HISTPR ' "$DK_DUMP" | cut -d' ' -f4- | tail -3 | tr '\n' '|')"
ap_menu 9109 "Reload Action Sets"
ap_find "QA Invert" 1
read -r _ K_NODE K_SLOT K_TXT <<< "$(ak_line)"
[[ "$K_NODE" == "$R_NODE" && "$K_TXT" == F9 ]] && pass "Reload: it still has F9" || fail "after Reload: ACTPK '$(ak_line)'"
key F9; wait_for 1.0 "F9 plays"; dk_park; park_mouse
snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-k2"
assert_regions_same "$K0" "$SNAP_RESULT" "F9 again: inverted back"
ap_find "QA Invert" 1
ap_menu 9112 "Clear Key" "$R_ROW"
[[ -z "$(ak_line)" ]] && ! setf | grep -q '^KEY ' && pass "Clear Key: no key, none in the file" || fail "after Clear Key: ACTPK '$(ak_line)', file KEY lines $(setf | grep -c '^KEY ')"
if [[ -n "${QA_CONFIG_DIR:-}" ]]; then
    grep -q '^2740 -1 ' "$BIND_F" && pass "and the bind is let go (2740 -1)" || fail "DRAW.bindings: $(tr '\n' '|' < "$BIND_F" 2>/dev/null)"
fi
key F9; wait_for 1.0 "F9"; dk_park; park_mouse
snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-k3"
assert_regions_same "$K0" "$SNAP_RESULT" "F9 now plays nothing"

# --- 5e. batch --------------------------------------------------------------------------------------
AB_IN="$DRAW_ROOT/QA/.actions-batch-in"; AB_OUT="$AB_IN/done"
rm -rf "$AB_IN"; mkdir -p "$AB_IN"
magick -size 40x30 gradient:red-blue "PNG32:$AB_IN/one.png"
magick -size 24x24 "xc:#30a050" -fill white -draw "rectangle 4,4 12,12" "PNG32:$AB_IN/two.png"
echo "not an image" > "$AB_IN/notes.txt"
park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-b0"; B0="$SNAP_RESULT"
ap_find "QA Invert" 1
ap_menu 9113 "Batch..." "$R_ROW"
wait_for 0.8 "the folder box"; key ctrl+a; type_text "$AB_IN"; wait_for 0.3 "typed"; key Return
wait_for 0.8 "the output box"; screenshot "actions-palette-batch-out"; key ctrl+a; type_text "$AB_OUT"; wait_for 0.3 "typed"; key Return
wait_for 0.8 "PNG / DRAW"; screenshot "actions-palette-batch-format"; key Return
wait_for 3.0 "the batch"; dk_park; dk_settle; ap_read
NB=$(ls "$AB_OUT"/*.png 2>/dev/null | wc -l)
(( NB == 2 )) && [[ -f "$AB_OUT/one.png" && -f "$AB_OUT/two.png" ]] && (( A_BFAIL == 0 )) && pass "Batch...: one.png + two.png written to the output folder (notes.txt skipped)" || fail "Batch: $NB PNGs [$(ls "$AB_OUT" 2>&1 | tr '\n' ' ')] failed '$A_BFAIL'"
for f in one two; do
    magick "$AB_IN/$f.png" -channel RGB -negate +channel "PNG32:$AB_IN/.$f-neg.png" 2>/dev/null
    ae=$(magick compare -metric AE "$AB_OUT/$f.png" "$AB_IN/.$f-neg.png" null: 2>&1 | awk '{print $1}')
    [[ "$ae" == 0 ]] && pass "$f.png: the action ran on it (inverted, pixel for pixel)" || fail "$f.png differs from its negative ($ae pixels)"
done
park_mouse; snap_region $(( DX - 20 )) $(( DY - 20 )) 41 41 "ap-b1"
assert_regions_same "$B0" "$SNAP_RESULT" "the document open before the batch is back (its view too)" 0
rm -rf "$AB_IN"

# --- 5f. tool steps ----------------------------------------------------------------------------------
key ctrl+shift+n; wait_for 0.8 "a new layer"; dk_park
TX=$(( DX - 40 )); TY=$(( DY - 30 )); TW=101; TH=81
park_mouse; snap_region $TX $TY $TW $TH "ap-t0"; T0="$SNAP_RESULT"
ap_find "Default Actions" 0; ap_click "$R_ROW" name
ap_btn 5; ap_name "QA Tools"
key b; wait_for 0.3 "brush"; drag $(( DX - 30 )) $(( DY + 25 )) $(( DX + 30 )) $(( DY + 25 )); wait_for 0.6 "stroke"
key l; wait_for 0.3 "line"; drag $(( DX - 30 )) $(( DY + 35 )) $(( DX + 30 )) $(( DY + 45 )); wait_for 0.6 "line"
key r; wait_for 0.3 "rect"; drag $(( DX - 20 )) $(( DY - 25 )) $(( DX + 20 )) $(( DY - 5 )); wait_for 0.6 "rect"
key c; wait_for 0.3 "ellipse"; drag $(( DX + 30 )) $(( DY - 25 )) $(( DX + 50 )) $(( DY - 5 )); wait_for 0.6 "ellipse"
key f; wait_for 0.3 "fill"; click "$DX" $(( DY - 15 )); wait_for 0.8 "fill"
key b; wait_for 0.3 "brush again"
dk_park; ap_btn 1
park_mouse; snap_region $TX $TY $TW $TH "ap-t1"; T1="$SNAP_RESULT"
screenshot "actions-palette-tools-recorded"
assert_regions_differ "$T0" "$T1" "the five tools drew"
NT=$(steps_of "QA Tools")
TOOLS=$(setf | awk '/^ACTION 1 1 QA Tools$/ {on=1; next} /^(ACTION|SET) / {on=0} on && /^PARAM TOOL=/ {sub(/^PARAM TOOL=/, ""); printf "%s,", $0}')
(( NT == 5 )) && [[ "$TOOLS" == "1,4,7,8,2," ]] && pass "5 tool steps: brush, line, rectangle, ellipse, fill (TOOL= 1 4 7 8 2)" || fail "QA Tools: $NT steps, tools '$TOOLS' [$(setf | grep -A3 '^STEP -2' | cut -c1-60 | tr '\n' '|')]"
setf | grep -q '^PARAM PTS=[0-9-]*,[0-9-]* ' && setf | grep -q '^STEP -2 1 0 Line [0-9-]*,[0-9-]* - [0-9-]*,[0-9-]*$' && pass "a brush stroke keeps its points (PTS=), a line its ends" || fail "file: $(setf | grep -E '^(STEP -2|PARAM PTS)' | cut -c1-70 | tr '\n' '|')"
for _u in 1 2 3 4 5; do key ctrl+z; wait_for 0.5 "undo"; done
park_mouse; snap_region $TX $TY $TW $TH "ap-t2"
assert_regions_same "$T0" "$SNAP_RESULT" "five Ctrl+Z: the layer is empty again" 0
ap_find "QA Tools" 1; ap_click "$R_ROW" name
ap_btn 3; ap_read
(( A_RUN == 5 && A_SKIP == 0 )) && pass "PLAY: 5 tool steps drawn" || fail "PLAY QA Tools: ran $A_RUN, skipped $A_SKIP"
park_mouse; snap_region $TX $TY $TW $TH "ap-t3"
assert_regions_same "$T1" "$SNAP_RESULT" "the played picture is the recorded one" 40
screenshot "actions-palette-tools-played"
key ctrl+z; wait_for 0.8 "undo the play"; park_mouse
snap_region $TX $TY $TW $TH "ap-t4"
assert_regions_same "$T0" "$SNAP_RESULT" "ONE Ctrl+Z undoes all five" 0

# --- 6. fold -------------------------------------------------------------------------------------------
# the list followed the selection down (10 rows now): wheel it back to the top so row 1 is on screen
ap_read; for _i in 1 2 3 4 5 6 7 8 9 10 11 12; do (( A_SC > 0 )) || break; scroll_up "$(vx $(( A_X + 60 )))" "$(vy $(( A_LY + 4 )))"; wait_for 0.3 "list up"; dk_park; ap_read; done
(( A_SC == 0 )) || fail "list still scrolled ($A_SC) before the fold checks"
RA0=$A_RA
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
# its title bar is its own header, in its surface: it follows the Scale (Rick 2026-11-22:
# the dock strip it had stayed at the display scale)
title_h() { dk_p actions; (( P_TW == 0 && P_HH > 0 && P_HY == P_Y )); }
title_h && HH0=$P_HH || fail "at Auto: no own title bar (handle h $P_HH, tab w $P_TW, y $P_HY vs $P_Y)"
pick_scale 21
surf "$DP_ACTIONS"
[[ "$S_ON" == -1 && "$S_K" == 1 ]] && pass "Scale 1x: its own surface (k $S_K)" || fail "Scale 1x: PSURF '$(grep "^PSURF $DP_ACTIONS " "$DK_DUMP")'"
grep -q '^ACTIONS_PANEL_SCALE=1\b' "$QA_CFG" && pass "ACTIONS_PANEL_SCALE=1 saved" || fail "saved '$(grep '^ACTIONS_PANEL_SCALE' "$QA_CFG")'"
ap_click 1 fold; ap_read
(( A_RA == 1 )) && pass "at 1x a click lands (folded)" || fail "at 1x: $A_RA rows"
ap_click 1 fold
screenshot "actions-palette-1x"
title_h && (( P_HH < HH0 )) && pass "Scale 1x: its title bar scales with it ($HH0 -> $P_HH px)" || fail "Scale 1x: title bar $HH0 -> $P_HH px (tab w $P_TW)"
pick_scale 23
title_h && (( P_HH > HH0 )) && pass "Scale 3x: so does its title bar ($HH0 -> $P_HH px)" || fail "Scale 3x: title bar $HH0 -> $P_HH px (tab w $P_TW)"
screenshot "actions-palette-3x"
pick_scale 20
dk_move_expect actions float
ap_read
(( A_VIS != 0 && A_RA > 1 )) && pass "floating, it still lists ($A_RA rows)" || fail "floating: vis $A_VIS, $A_RA rows"
screenshot "actions-palette-float"
dk_p actions
click $(( P_FX + P_FW - 6 )) $(( P_FY + 3 )); wait_for 0.8 "close"; dk_park; dk_settle
dk_p actions
(( P_SHOWN == 0 )) && pass "its [x] closes it" || fail "the [x] did not close it (shown $P_SHOWN)"
pcmd "View: Actions"
dk_p actions
(( P_SHOWN != 0 )) && dk_floating actions && pass "View: Actions brings it back, floating where it was" || fail "View: Actions: shown $P_SHOWN fl $P_FL"

rm -rf "$ACTDIR"
assert_no_crash
