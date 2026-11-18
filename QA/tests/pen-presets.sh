#!/bin/bash
# =============================================================================
# pen-presets.sh — QA test: Pen Control presets (Rick 2026-11-17). Right-click
# the Pen Control panel: Pen Control Presets menu (GUI/PEN-PRESETS, shown in the
# dock's handle menu: DMENUR rows; values 1 Save, 2 Rename, 3 Delete, 4 Open,
# 100+i preset i).
#   save     Save Preset... "QA Pen ZZ" -> <data>/DRAW/PEN-PRESETS/QA Pen ZZ.pen
#   change   Toggle Smoothing (2030): the preset no longer checked
#   apply    pick it -> PEN_STAB back as saved, the row checked again
#   rename   -> "QA Pen YY" (the file follows)
#   delete   -> gone (Yes in the confirm box)
#   examples the shipped ASSETS/PRESETS/PEN presets are copied in on the first
#            open; Technical Pen applies + is checked; Raw Pen turns filters off
# [Linux / macOS] the files are checked under ${XDG_DATA_HOME:-~/.local/share}/DRAW.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE PEN_PANEL_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Pen Control presets ==="
dk_begin
PDIR="${XDG_DATA_HOME:-$HOME/.local/share}/DRAW/PEN-PRESETS"
rm -f "$PDIR/QA Pen ZZ.pen" "$PDIR/QA Pen YY.pen"

cfgv() { grep -m1 "^$1=" "$QA_CFG" | cut -d= -f2 | tr -d '\r'; }
read -r _ _ WX WY WW WH _ <<< "$(grep -m1 '^WIN pen ' "$DK_DUMP")"
if [[ -z "$WX" ]]; then fail "no Pen Control window in the dump"; assert_no_crash; exit 0; fi
PX=$(( WX + WW / 3 )); PY=$(( WY + WH * 2 / 3 ))
info "pen panel at $WX,$WY ${WW}x$WH - right-click at $PX,$PY"

pmenu() { # open the presets menu: M_* + the DMENUR rows
    dk_park; right_click "$PX" "$PY"; wait_for 0.7 "presets menu"; dk_settle
    read -r _ M_OPEN M_PANEL _ M_X M_Y M_W M_N <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"
}
rowv() { awk -v t="$1" '$1=="DMENUR" && $3==t {print $6; exit}' "$DK_DUMP"; } # checked flag of the row with value t
# a preset's menu value: 100 + its place in the list (A-Z, case-blind, as PENPR_scan sorts)
pidx() { local i; i=$(command ls "$PDIR" 2>/dev/null | grep -i '\.pen$' | sed 's/\.[pP][eE][nN]$//' | awk '{print tolower($0) "\t" $0}' | LC_ALL=C sort | cut -f2 | grep -nxF "$1" | cut -d: -f1); [[ -n "$i" ]] && echo $(( 100 + i )); }
answer() { wait_for 1.0 "dialog"; [[ -n "$1" ]] && { type_text "$1"; wait_for 0.4 "typed"; }; key Return; wait_for 1.0 "answered"; dk_park; dk_settle; }

