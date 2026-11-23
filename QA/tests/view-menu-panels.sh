#!/bin/bash
# =============================================================================
# view-menu-panels.sh — QA test: the panels' show / hide rows live in VIEW > PANELS
# (GUI/MENUBAR MENUBAR_view_panel, the generic category flyout).
# Rick 2026-11-23: "please move the panels from VIEW -> into VIEW -> PANELS -> ...";
# "the view menu is so large it's requiring scrolling".
#   1. the View menu itself no longer lists the panels (Menu Bar 411, Layer Panel 404,
#      Toolbox 401, Edit Bar 435, Character Map 2050, Browser 2022, History 2700 ...);
#      PREVIEW WINDOW > (2012, its own menu) and CANVAS RECORDING... (2710, not a panel:
#      Rick 2026-11-23) stay; the menu is shorter than the window
#   2. hovering PANELS opens its flyout with every panel, checked when it shows, wide
#      enough for the hotkey column (the generic flyout sized to its labels only)
#      (Menu Bar / Toolbox / Layer Panel on, History off)
#   3. a click on HISTORY in the flyout shows the History palette; reopened, it is checked
# Dump: MROOT view x w; MENU x y w h; MENUI <ids> (the dropdown's rows, 0 = a divider,
# -1 = a flyout row); MENUG x y w h <id:checked>... (the open flyout); HISTP visible ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE HISTORY_PANEL=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

hp_vis() { awk '$1 == "HISTP" {print $2; exit}' "$DK_DUMP"; }
view_open() {
    dk_park; dk_settle
    read -r _ _ VX VW <<< "$(grep -m1 '^MROOT view ' "$DK_DUMP")"
    click $(( VX + VW / 2 )) 6; wait_for 0.6 "VIEW menu open"
    for _w in $(seq 1 30); do grep -q '^MENUI' "$DK_DUMP" && break; sleep 0.1; done
    read -r _ MX MY MW MH <<< "$(grep -m1 '^MENU ' "$DK_DUMP")"
    VI=" $(grep -m1 '^MENUI' "$DK_DUMP" | cut -d' ' -f2-) "
}
# y of the first row with id $1 in the open dropdown (rows from MENU y + 3: items 12, dividers 5)
row_y() {
    local y=$(( MY + 3 )) id
    for id in $VI; do
        [[ "$id" == "$1" ]] && { echo $(( y + 6 )); return; }
        [[ "$id" == 0 ]] && y=$(( y + 5 )) || y=$(( y + 12 ))
    done
}
panels_open() { # hover the PANELS row -> G_X G_Y G_W G_H GI (" id:checked ... ")
    local py; py=$(row_y -1)
    hover $(( MX + 30 )) "$py"; sleep 0.2; hover $(( MX + 32 )) "$py"; wait_for 0.6 "PANELS flyout"
    for _w in $(seq 1 30); do grep -q '^MENUG' "$DK_DUMP" && break; sleep 0.1; done
    read -r _ G_X G_Y G_W G_H _ <<< "$(grep -m1 '^MENUG' "$DK_DUMP")"
    GI=" $(grep -m1 '^MENUG' "$DK_DUMP" | cut -d' ' -f6-) "
}
grow_y() { # y of id $1 in the flyout (rows from MENUG y + 2)
    local y=$(( G_Y + 2 )) e
    for e in $GI; do
        [[ "${e%%:*}" == "$1" ]] && { echo $(( y + 6 )); return; }
        [[ "${e%%:*}" == 0 ]] && y=$(( y + 5 )) || y=$(( y + 12 ))
    done
}

info "=== VIEW > PANELS ==="
wait_for 1.0 "settle"
key Escape

# --- 1. the View menu without the panels ---------------------------------------------------------
view_open
screenshot "view-menu"
LEFT=""
for a in 411 404 401 2472 2473 402 435 449 2050 2021 2023 2024 2028 2022 2700; do [[ "$VI" == *" $a "* ]] && LEFT="$LEFT $a"; done
[[ -z "$LEFT" ]] && pass "the View menu no longer lists the panels" || fail "still in View:$LEFT [$VI]"
[[ "$VI" == *" -1 2012 2710 "* ]] && pass "PANELS >, PREVIEW WINDOW > (its own menu), CANVAS RECORDING... (not a panel)" || fail "no PANELS / PREVIEW WINDOW / CANVAS RECORDING rows: [$VI]"
[[ "$VI" == *" 453 0 -1 "* ]] && pass "PANELS right under FULLSCREEN" || fail "PANELS row placement: [$VI]"
(( MY + MH < 700 )) && pass "the View menu is ${MH} px tall (ends at y $(( MY + MH )), no scrolling)" || fail "View menu ${MH} px tall at y $MY"

# --- 2. the PANELS flyout ------------------------------------------------------------------------------
panels_open
screenshot "view-menu-panels"
MISS=""
for a in 411 404 401 2472 2473 402 434 435 449 2050 2021 2023 2024 2028 2022 2700; do [[ "$GI" == *" $a:"* ]] || MISS="$MISS $a"; done
[[ -n "$G_W" && -z "$MISS" ]] && pass "PANELS lists every panel (flyout ${G_W}x$G_H)" || fail "PANELS flyout lacks:$MISS [$GI]"
# room for the hotkey column: label-only width was 119 px and ADVANCED COLOR PICKER ran into CTRL+SHIFT+M
(( ${G_W:-0} >= 180 )) && pass "the flyout is wide enough for labels + hotkeys (${G_W} px)" || fail "flyout ${G_W} px wide: a long label runs into its hotkey"
[[ "$GI" == *" 411:-1 "* && "$GI" == *" 401:-1 "* && "$GI" == *" 404:-1 "* ]] && pass "Menu Bar, Toolbox, Layer Panel checked (they show)" || fail "checks: [$GI]"
[[ "$GI" == *" 2700:0 "* ]] && pass "History unchecked (hidden)" || fail "History check: [$GI]"
LASTG=$(awk '{print $NF}' <<< "$GI")
[[ "$GI" != *" 2710:"* && "${LASTG%%:*}" == 2022 ]] && pass "no Canvas Recording in PANELS; it ends at BROWSER (no trailing divider)" || fail "PANELS ends with '$LASTG': [$GI]"

# --- 3. HISTORY from the flyout ---------------------------------------------------------------------
HY=$(grow_y 2700)
hover $(( G_X + 30 )) "$HY"; sleep 0.2
click $(( G_X + 30 )) "$HY"; wait_for 0.8 "History on"
dk_park; dk_settle
[[ "$(hp_vis)" != 0 ]] && pass "PANELS > HISTORY shows the History palette" || fail "History did not show (HISTP '$(hp_vis)')"
view_open
panels_open
[[ "$GI" == *" 2700:-1 "* ]] && pass "... and PANELS shows it checked" || fail "History check after: [$GI]"
key Escape; wait_for 0.3 "close"; key Escape; wait_for 0.3 "close"
dk_park
assert_no_crash
