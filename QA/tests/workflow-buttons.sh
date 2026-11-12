#!/bin/bash
# =============================================================================
# workflow-buttons.sh - QA test: the workflow buttons at the top of the toolbox
# (GUI/WORKFLOW, PLANS/PERSONAS.md).
#
#  - WORKFLOW_BUTTONS default sprite,animate,scene,annotate: four labelled
#    buttons above the tool buttons, which start below the strip
#  - a click switches workspace, the lit one again goes back to Default
#  - right-click: set a button's workspace, add, move, remove, hide
#  - View > Workflow Buttons / the palette's Workflow Button N
#
# Dump lines: WF on n x y w h active | WFB i x y w h lit id label |
# BTN toolbox i kind id name x y w h | DMENU open panel hover x y w n |
# DMENUR row value y h checked. Menu values (GUI/WORKFLOW.BI): 3901 add,
# 3902 remove, 3903 hide, 3904 / 3905 move left / right, 4000 + k workspace k
# (WS_LIST: Default, Current, then by name).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKFLOW_BAR=1 WORKSPACES_DIR=/tmp/draw-qa-ws-none
# =============================================================================
info "=== Workflow buttons ==="

WF_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
wf_settle() { { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2; }
wf_line() { grep -m1 "^$1" "$WF_DUMP" 2>/dev/null; }
wf_read() {
    wf_settle
    read -r _ WF_ON WF_N WF_X WF_Y WF_W WF_H WF_ACT _ <<< "$(wf_line 'WF ')"
    WF_IDS=$(grep '^WFB ' "$WF_DUMP" | awk '{print $8}' | paste -sd, -)
    WF_LABELS=$(grep '^WFB ' "$WF_DUMP" | awk '{print $9}' | paste -sd, -)
    WF_LIT=$(grep '^WFB ' "$WF_DUMP" | awk '$7 == -1 {print $8}' | paste -sd, -)
    TB_Y=$(grep -m1 '^BTN toolbox 0 ' "$WF_DUMP" | awk '{print $8}')
}
wf_s() { echo "on ${WF_ON:-?} n ${WF_N:-?} at ${WF_X:-?},${WF_Y:-?} ${WF_W:-?}x${WF_H:-?} active ${WF_ACT:-?} ids [$WF_IDS] labels [$WF_LABELS] lit [$WF_LIT] first tool y ${TB_Y:-?}"; }
wf_btn() { # N -> "x y" middle of button N
    local l; l=$(grep "^WFB $1 " "$WF_DUMP")
    read -r _ _ bx by bw bh _ <<< "$l"
    echo "$(( bx + bw / 2 )) $(( by + bh / 2 ))"
}
wf_click() { local xy; xy=$(wf_btn "$1"); click $xy; wait_for 1.2 "workflow button $1"; wf_read; }
wf_menu() { # N VALUE LABEL - right-click button N, click the row with that value
    local xy row my mh mx
    xy=$(wf_btn "$1"); right_click $xy; wait_for 0.6 "menu"; wf_settle
    read -r _ _ _ _ mx _ _ _ <<< "$(wf_line 'DMENU ')"
    row=$(grep '^DMENUR ' "$WF_DUMP" | awk -v v="$2" '$3 == v {print $4, $5; exit}')
    if [[ -z "$row" ]]; then fail "$3: no menu row with value $2 ($(grep -c '^DMENUR ' "$WF_DUMP") rows)"; key Escape; return 1; fi
    read -r my mh <<< "$row"
    click $(( mx + 20 )) $(( my + mh / 2 )); wait_for 0.8 "$3"; wf_read
}
wf_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 1.2 "Filtered"
    key Return; wait_for 1.2 "$1"; wf_read
}
has() { [[ ",$1," == *",$2,"* ]]; }

