#!/bin/bash
# =============================================================================
# dock-windows-menu.sh — QA test: a docked Color Mixer stays drawn while a menu
# is open (it used to vanish for any open menu / popup), and the menu is drawn
# above it where they overlap (POPUP_reblit_to_screen0).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt COLOR_MIXER_VISIBLE=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;colormixer DOCK_LEFT_2=AUTO;toolbox|organizer|drawer DOCK_RIGHT_1=AUTO;layers DOCK_RIGHT_2=AUTO;advbar DOCK_RIGHT_3=AUTO;editbar
# =============================================================================

source "$DRAW_ROOT/QA/dock-lib.sh"

info "=== Docked window stays up while a menu is open ==="
wait_for 1.0 "settle"
key Escape
dk_park
dk_settle
dk_p colormixer || fail "no colormixer in the dump"
if (( P_SLOT > 0 )); then pass "the Color Mixer is docked (slot $P_SLOT)"; else fail "the Color Mixer is not docked"; fi
MX=$P_X; MY=$P_Y; MW=$P_W; MH=$P_H
snap_region "$MX" $(( MY + 20 )) "$MW" 60 "mixer-closed"; A="$SNAP_RESULT"

# open the SELECT menu (a menu bar root) and hold it open
dk_scr
click $(( CAN_LX + 160 )) 5
wait_for 0.6 "menu open"
snap_region "$MX" $(( MY + 20 )) "$MW" 60 "mixer-menu-open"; B="$SNAP_RESULT"
screenshot "dock-windows-menu"
assert_regions_same "$A" "$B" "the docked Color Mixer is still drawn with a menu open"
key Escape
wait_for 0.4 "closed"
assert_no_crash
