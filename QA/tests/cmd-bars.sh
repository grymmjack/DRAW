#!/bin/bash
# =============================================================================
# cmd-bars.sh — QA test: the PANELS bar and the I/O bar (GUI/CMDBARS).
# Rick 2026-11-22: "another 2 toolbars ... one for view that has all the view ->
# toggleable panels, and another for new/open/import/export - they should act just
# like advanced and edit bars"; "the bars should be called PANELS for view, and I/O
# for import/export".
#   1. PANELS_BAR / IO_BAR on: both bars show, docked, with their default buttons
#   2. PANELS bar: History's button is dim while History is hidden; a click shows the
#      History palette and lights it; a second click hides it again
#   3. I/O bar: New / Open / Import / Save / Export buttons; hovering one outlines it
#   4. View > PANELS Bar (command palette) hides the bar; again shows it
#   5. Customize Toolbars has PANELS and I/O tabs listing the bars; removing the
#      PANELS bar's first button takes it off the bar and keeps [PANELS_BAR] ORDER=
#      in the workspace CURRENT (Default stays stock)
#   6. the PANELS bar's handle menu has Customize Buttons..., which opens its tab
# Dump: CBAR <panels_bar|io_bar> wanted visible x1 y1 x2 y2 hover scroll contentH cols entries;
# BTN / BTNS / TBED / TBC (GUI/TOOLBAR-EDITOR TBED_dump$); HISTP (the History palette).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE PANELS_BAR=TRUE IO_BAR=TRUE HISTORY_PANEL=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

cb_read() { # BAR (panels_bar / io_bar) -> C_WANT C_VIS C_X1 C_Y1 C_X2 C_Y2 C_HOV C_SC C_CH C_COLS C_N
    read -r _ _ C_WANT C_VIS C_X1 C_Y1 C_X2 C_Y2 C_HOV C_SC C_CH C_COLS C_N <<< "$(grep -m1 "^CBAR $1 " "$DK_DUMP")"
}
bt_at() { awk -v p="$1" -v id="$2" 'BEGIN{r=-1} $1 == "BTN" && $2 == p && $4 == 2 && $5 == id && r < 0 {r=$3} END{print r}' "$DK_DUMP"; } # PANEL ACTION -> entry index
bt_lit() { awk -v p="$1" -v i="$2" '$1 == "BTNS" && $2 == p && $3 == i {print $5; exit}' "$DK_DUMP"; }
hp_vis() { awk '$1 == "HISTP" {print $2; exit}' "$DK_DUMP"; }
pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; dk_park; dk_settle; }

info "=== The PANELS bar and the I/O bar ==="
wait_for 1.0 "settle"
key Escape
dk_park
dk_settle

# --- 1. both bars ----------------------------------------------------------------------------
cb_read panels_bar
(( C_VIS != 0 && C_N > 20 )) && pass "the PANELS bar shows ($C_N entries, rect $C_X1,$C_Y1-$C_X2,$C_Y2)" || fail "PANELS bar: [$(grep -m1 '^CBAR panels_bar' "$DK_DUMP")]"
dk_docked panelsbar && pass "PANELS bar docked (slot $P_SLOT)" || fail "PANELS bar not docked [$(grep -m1 '^P panelsbar ' "$DK_DUMP")]"
cb_read io_bar
(( C_VIS != 0 && C_N > 10 )) && pass "the I/O bar shows ($C_N entries)" || fail "I/O bar: [$(grep -m1 '^CBAR io_bar' "$DK_DUMP")]"
dk_docked iobar && pass "I/O bar docked (slot $P_SLOT)" || fail "I/O bar not docked [$(grep -m1 '^P iobar ' "$DK_DUMP")]"
screenshot "cmd-bars"
MISS=""
for a in 411 401 404 434 435 449 2050 2021 2022 2700 2702; do [[ "$(bt_at panelsbar $a)" == -1 ]] && MISS="$MISS $a"; done
[[ -z "$MISS" ]] && pass "PANELS bar: the View panels' toggles (menu bar, toolbox, layers, preview, bars, char map, mixer, browser, History, Actions)" || fail "PANELS bar lacks:$MISS [$(tb_list panelsbar)]"
MISS=""
for a in 209 206 208 202 204 2204 2217 205 220; do [[ "$(bt_at iobar $a)" == -1 ]] && MISS="$MISS $a"; done
[[ -z "$MISS" ]] && pass "I/O bar: New, Open, Import, Save, Save As, Export PNG / Again / Selection / QB64" || fail "I/O bar lacks:$MISS [$(tb_list iobar)]"

