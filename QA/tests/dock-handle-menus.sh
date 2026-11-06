#!/bin/bash
# =============================================================================
# dock-handle-menus.sh — QA test: right-clicking a DOCKED panel's handle opens
# the dock menu (Float / Dock / Close...) for that panel - the layers' header,
# and a preview window stacked in the layers' column (its title bar). The
# docked layers once gave no menu (only the floating window did), and the
# preview in the layers' column could neither be dragged out nor right-clicked.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt PREVIEW_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: handle menus on docked panels Test ==="
dk_begin


menu_on() { # name what
    local name=$1 what=$2 open panel
    dk_settle
    dk_grab_point "$name" || { fail "$what: $name has no handle"; return; }
    info "$what: right-click $name's handle at $GX,$GY"
    hover "$GX" "$GY"; sleep 0.3
    right_click "$GX" "$GY"; sleep 0.6
    read -r _ open panel _ <<< "$(grep '^DMENU ' "$DK_DUMP")"
    screenshot "dock-handle-menu-$name"
    if (( open != 0 )); then pass "$what: the dock menu opens"; else fail "$what: no dock menu (DMENU $open $panel)"; fi
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

dk_p layers; (( P_SLOT > 0 )) || fail "the layers are not docked"
menu_on layers "docked layers"

dk_p preview || fail "no preview panel in the dump"
dk_move preview below layers && dk_expect_stacked layers preview
dk_check "preview below layers"
menu_on preview "preview stacked under the layers"

# and it can be dragged out of the column (floats)
float_out() {
    dk_scr
    dk_move preview float $(( (CAN_LX + CAN_RX) / 2 )) $(( (DOCK_TOP + DOCK_BOT) / 2 ))
    dk_p preview
    if (( P_SLOT == 0 )); then pass "$1: the preview drags out of the layers' column"; else fail "$1: the preview stayed docked (slot $P_SLOT)"; fi
}
float_out "below the layers"

# above the layers
dk_move preview above layers && dk_expect_stacked preview layers
menu_on preview "preview above the layers"
menu_on layers "layers under the preview"
float_out "above the layers"
dk_move preview above layers && dk_expect_stacked preview layers
gap_menu_and_drag "preview above the layers"

# a tab of the layers (the preview the active tab)
dk_move preview tab layers && dk_expect_tabs layers preview
dk_check "preview a tab of the layers"
menu_on preview "preview tabbed with the layers"
float_out "tabbed with the layers"

assert_window_exists
info "=== Dock: handle menus on docked panels Test PASSED ==="
