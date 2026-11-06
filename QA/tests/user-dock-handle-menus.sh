#!/bin/bash
# =============================================================================
# user-dock-handle-menus.sh — QA test for the USER's own layout (run it with
# QA_USER_PROFILE=1 so DRAW starts from their DRAW.cfg + workspace; it also
# passes on the factory layout): right-click the handle of every panel that is
# showing - docked or floating - and the dock menu opens for it; then the
# preview grouped with the layers (below them, a tab of them) still has a menu
# and still drags out.
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: handle menus in the user's layout Test ==="
dk_begin
info "layout: $(dk_tree)"

menu_on() { # name what
    local name=$1 what=$2 open panel
    dk_settle
    dk_grab_point "$name" || { info "$what: $name has no handle (not showing)"; return; }
    hover "$GX" "$GY"; sleep 0.3
    right_click "$GX" "$GY"; sleep 0.6
    read -r _ open panel _ <<< "$(grep '^DMENU ' "$DK_DUMP")"
    if (( open != 0 )); then pass "$what: the dock menu opens (right-click at $GX,$GY)"; else
        screenshot "user-dock-no-menu-$name"; fail "$what: no dock menu (right-click at $GX,$GY)"; fi
    key Escape; sleep 0.3
    dk_park; sleep 0.3
}

# the docked preview's title bar between its FP checkbox and its minimize
# button - empty, the natural place to grab (it was no handle at all)
pv_title_gap() {
    dk_p preview
    PGX=$(( P_X + P_W - 2 * P_HH - 4 )); PGY=$(( P_HY + P_HH / 2 ))
}
gap_menu_and_drag() { # what
    local open
    dk_settle; pv_title_gap
    hover "$PGX" "$PGY"; sleep 0.3
    right_click "$PGX" "$PGY"; sleep 0.6
    read -r _ open _ <<< "$(grep '^DMENU ' "$DK_DUMP")"
    if (( open != 0 )); then pass "$1: right-clicking the empty title bar opens the dock menu ($PGX,$PGY)"; else
        screenshot "dock-preview-gap-no-menu"; fail "$1: no dock menu on the empty title bar ($PGX,$PGY)"; fi
    key Escape; sleep 0.3; dk_park; sleep 0.3
    dk_settle; pv_title_gap; dk_scr
    dk_drag "$PGX" "$PGY" $(( (CAN_LX + CAN_RX) / 2 )) $(( (DOCK_TOP + DOCK_BOT) / 2 ))
    dk_park; dk_settle
    dk_p preview
    if (( P_SLOT == 0 )); then pass "$1: dragging the empty title bar floats the preview"; else fail "$1: the preview stayed docked when dragged by its empty title bar"; fi
}

for name in $(awk '$1=="P" && $4!=0 {print $2}' "$DK_DUMP"); do
    menu_on "$name" "$name as laid out"
done

float_out() {
    dk_scr
    dk_move preview float $(( (CAN_LX + CAN_RX) / 2 )) $(( (DOCK_TOP + DOCK_BOT) / 2 ))
    dk_p preview
    if (( P_SLOT == 0 )); then pass "$1: the preview drags out"; else fail "$1: the preview stayed docked [$(dk_tree)]"; fi
}
if dk_docked layers; then
    dk_move preview below layers && dk_expect_stacked layers preview
    menu_on preview "preview below the layers"
    menu_on layers "layers above the preview"
    float_out "below the layers"
    dk_move preview above layers && dk_expect_stacked preview layers
    info "after: $(dk_tree)"
    dk_p preview; info "preview at $P_X,$P_Y ${P_W}x$P_H handle $P_HX,$P_HY ${P_HW}x$P_HH live=$P_LIVE"
    screenshot "user-dock-preview-above-layers"
    menu_on preview "preview above the layers"
    menu_on layers "layers under the preview"
    float_out "above the layers"
    dk_move preview above layers && dk_expect_stacked preview layers
    gap_menu_and_drag "preview above the layers"
    dk_move preview tab layers && dk_expect_tabs layers preview
    menu_on preview "preview tabbed with the layers"
    float_out "tabbed with the layers"
fi
assert_window_exists
info "=== Dock: handle menus in the user's layout Test PASSED ==="
