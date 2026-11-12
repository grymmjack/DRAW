#!/bin/bash
# =============================================================================
# swatches-menu-over-drawer.sh — QA test: a Swatches menu drawn over the
# Drawer's bins owns the pointer there (reported 2026-11-11: with Swatches
# docked beside the Drawer, the set list / edit / gear menus showed the bins'
# tooltip while the pointer was on the menu).
#   - a bin on its own shows the bins tooltip (TIP source 7)
#   - with the edit menu open over it: no tooltip, no AnimBrush hover on the bin
#   - the menu closed: the bin's tooltip again
#   - over the menu where it covers the dock's edge: the arrow, not the
#     dock's resize cursor (same report)
#   - a SORT chip / an item drawn over the toolbox runs, and does not also
#     click the tool under it
# Dump: TIP active source idx; SWATM x y w h rowH top; DRAWERL / DRAWERR (bins);
# ABQL hoverSlot ...
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=FALSE DRAWER_MINI_PALETTE=0 SWATCHES_VISIBLE=1 SWATCHES_X=-1 SWATCHES_Y=-1 SWATCHES_W=0 SWATCHES_H=0 SWATCHES_SCALE=0 SWATCHES_SET=QA/fixtures/swatches-edit.gpl SWATCHES_COLS=0 SWATCHES_CELL=10 SWATCHES_GAP=1 SWATCHES_STRETCH=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
source "$DRAW_ROOT/QA/swatches-lib.sh"

line() { grep -m1 "^$1 " "$DK_DUMP" 2>/dev/null; }
# centre of bin $1 as laid out now; 1 = that row is not showing
bin_xy() {
    local DL_COLS DL_VIS DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY DL_ROW0 i r c
    read -r _ DL_COLS _ DL_VIS _ _ _ DL_CX DL_CY DL_BW DL_BH DL_GX DL_GY _ <<< "$(line DRAWERL)"
    read -r _ DL_ROW0 _ <<< "$(line DRAWERR)"
    [[ -n "$DL_COLS" ]] || return 1
    i=$(( $1 - 1 )); r=$(( i / DL_COLS - DL_ROW0 )); c=$(( i % DL_COLS ))
    (( r >= 0 && r < DL_VIS )) || return 1
    BX=$(( DL_CX + c * (DL_BW + DL_GX) + DL_BW / 2 )); BY=$(( DL_CY + r * (DL_BH + DL_GY) + DL_BH / 2 ))
}
# rest the pointer at X Y long enough for a tooltip -> TIP_ACT TIP_SRC
tip_at() {
    hover "$1" "$2"; wait_for 0.3 "rest"; hover $(( $1 + 1 )) "$2"; wait_for 2.0 "tooltip delay"; dk_settle
    read -r _ TIP_ACT TIP_SRC _ <<< "$(line TIP)"
}

info "=== Swatches: a menu over the Drawer's bins ==="
sw_isolate
dk_begin

bin_xy 1 || fail "no Drawer bins in the dump"
tip_at "$BX" "$BY"
[[ "$TIP_ACT" == -1 && "$TIP_SRC" == 7 ]] && pass "a bin on its own shows the bins tooltip" \
    || fail "bin tooltip: TIP '$TIP_ACT $TIP_SRC' (wanted -1 7)"

# the right dock's inner edge (the leftmost right-side column): its resize cursor
EDGE_X=$(awk '$1=="COL" && $3==2 && $6>0 {if (m=="" || $5<m) m=$5} END {print m}' "$DK_DUMP")
EDGE_Y=$(( BY ))
cur_at() { hover "$1" "$2"; wait_for 0.2 "rest"; hover "$1" $(( $2 + 1 )); dk_settle; read -r _ CUR _ <<< "$(line CURSOR)"; }
cur_at "$EDGE_X" "$EDGE_Y"
EDGE_CUR=$CUR
[[ "$EDGE_CUR" == 8 ]] && pass "the right dock's edge (x $EDGE_X) shows the resize cursor" \
    || info "the edge at x $EDGE_X shows cursor $EDGE_CUR (wanted 8) - the cursor check below is moot"

# Shift+right-click a swatch: the edit menu at the pointer, kept on screen -
# it lands over the Drawer at the right
park_mouse; wait_for 0.5 "tooltip gone"
sw_cell 5; with_mods shift right_click $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); dk_settle; sw_read
sw_expect "the edit menu is open" "$SW_MENU" 3
read -r _ MX MY MW MH _ <<< "$(line SWATM)"
HIT=0
for b in $(seq 1 40); do
    bin_xy "$b" || continue
    if (( BX > MX + 4 && BX < MX + MW - 4 && BY > MY + 4 && BY < MY + MH - 4 )); then HIT=$b; break; fi
done
if (( HIT == 0 )); then
    fail "the menu ($MX,$MY ${MW}x$MH) covers no bin - the layout changed, move the menu"