key Escape
wait_for 0.5 "settle"
wf_read
info "start: $(wf_s)"
[[ "$WF_ON" == -1 && "$WF_N" == 4 ]] && pass "four workflow buttons shown" || fail "strip: $(wf_s)"
[[ "$WF_IDS" == "sprite,animate,scene,annotate" ]] && pass "default buttons: sprite, animate, scene, annotate" || fail "ids [$WF_IDS]"
[[ "$WF_LABELS" == "SPRITE,ANIMATE,SCENE,ANNOTATE" ]] && pass "labels from the workspaces' SHORT names" || fail "labels [$WF_LABELS]"
[[ -n "$TB_Y" && -n "$WF_Y" ]] && (( TB_Y >= WF_Y + WF_H )) && pass "the tool buttons start below the strip (y $TB_Y >= $(( WF_Y + WF_H )))" || fail "tool buttons at y ${TB_Y:-?}, strip ${WF_Y:-?}+${WF_H:-?}"
[[ -z "$WF_LIT" ]] && pass "nothing lit in Default" || fail "lit in Default: [$WF_LIT]"
screenshot "workflow-buttons"

wf_click 1
[[ "$WF_ACT" == sprite && "$WF_LIT" == sprite ]] && pass "SPRITE switches to Sprite and lights" || fail "after SPRITE: $(wf_s)"
wf_click 3
[[ "$WF_ACT" == scene && "$WF_LIT" == scene ]] && pass "SCENE switches straight to Scene" || fail "after SCENE: $(wf_s)"
XS=$(wf_line 'ANIMXS ' | awk '{print $2}')
info "Scene: ANIMXS cfg ${XS:-?}"
[[ "$XS" == -1 || "$XS" == 1 ]] && pass "Scene turns the X-sheet on" || fail "Scene: X-sheet cfg '${XS:-?}'"
wf_click 3
[[ "$WF_ACT" == default && -z "$WF_LIT" ]] && pass "SCENE again goes back to Default" || fail "after SCENE again: $(wf_s)"

wf_menu 4 4001 "button 4 -> Default"
[[ "$WF_IDS" == "sprite,animate,scene,default" ]] && pass "right-click > Default sets button 4" || fail "after set: $(wf_s)"
grep -q '^WORKFLOW_BUTTONS=sprite,animate,scene,default' "$DRAW_CFG" && pass "the list is saved to the config" || fail "config: $(grep '^WORKFLOW_BUTTONS=' "$DRAW_CFG")"
wf_menu 4 3902 "remove button 4"
[[ "$WF_N" == 3 && "$WF_IDS" == "sprite,animate,scene" ]] && pass "Remove This Button" || fail "after remove: $(wf_s)"
wf_menu 1 3901 "add after button 1"
[[ "$WF_N" == 4 && "$WF_IDS" == "sprite,annotate,animate,scene" ]] && pass "Add a Button puts the first unused workspace (Annotate) after it" || fail "after add: $(wf_s)"
wf_menu 1 3905 "move button 1 right"
[[ "$WF_IDS" == "annotate,sprite,animate,scene" ]] && pass "Move Right swaps it with its neighbour" || fail "after move: $(wf_s)"

wf_menu 1 3903 "hide"
TB_ON=$TB_Y
[[ "$WF_ON" == 0 ]] && pass "Hide Workflow Buttons" || fail "after hide: $(wf_s)"
wf_cmd "workflow buttons"
[[ "$WF_ON" == -1 && "$WF_IDS" == "annotate,sprite,animate,scene" ]] && pass "View: Workflow Buttons brings them back with the same list" || fail "after show: $(wf_s)"
(( TB_ON < TB_Y )) && pass "hidden, the tool buttons move up (y $TB_ON < $TB_Y)" || fail "tool buttons y hidden $TB_ON, shown $TB_Y"
wf_cmd "workflow button 3"
[[ "$WF_ACT" == animate ]] && pass "the palette's Workflow Button 3 switches to Animate" || fail "after Workflow Button 3: $(wf_s)"
wf_cmd "workflow button 3"
[[ "$WF_ACT" == default ]] && pass "Workflow Button 3 again goes back to Default" || fail "after it again: $(wf_s)"

assert_no_crash
assert_window_exists
info "=== Workflow buttons done ==="