# --- 2. PANELS bar: History on / off ------------------------------------------------------------
HI=$(bt_at panelsbar 2700)
if tb_btn panelsbar "$HI"; then
    [[ "$(hp_vis)" == 0 && "$(bt_lit panelsbar "$HI")" == 0 ]] && pass "History hidden: its button is dim" || fail "before: HISTP '$(hp_vis)' lit '$(bt_lit panelsbar "$HI")'"
    click "$BCX" "$BCY"; wait_for 0.8 "History on"; dk_park; dk_settle
    screenshot "cmd-bars-history-on"
    [[ "$(hp_vis)" != 0 ]] && pass "a click on it shows the History palette" || fail "History did not show (HISTP '$(hp_vis)')"
    [[ "$(bt_lit panelsbar "$HI")" == -1 ]] && pass "... and lights its button" || fail "button lit '$(bt_lit panelsbar "$HI")'"
    tb_btn panelsbar "$HI" ' (the bar may have moved: History docked beside it)'
    click "$BCX" "$BCY"; wait_for 0.8 "History off"; dk_park; dk_settle
    [[ "$(hp_vis)" == 0 && "$(bt_lit panelsbar "$HI")" == 0 ]] && pass "a second click hides it, the button dim again" || fail "after: HISTP '$(hp_vis)' lit '$(bt_lit panelsbar "$HI")'"
else
    fail "History's button is not drawn on the PANELS bar (entry '$HI')"
fi

# --- 3. I/O bar: hover -----------------------------------------------------------------------------
SI=$(bt_at iobar 202)
if tb_btn iobar "$SI"; then
    hover "$BCX" "$BCY"; sleep 0.2; hover $(( BCX + 1 )) "$BCY"; wait_for 0.5 "hover Save"; dk_settle
    cb_read io_bar
    [[ "$C_HOV" == "$SI" ]] && pass "hovering Save outlines it (hover $C_HOV)" || fail "I/O hover '$C_HOV' (want $SI)"
    screenshot "cmd-bars-io-hover"
    dk_park; dk_settle
    cb_read io_bar
    [[ "$C_HOV" == -1 ]] && pass "off the bar: no hover" || fail "hover stuck at '$C_HOV'"
else
    fail "Save is not drawn on the I/O bar (entry '$SI')"
fi

# --- 4. View > PANELS Bar --------------------------------------------------------------------------
pcmd "view: panels bar"
cb_read panels_bar
[[ "$C_WANT" == 0 && "$C_VIS" == 0 ]] && pass "View: PANELS Bar hides it" || fail "after the toggle: wanted '$C_WANT' visible '$C_VIS'"
pcmd "view: panels bar"
cb_read panels_bar
[[ "$C_WANT" == -1 && "$C_VIS" == -1 ]] && pass "... and shows it again" || fail "after the 2nd toggle: wanted '$C_WANT' visible '$C_VIS'"

# --- 5. Customize Toolbars: PANELS / I/O tabs ------------------------------------------------------
tb_open
tb_click tab4; tb_state
[[ "$TB_TAB" == "panelsbar" ]] && pass "tab 4 is the PANELS bar" || fail "tab 4: '$TB_TAB'"
N0=$(tb_count panelsbar)
FIRST=$(tb_list panelsbar | cut -d, -f1)
screenshot "cmd-bars-customize-panels"
tb_ls_click 0
tb_click remove
sleep 1.0; dk_settle
N1=$(tb_count panelsbar)
(( N1 == N0 - 1 )) && [[ "$(tb_list panelsbar | cut -d, -f1)" != "$FIRST" ]] && pass "<- removes its first button ($FIRST; $N0 -> $N1)" || fail "after remove: $N1 entries (was $N0), first '$(tb_list panelsbar | cut -d, -f1)'"
WSF=$(tb_ws_file)
if [[ -n "$WSF" ]] && awk '/^\[PANELS_BAR\]/ {on=1; next} /^\[/ {on=0} on && /^ORDER=/ {f=1} END {exit !f}' "$WSF"; then
    pass "kept as [PANELS_BAR] ORDER= in $(basename "$WSF")"
else
    fail "no [PANELS_BAR] ORDER= saved (workspace '$WSF')"
fi
tb_click tab5; tb_state
[[ "$TB_TAB" == "iobar" && "$TB_N" == "$(tb_count iobar)" ]] && pass "tab 5 is the I/O bar ($TB_N entries)" || fail "tab 5: '$TB_TAB' $TB_N entries"
screenshot "cmd-bars-customize-io"
tb_click reset
tb_click tab4; tb_click reset; sleep 0.6; dk_settle
(( $(tb_count panelsbar) == N0 )) && pass "Reset puts the PANELS bar's buttons back" || fail "after Reset: $(tb_count panelsbar) entries (want $N0)"
tb_click done; sleep 0.5; dk_settle

# --- 6. the handle menu ----------------------------------------------------------------------------
if dk_rmenu panelsbar; then
    if dk_menu_has 9; then # DOCK_ACT_CUSTOMIZE
        pass "its handle menu has Customize Buttons..."
        dk_pick 9 "Customize Buttons..."
        tb_state
        [[ "$TB_EDIT" == -1 && "$TB_TAB" == "panelsbar" ]] && pass "... which opens Customize Toolbars on the PANELS tab" || fail "Customize Buttons...: edit '$TB_EDIT' tab '$TB_TAB'"
        tb_click done; sleep 0.5; dk_settle
    else
        fail "no Customize Buttons... in the PANELS bar's handle menu [$(grep '^DMENUR ' "$DK_DUMP" | awk '{print $3}' | tr '\n' ' ')]"
        key Escape; wait_for 0.4 "close"
    fi
fi
dk_park
assert_no_crash
