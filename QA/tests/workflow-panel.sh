#!/bin/bash
# =============================================================================
# workflow-panel.sh — QA test: the workflow buttons in a dock panel of their own
# (Rick, 2026-11-14: "Workspace buttons: ungang from the toolbox into their
# own panel with the organizer's features + docking options; one column = the
# workspace's first letter only; scalable like the rest").
#
#  - by default docked in the toolbox's column above it, at its width; the
#    toolbox starts on the panel's last row (one shared frame row)
#  - right-click a button: its menu has the panel's Float and Scale; floating,
#    the buttons still switch workspace; Dock Back puts it over the toolbox
#  - right-click between the buttons: the panel's own handle menu; Move to
#    Left Edge = a column of its own, one button wide: each button shows only
#    its workspace's first letter, and still switches
#  - Scale 1x (WORKFLOW_PANEL_SCALE=1): its own surface, clicks still land;
#    Auto again
#  - an arrangement saved before the panel existed (no "workflow" in it): it
#    goes above the docked toolbox (saved with it at once), or over the
#    toolbox's window when that floats
#
# Dump: WF on n x y w h active cols laidOut | WFB i x y w h lit id label shown |
# P / SLOT / COL (QA/dock-lib.sh) | DMENU open panel hover x y w n |
# DMENUR row value y h checked | PSURF id on k ... | WSA <workspace>.
# Menu values: 1 Move to Left Edge, 5 Float, 6 Dock Back, 20 Scale Auto,
# 21 Scale 1x (GUI/DOCK.BI DOCK_ACT_*); 3901+ the buttons' own (GUI/WORKFLOW.BI).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKFLOW_BAR=1 WORKSPACES_DIR=/tmp/draw-qa-ws-none TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Workflow buttons: their own panel ==="

DP_WORKFLOW=8
wf() { read -r _ WF_ON WF_N WF_X WF_Y WF_W WF_H WF_ACT WF_COLS WF_LAID <<< "$(grep -m1 '^WF ' "$DK_DUMP")"; }
wfb() { read -r _ _ B_X B_Y B_W B_H B_LIT B_ID B_LBL B_SHOWN <<< "$(grep -m1 "^WFB $1 " "$DK_DUMP")"; }
shown() { grep '^WFB ' "$DK_DUMP" | awk '{print $10}' | paste -sd, -; }
wsa() { awk '$1=="WSA" {print $2; exit}' "$DK_DUMP"; }
wf_s() { wf; echo "WF on $WF_ON n $WF_N at $WF_X,$WF_Y ${WF_W}x$WF_H cols $WF_COLS laid $WF_LAID; shown [$(shown)]; ws $(wsa)"; }
saved() { tr -d '\r' < "$QA_CFG" | grep -q "^$1=$2\$" && pass "$1=$2 saved" || fail "$1: saved '$(grep "^$1=" "$QA_CFG")', want $2"; }
# press button N; wait for the workspace switch
press() { wfb "$1"; click $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); wait_for 1.4 "workflow button $1"; dk_park; dk_settle; wf; }
# right-click (X, Y) -> the dock menu
rmenu() { right_click "$1" "$2"; wait_for 0.6 "menu"; dk_settle; read -r _ M_OPEN M_PANEL _ M_X M_Y M_W M_N <<< "$(grep -m1 '^DMENU ' "$DK_DUMP")"; }
has_row() { awk -v v="$1" '$1=="DMENUR" && $3==v {f=1} END {exit !f}' "$DK_DUMP"; }
# click the open menu's row with VALUE
pick() {
    local row ry rh
    row=$(awk -v v="$1" '$1=="DMENUR" && $3==v {print $4, $5; exit}' "$DK_DUMP")
    if [[ -z "$row" ]]; then fail "$2: no menu row $1"; key Escape; return 1; fi
    read -r ry rh <<< "$row"
    click $(( M_X + 20 )) $(( ry + rh / 2 )); wait_for 0.9 "$2"; dk_park; dk_settle; wf
}
btn_menu() { wfb "$1"; rmenu $(( B_X + B_W / 2 )) $(( B_Y + B_H / 2 )); }
switch_and_back() { # BUTTON WORKSPACE LABEL
    press "$1"
    [[ "$(wsa)" == "$2" ]] && pass "$3: button $1 switches to $2" || fail "$3: button $1 -> workspace '$(wsa)' ($(wf_s))"
    press "$1"
    [[ "$(wsa)" == default ]] && pass "$3: again, back to Default" || fail "$3: button $1 again -> '$(wsa)'"
}

dk_begin
wf
info "start: $(wf_s)"

# --- default: docked above the toolbox, at its width -------------------------
dk_p workflow || fail "no workflow panel in the dump"
(( WF_ON == -1 && WF_LAID == -1 && P_SLOT > 0 )) && pass "the workflow buttons are a docked panel of their own" || fail "not docked: $(wf_s) slot $P_SLOT"
dk_expect_stacked workflow toolbox
WPW=$P_W; dk_p toolbox; TPW=$P_W; TPY=$P_Y
(( WPW == TPW )) && pass "as wide as the toolbox ($WPW px)" || fail "width $WPW, the toolbox $TPW"
(( TPY == WF_Y + WF_H - 1 )) && pass "the toolbox starts on its last row (one frame row shared)" || fail "toolbox y $TPY, workflow $WF_Y+$WF_H"
[[ "$(shown)" == "SPRITE,ANIMATE,SCENE,ANNOTATE" && "$WF_COLS" == 2 ]] && pass "two labelled columns" || fail "labels: $(wf_s)"
dk_check "docked over the toolbox"
screenshot "workflow-panel-docked"

