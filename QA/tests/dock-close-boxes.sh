#!/bin/bash
# =============================================================================
# dock-close-boxes.sh — QA test: every dock-hosted panel can be closed (Rick
# 2026-11-17: "not every panel that can be repositioned/floated/resized has a
# [x] to close it"). GUI/DOCK: DOCK_close_at% / DOCK_panel_close.
#   floating title   float the Drawer, hover its [x] (red), click it -> hidden;
#                    View: Toggle Drawer (2473) brings it back, still floating
#   floating grip    float the Edit Bar (a grip strip), click its [x] -> hidden; F5 back
#   tabbed strip     tab the Drawer onto the Layers: the strip's [x] closes the
#                    showing tab only
#   handle menu      right-click the Organizer's handle: Close (DOCK_ACT_CLOSE 10)
#                    hides it; Toggle Organizer (2472) brings it back
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: [x] close boxes ==="
dk_begin

pcmd() { dk_park; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; dk_park; dk_settle; }
shown() { dk_p "$1" && (( P_SHOWN != 0 )); }

# --- floating title bar: the Drawer ----------------------------------------------
dk_move_expect drawer float
dk_p drawer
BX=$(( P_FX + P_FW - 6 )); BY=$(( P_FY + 5 ))
info "drawer floats at $P_FX,$P_FY ${P_FW}x$P_FH - its [x] at $BX,$BY"
snap_region $(( P_FX + P_FW - 14 )) "$P_FY" 14 11 "x-idle"; X0="$SNAP_RESULT"
hover "$BX" "$BY"; wait_for 0.6 "hover [x]"
snap_region $(( P_FX + P_FW - 14 )) "$P_FY" 14 11 "x-hover"; X1="$SNAP_RESULT"
assert_regions_differ "$X0" "$X1" "the [x] lights up under the pointer"
screenshot "close-drawer-hover"
click "$BX" "$BY"; wait_for 0.8 "close drawer"; dk_park; dk_settle
if shown drawer; then fail "the floating Drawer's [x] did not close it"; else pass "the floating Drawer's [x] closed it"; fi
pcmd "Toggle Drawer"
if shown drawer && dk_floating drawer; then pass "View: Toggle Drawer brought it back, floating where it was"; else fail "Toggle Drawer: drawer shown=$P_SHOWN fl=$P_FL"; fi
dk_check "after the floating drawer"

# --- floating grip strip: the Edit Bar ---------------------------------------------
dk_move_expect editbar float
dk_p editbar; screenshot "close-editbar-grip"
click $(( P_FX + P_FW - 4 )) $(( P_FY + 3 )); wait_for 0.8 "close edit bar"; dk_park; dk_settle
if shown editbar; then fail "the floating Edit Bar's [x] did not close it"; else pass "the floating Edit Bar's grip [x] closed it"; fi
key F5; wait_for 0.8 "F5"; dk_park; dk_settle
if shown editbar; then pass "F5 brought the Edit Bar back"; else fail "F5 did not bring the Edit Bar back"; fi

# --- a tabbed strip: Drawer + Layers ------------------------------------------------
dk_move_expect drawer tab layers
dk_p drawer; dk_slot "$P_SLOT"
info "tabbed slot $P_SLOT at $S_X,$S_Y w=$S_W act=$S_ACT panels=$S_PANELS"
screenshot "close-tabbed-strip"
click $(( S_X + S_W - 6 )) $(( S_Y + 5 )); wait_for 0.8 "close tab"; dk_park; dk_settle
D=0; L=0; shown drawer && D=1; shown layers && L=1
if (( D + L == 1 )); then pass "the strip's [x] closed one tab (drawer=$D layers=$L)"; else fail "the strip's [x]: drawer=$D layers=$L (want exactly one left)"; fi
(( D == 0 )) && pcmd "Toggle Drawer"
(( L == 0 )) && { key ctrl+l; wait_for 0.8 "Ctrl+L"; dk_park; dk_settle; }

# --- the handle menu's Close: the Organizer --------------------------------------
dk_rmenu organizer
if dk_menu_has 10; then pass "the Organizer's handle menu has Close"; else fail "no Close row in the Organizer's handle menu"; fi
dk_pick 10 "Close"
if shown organizer; then fail "Close did not hide the Organizer"; else pass "the menu's Close hid the Organizer"; fi
pcmd "Toggle Organizer"
if shown organizer; then pass "View: Toggle Organizer brought it back"; else fail "Toggle Organizer did not bring it back"; fi
dk_check "end"
assert_no_crash