else
    info "bin $HIT at $BX,$BY is under the menu ($MX,$MY ${MW}x$MH)"
    tip_at "$BX" "$BY"
    [[ "$TIP_ACT" == 0 ]] && pass "no tooltip over the menu where it covers a bin" \
        || fail "tooltip over the menu: TIP '$TIP_ACT $TIP_SRC' (wanted inactive)"
    read -r _ QL_HOVER _ <<< "$(line ABQL)"
    [[ -z "$QL_HOVER" || "$QL_HOVER" == 0 ]] && pass "the bin under the menu is not hovered" \
        || fail "bin hover under the menu: ABQL hoverSlot $QL_HOVER"
    sw_read; sw_expect "the menu is still open" "$SW_MENU" 3
    screenshot "swatches-menu-over-drawer"
    if (( EDGE_CUR == 8 && EDGE_X > MX + 4 && EDGE_X < MX + MW - 4 && EDGE_Y > MY && EDGE_Y < MY + MH )); then
        cur_at "$EDGE_X" "$EDGE_Y"
        sw_expect "over the menu where it covers the dock's edge: the arrow, not the resize cursor" "$CUR" 0
    else
        fail "the menu ($MX,$MY ${MW}x$MH) does not cover the dock edge at $EDGE_X,$EDGE_Y (cursor $EDGE_CUR)"
    fi

    key Escape; dk_settle; sw_read; sw_expect "Esc closes the menu" "$SW_MENU" 0
    tip_at "$BX" "$BY"
    [[ "$TIP_ACT" == -1 && "$TIP_SRC" == 7 ]] && pass "the menu closed: that bin's tooltip again" \
        || fail "bin tooltip after the menu: TIP '$TIP_ACT $TIP_SRC' (wanted -1 7)"
fi
park_mouse

# A click on a menu item / chip drawn over the toolbox does that item only:
# it must not also click the tool under it (Rick 2026-11-11: SORT > HUE
# picked the T tool) - neither on the press that closes the menu nor after.
read -r _ _ _ _ TOOL0 _ <<< "$(line VIEW)"
# the centre of where rect X Y W H overlaps a toolbox TOOL button that is not
# the current tool -> PX PY PNAME (1 = no such overlap). BTN panel idx kind id name x y w h
tool_under() {
    read -r PX PY PNAME <<< "$(awk -v x="$1" -v y="$2" -v w="$3" -v h="$4" -v cur="$TOOL0" '
        $1=="BTN" && $2=="toolbox" && $4==1 && $5!=cur {
            x1 = (x > $7 ? x : $7); x2 = (x + w < $7 + $9 ? x + w : $7 + $9)
            y1 = (y > $8 ? y : $8); y2 = (y + h < $8 + $10 ? y + h : $8 + $10)
            if (x2 - x1 >= 4 && y2 - y1 >= 4) { print int((x1 + x2) / 2), int((y1 + y2) / 2), $6; exit }
        }' "$DK_DUMP")"
    [[ -n "$PX" ]]
}
sw_cell 5; with_mods shift right_click $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); dk_settle; sw_read
sw_expect "the edit menu again" "$SW_MENU" 3
HEXA=$(sw_hexes)
FOUND=
while read -r _ _ CK CX0 CY0 CW0 CH0 CL; do
    if tool_under "$CX0" "$CY0" "$CW0" "$CH0"; then FOUND=1; break; fi
done < <(awk '$1=="SWATMC" && $2==31' "$DK_DUMP")
if [[ -z "$FOUND" ]]; then
    fail "no SORT chip lies over a toolbox tool button (menu $(line SWATM)) - move the menu"
    key Escape; dk_settle
else
    info "SORT chip $CL is over the $PNAME button at $PX,$PY"
    click "$PX" "$PY"; dk_settle; sw_read
    read -r _ _ _ _ TOOL1 _ <<< "$(line VIEW)"
    sw_expect "SORT $CL over the $PNAME button: the tool is unchanged" "$TOOL1" "$TOOL0"
    sw_expect "... the menu closed" "$SW_MENU" 0
    [[ "$(sw_hexes)" != "$HEXA" ]] && pass "... and the sort ran" || fail "SORT $CL changed nothing"
    sw_hover_panel; key ctrl+z; dk_settle
    read -r _ _ _ _ TOOLZ _ <<< "$(line VIEW)"
    sw_expect "Ctrl+Z over the panel (undo the sort): the tool is unchanged" "$TOOLZ" "$TOOL0"
fi
# an item row over the toolbox: LOCK / UNLOCK (203) on swatch 5
sw_cell 5; with_mods shift right_click $(( C_X + C_W / 2 )) $(( C_Y + C_H / 2 )); dk_settle
R=$(awk '$1=="SWATMI" && $4==203' "$DK_DUMP"); read -r _ _ _ _ _ RX RY RW RH _ <<< "$R"
if [[ -n "$RX" ]] && tool_under "$RX" "$RY" "$RW" "$RH"; then
    info "LOCK / UNLOCK row is over the $PNAME button at $PX,$PY"
    sw_cell 5; F0=$C_FLAGS
    read -r _ _ _ _ TOOL0 _ <<< "$(line VIEW)"
    click "$PX" "$PY"; dk_settle; sw_read
    read -r _ _ _ _ TOOL2 _ <<< "$(line VIEW)"
    sw_expect "LOCK / UNLOCK over the $PNAME button: the tool is unchanged" "$TOOL2" "$TOOL0"
    sw_cell 5; [[ "$C_FLAGS" != "$F0" ]] && pass "... and swatch 5's lock changed ($F0 -> $C_FLAGS)" || fail "LOCK did not run (flags $C_FLAGS)"
else
    fail "LOCK / UNLOCK row ($R) is over no toolbox tool button"
    key Escape; dk_settle
fi
park_mouse
