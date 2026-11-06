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
    dk_move preview tab layers && dk_expect_tabs layers preview
    menu_on preview "preview tabbed with the layers"
    float_out "tabbed with the layers"
fi
assert_window_exists
info "=== Dock: handle menus in the user's layout Test PASSED ==="
