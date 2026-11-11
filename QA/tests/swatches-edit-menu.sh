#!/bin/bash
# =============================================================================
# swatches-edit-menu.sh — QA test: the Swatches edit menu (☰ button left of
# the gear, and Shift+right-click on the grid):
#   - ☰ opens it (menu 3) with every edit; its header counts the selection;
#     Esc / the button again close it
#   - an item runs on the selection and closes the menu (DELETE)
#   - Shift+right-click on an unselected swatch selects it alone and opens the
#     menu at the pointer; on a selected one the selection stays
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-edit.gpl SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"
menu_head() { awk '$1=="SWATMI" && $3==1 {for (i=10; i<=NF; i++) printf "%s%s", $i, (i<NF ? " " : ""); print ""; exit}' "$DK_DUMP"; }

info "=== Swatches: the edit menu ==="
sw_isolate
dk_begin
sw_read; sw_expect "entries" "$SW_N" 21
sw_geo
if [[ -n "$M_X" ]] && (( M_X > B_X + B_W && M_X < E_X )); then pass "the ☰ button sits between the set name and the gear"; else fail "edit button at '$M_X' (set ends $(( B_X + B_W )), gear $E_X)"; fi

sw_menu_edit; sw_read
sw_expect "☰ opens the edit menu" "$SW_MENU" 3
for id in 201 202 203 204 205 206 207 208 209 210 211; do
    if awk -v id=$id '$1=="SWATMI" && $4==id' "$DK_DUMP" | grep -q .; then :; else fail "edit menu has no item $id"; fi
done
pass "the edit menu has items 201-211"
sw_expect "header with nothing selected" "$(menu_head)" "NOTHING SELECTED"
screenshot "swatches-edit-menu"
key Escape; dk_settle; sw_read; sw_expect "Esc closes it" "$SW_MENU" 0
sw_menu_edit; sw_menu_edit; sw_read; sw_expect "the button again closes it" "$SW_MENU" 0

# an item: DELETE on swatch 3
sw_click 3; sw_menu_edit
sw_expect "header with one selected" "$(menu_head)" "1 SELECTED"
sw_menu_click 202; sw_read
sw_expect "DELETE: entries" "$SW_N" 20
sw_expect "the menu closed" "$SW_MENU" 0
sw_cell 3; sw_expect "entry 3 is now Red 4" "$C_HEX" "870000"

# Shift+right-click an unselected swatch: it alone, the menu at the pointer
sw_click 1; sw_cell 5; PX=$(( C_X + C_W / 2 )); PY=$(( C_Y + C_H / 2 ))
with_mods shift right_click "$PX" "$PY"; dk_settle; sw_read; sw_sel
sw_expect "Shift+right-click opens the edit menu" "$SW_MENU" 3
sw_expect "Shift+right-click selects that swatch alone" "$SS_LIST" "5"
read -r _ MX MY _ <<< "$(grep '^SWATM ' "$DK_DUMP")"
if (( MX >= PX && MX <= PX + 20 && MY >= PY && MY <= PY + 20 )); then pass "the menu opens at the pointer ($MX,$MY vs $PX,$PY)"; else fail "menu at $MX,$MY, pointer $PX,$PY"; fi
sw_menu_click 203; sw_cell 5
sw_expect "LOCK from that menu locks 5" "$C_FLAGS" 1

# on a selected swatch the selection stays
sw_click 1; sw_click 3 shift
sw_cell 2; with_mods shift right_click $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); dk_settle; sw_sel
sw_expect "Shift+right-click a selected swatch keeps the selection" "$SS_LIST" "1 2 3"
sw_expect "header" "$(menu_head)" "3 SELECTED"
key Escape; dk_settle

# Shift+right-click an empty place: the menu, selection unchanged
sw_empty_xy; sw_geo; info "empty place $EX,$EY; grid $G_X,$G_Y ${G_W}x$G_H"
with_mods shift right_click "$EX" "$EY"; dk_settle; sw_read; sw_sel
sw_expect "Shift+right-click an empty place opens the menu" "$SW_MENU" 3
sw_expect "... and keeps the selection" "$SS_N" 3
sw_menu_click 209; sw_sel
sw_expect "SELECT NONE" "$SS_N" 0
sw_menu_edit; sw_menu_click 208; sw_sel
sw_expect "SELECT ALL (20 entries, the break not)" "$SS_N" 19
sw_menu_edit; sw_menu_click 210; sw_read
sw_expect "UNDO (the lock)" "$SW_N" 20
sw_menu_edit; sw_menu_click 210; sw_read
sw_expect "UNDO (the delete)" "$SW_N" 21
sw_menu_edit; sw_menu_click 211; sw_read
sw_expect "REDO" "$SW_N" 20
assert_window_exists
info "=== Swatches: the edit menu PASSED ==="