# --- the menu --------------------------------------------------------------------
pmenu
if [[ "$M_OPEN" == -1 ]] && dk_menu_has 1 && dk_menu_has 4; then pass "right-click on the panel opens the presets menu (Save .. Open Presets)"; else fail "presets menu: open=$M_OPEN rows=[$(grep '^DMENUR' "$DK_DUMP" | awk '{print $3}' | tr '\n' ' ')]"; fi
screenshot "pen-presets-menu"
# the shipped examples (ASSETS/PRESETS/PEN) are copied in the first time the menu opens
NEX=$(command ls "$DRAW_ROOT/ASSETS/PRESETS/PEN" | grep -c '\.pen$')
NHAVE=0; for f in "$DRAW_ROOT"/ASSETS/PRESETS/PEN/*.pen; do [[ -f "$PDIR/$(basename "$f")" ]] && NHAVE=$((NHAVE + 1)); done
(( NEX > 0 && NHAVE == NEX )) && pass "the $NEX example presets are in the presets folder" || fail "example presets: $NHAVE of $NEX copied to $PDIR"
tr -d '\r' < "$PDIR/.examples-copied" 2>/dev/null | grep -qx "Technical Pen" && pass "the copied examples are recorded (.examples-copied)" || fail "no .examples-copied record"
E=$(pidx "Technical Pen")
if [[ -n "$E" ]] && dk_menu_has "$E"; then
    dk_pick "$E" "apply Technical Pen"
    [[ "$(cfgv PEN_PROC_MODE)" == 1 && "$(cfgv PEN_PROC_AMOUNT)" == 70 && "$(cfgv PEN_STAB_MODE)" == 1 ]] && pass "the Technical Pen example sets Fixed pressure 70 + Pulled String" \
        || fail "Technical Pen: PROC_MODE=$(cfgv PEN_PROC_MODE) PROC_AMOUNT=$(cfgv PEN_PROC_AMOUNT) STAB_MODE=$(cfgv PEN_STAB_MODE)"
    pmenu
    [[ "$(rowv "$E")" == -1 ]] && pass "the applied example is checked in the menu" || fail "Technical Pen row not checked"
    R=$(pidx "Raw Pen")
    if [[ -n "$R" ]]; then dk_pick "$R" "apply Raw Pen"; [[ "$(cfgv PEN_PROC)" == FALSE && "$(cfgv PEN_STAB)" == FALSE ]] && pass "Raw Pen puts the filters back off" || fail "Raw Pen: PEN_PROC=$(cfgv PEN_PROC) PEN_STAB=$(cfgv PEN_STAB)"; pmenu; fi
else
    fail "no Technical Pen row in the presets menu (value '$E')"
fi
key Escape; wait_for 0.4 "menu closed"; pmenu
dk_menu_has 2 && [[ "$(awk '$1=="DMENUR" && $3==2' "$DK_DUMP")" ]] && info "rename row present (disabled with no preset current)"

# --- save --------------------------------------------------------------------------
dk_pick 1 "Save Preset"
answer "QA Pen ZZ"
if [[ -f "$PDIR/QA Pen ZZ.pen" ]]; then pass "Save Preset wrote QA Pen ZZ.pen"; else fail "no $PDIR/QA Pen ZZ.pen"; fi
grep -q '^PEN_STAB=FALSE' "$PDIR/QA Pen ZZ.pen" 2>/dev/null && pass "the preset holds PEN_STAB=FALSE" || fail "preset content: $(head -c 300 "$PDIR/QA Pen ZZ.pen" 2>/dev/null)"
pmenu
I=$(pidx "QA Pen ZZ")
if [[ -n "$I" && "$(rowv "$I")" == -1 ]]; then pass "the saved preset is listed and checked (row $I)"; else fail "preset row: '$I' checked='$(rowv "$I")'"; fi
key Escape; wait_for 0.4 "menu closed"

# --- change a setting: no longer the preset ------------------------------------
dk_park; key question; wait_for 1.0 "command palette"; type_text "Pen Control: Toggle Smoothing"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "toggled"
[[ "$(cfgv PEN_STAB)" == TRUE ]] && pass "Toggle Smoothing: PEN_STAB=TRUE" || fail "Toggle Smoothing: PEN_STAB=$(cfgv PEN_STAB)"
pmenu
[[ "$(rowv "$I")" == 0 ]] && pass "after a change the preset is not checked" || fail "still checked after a change"

# --- apply -----------------------------------------------------------------------
dk_pick "$I" "apply QA Pen ZZ"
[[ "$(cfgv PEN_STAB)" == FALSE ]] && pass "picking the preset put PEN_STAB back to FALSE" || fail "after apply PEN_STAB=$(cfgv PEN_STAB)"
pmenu
[[ "$(rowv "$I")" == -1 ]] && pass "the preset is checked again" || fail "not checked after apply"

# --- rename ------------------------------------------------------------------------
dk_pick 2 "Rename Preset"
answer "QA Pen YY"
if [[ -f "$PDIR/QA Pen YY.pen" && ! -f "$PDIR/QA Pen ZZ.pen" ]]; then pass "Rename moved the file to QA Pen YY.pen"; else fail "rename: $(ls "$PDIR" 2>/dev/null | tr '\n' ';')"; fi

# --- delete ------------------------------------------------------------------------
pmenu
dk_pick 3 "Delete Preset"
answer ""
if [[ ! -f "$PDIR/QA Pen YY.pen" ]]; then pass "Delete removed the preset"; else fail "QA Pen YY.pen still there"; fi
rm -f "$PDIR/QA Pen ZZ.pen" "$PDIR/QA Pen YY.pen"
assert_no_crash