# --- a button's menu: Float -----------------------------------------------------
btn_menu 1
[[ "$M_OPEN" == -1 && "$M_PANEL" == "$DP_WORKFLOW" ]] && pass "right-click a button: the menu (panel $M_PANEL)" || fail "button menu: DMENU open '$M_OPEN' panel '$M_PANEL'"
has_row 4001 && pass "it picks the button's workspace" || fail "no workspace rows"
has_row 5 && has_row 20 && has_row 21 && pass "and has the panel's Float and Scale" || fail "no Float / Scale rows"
pick 5 "Float"
dk_expect_floating workflow
grep -qi '^DOCK_FLOAT_WORKFLOW=' "$QA_CFG" && pass "floating, saved (DOCK_FLOAT_WORKFLOW)" || fail "DOCK_FLOAT_WORKFLOW not saved"
dk_p toolbox; (( P_Y < TPY )) && pass "the toolbox moves up into the room (y $TPY -> $P_Y)" || fail "toolbox y $P_Y (was $TPY)"
switch_and_back 1 sprite "floating"
dk_check "floating"

btn_menu 1
pick 6 "Dock Back"
dk_expect_stacked workflow toolbox

# --- between the buttons: the panel's handle menu; a column of its own -------
wfb 1
rmenu $(( B_X + B_W / 2 )) $(( B_Y + B_H ))
[[ "$M_OPEN" == -1 && "$M_PANEL" == "$DP_WORKFLOW" ]] && has_row 1 && ! has_row 3902 && pass "right-click between the buttons: the panel's handle menu" || fail "gap: DMENU open '$M_OPEN' panel '$M_PANEL', Move row $(has_row 1 && echo yes || echo no)"
pick 1 "Move to Left Edge"
dk_expect_side workflow 1
dk_p workflow; wfb 1
[[ "$WF_COLS" == 1 && "$(shown)" == "S,A,S,A" ]] && pass "one button wide: one column, first letters only" || fail "own column: $(wf_s)"
(( WF_H == 4 * (B_H + 1) + 1 )) && pass "four rows ($WF_H px)" || fail "height $WF_H for button height $B_H"
(( P_W < WPW )) && pass "narrower than in the toolbox's column ($P_W < $WPW px)" || fail "width $P_W (toolbox column $WPW)"
dk_check "a column of its own"
screenshot "workflow-panel-letters"
switch_and_back 2 animate "first letters"

# --- its own Scale --------------------------------------------------------------
W0=$WF_W
btn_menu 1
pick 21 "Scale 1x"
saved WORKFLOW_PANEL_SCALE 1
read -r _ _ S_ON S_K _ <<< "$(grep -m1 "^PSURF $DP_WORKFLOW " "$DK_DUMP")"
[[ "$S_ON" == -1 && "$S_K" == 1 ]] && pass "1x: its own surface (k 1)" || fail "1x: PSURF '$(grep "^PSURF $DP_WORKFLOW " "$DK_DUMP")'"
(( WF_W < W0 )) && pass "1x: smaller on screen ($W0 -> $WF_W px)" || fail "1x: width $W0 -> $WF_W"
switch_and_back 1 sprite "1x"
btn_menu 1
pick 20 "Scale Auto"
saved WORKFLOW_PANEL_SCALE 0
grep -q "^PSURF $DP_WORKFLOW " "$DK_DUMP" && fail "Auto: still a surface" || pass "Auto: drawn into the viewport again"
assert_no_crash

# --- an arrangement from before the panel existed --------------------------------
adopt_launch() { # SPEC LINES...
    draw_quit
    draw_settle
    sed -i '/^DOCK_/d; /^\[DOCK\]/d' "$QA_CFG"
    { echo "[DOCK]"; printf '%s\n' "$@"; } >> "$QA_CFG"
    draw_launch 15
    wait_for 1.5 "launched"
    dk_begin
    wf
}
adopt_launch "DOCK_CUSTOM=1" "DOCK_LEFT_1=AUTO; layers" "DOCK_RIGHT_1=AUTO; toolbox | organizer | drawer"
info "old tree: $(dk_tree)"
dk_expect_stacked workflow toolbox
(( WF_LAID == -1 )) && pass "old tree: the buttons are laid out" || fail "old tree: $(wf_s)"
grep -qE '^DOCK_RIGHT_1=.*workflow \| toolbox' "$QA_CFG" && pass "old tree: saved with the panel ($(grep '^DOCK_RIGHT_1=' "$QA_CFG"))" || fail "old tree: saved '$(grep '^DOCK_RIGHT_1=' "$QA_CFG")'"
dk_check "an old tree"

adopt_launch "DOCK_CUSTOM=1" "DOCK_LEFT_1=AUTO; layers" "DOCK_RIGHT_1=AUTO; organizer | drawer" "DOCK_FLOAT_TOOLBOX=300,160,98,180"
info "old tree, the toolbox floating: $(dk_tree)"
dk_expect_floating workflow
dk_p workflow; WFX=$P_FX; WFY=$P_FY; WFH=$P_FH; dk_p toolbox
(( WFX == P_FX && WFY + WFH <= P_FY + 1 )) && pass "the toolbox floating: the buttons float over its window ($WFX,$WFY h $WFH; toolbox $P_FX,$P_FY)" || fail "floating: workflow $WFX,$WFY h $WFH, toolbox $P_FX,$P_FY"
(( WF_LAID == -1 )) && pass "and are laid out" || fail "floating: $(wf_s)"
screenshot "workflow-panel-adopt-float"
assert_no_crash
assert_window_exists
info "=== Workflow buttons: their own panel: done ==="
