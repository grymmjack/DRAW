#!/bin/bash
# =============================================================================
# popup-over-windows.sh — QA test: a menu bar dropdown opened over a floating
# window (here the large Customize Toolbars window) is drawn complete on top of
# it, and nothing around the dropdown changes: the 2px strips just outside its
# frame must be pixel-identical with the menu open and closed. (Rick's
# screenshots, 2026-10-08: a band of canvas pixels - dashed lines - showed
# around menus over windows; POPUP_reblit_to_screen0 copied a margin.)
# For every root whose dropdown overlaps the window; then each of those
# dropdowns must be pixel-identical to the same dropdown with the window closed.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt WORKSPACES_DIR=QA/.tbed-ws
# =============================================================================

source "$DRAW_ROOT/QA/tbed-lib.sh"
tb_reset_ws

# MENU line -> MX MY MW MH (1 = no dropdown open)
menu_rect() {
    local line
    line=$(grep '^MENU ' "$DK_DUMP" 2>/dev/null) || return 1
    read -r _ MX MY MW MH <<< "$line"
}
# the editor window's rect from its title control + DONE row
win_rect() {
    local t d
    t=$(grep '^TBC title ' "$DK_DUMP"); d=$(grep '^TBC done ' "$DK_DUMP")
    read -r _ _ WX WY _ _ <<< "$t"
    read -r _ _ dx dy dw dh <<< "$d"
    WR=$(( dx + dw + 6 )); WB=$(( dy + dh + 6 ))
}

info "=== Menus over a floating window: complete, nothing around them changes ==="
wait_for 1.0 "settle"
key Escape
dk_park
dk_settle
tb_open
win_rect
info "window: x $WX..$WR y $WY..$WB"

N=0
declare -A MENU_SNAP MENU_RECT
while read -r _ name rx rw; do
    [[ -z "$name" ]] && continue
    # open it, read the dropdown frame
    hover $(( rx + rw / 2 )) 5; sleep 0.2
    click $(( rx + rw / 2 )) 5; sleep 0.5; dk_settle
    if ! menu_rect; then info "$name: no dropdown"; key Escape; sleep 0.3; continue; fi
    # only menus that overlap the window
    if (( MX + MW <= WX || MX >= WR || MY + MH <= WY || MY >= WB )); then
        key Escape; sleep 0.3; dk_settle; continue
    fi
    N=$(( N + 1 ))
    snap_region $(( MX - 2 )) "$MY" 2 "$MH" "$name-L-open"; LO="$SNAP_RESULT"
    snap_region $(( MX + MW )) "$MY" 2 "$MH" "$name-R-open"; RO="$SNAP_RESULT"
    snap_region "$MX" $(( MY + MH )) "$MW" 2 "$name-B-open"; BO="$SNAP_RESULT"
    snap_region "$MX" "$MY" "$MW" "$MH" "$name-menu-over-window"; MENU_SNAP[$name]="$SNAP_RESULT"; MENU_RECT[$name]="$MX $MY $MW $MH $rx $rw"
    (( N == 1 )) && screenshot "popup-over-window-$name"
    key Escape; sleep 0.5; dk_settle
    snap_region $(( MX - 2 )) "$MY" 2 "$MH" "$name-L-closed"; LC="$SNAP_RESULT"
    snap_region $(( MX + MW )) "$MY" 2 "$MH" "$name-R-closed"; RC="$SNAP_RESULT"
    snap_region "$MX" $(( MY + MH )) "$MW" 2 "$name-B-closed"; BC="$SNAP_RESULT"
    assert_regions_same "$LC" "$LO" "$name: the strip left of the dropdown is untouched" 0
    assert_regions_same "$RC" "$RO" "$name: the strip right of the dropdown is untouched" 0
    assert_regions_same "$BC" "$BO" "$name: the strip below the dropdown is untouched" 0
done < <(grep '^MROOT ' "$DK_DUMP")

if (( N >= 3 )); then pass "$N dropdowns over the window checked"; else fail "only $N dropdowns overlapped the window"; fi

# the same dropdowns with no window under them: each one is drawn complete over
# the window (no rows or edges missing / covered)
tb_click close
dk_park; sleep 0.3; dk_settle
for name in "${!MENU_RECT[@]}"; do
    read -r mx my mw mh rx rw <<< "${MENU_RECT[$name]}"
    hover $(( rx + rw / 2 )) 5; sleep 0.2
    click $(( rx + rw / 2 )) 5; sleep 0.5; dk_settle
    snap_region "$mx" "$my" "$mw" "$mh" "$name-menu-alone"
    tol=0; [[ "$name" == "view" ]] && tol=40 # (its "Customize Toolbars..." row is checked while the window is open)
    assert_regions_same "$SNAP_RESULT" "${MENU_SNAP[$name]}" "$name: the dropdown over the window is identical to the dropdown alone" "$tol"
    key Escape; sleep 0.4; dk_settle
done
assert_no_crash
tb_reset_ws
