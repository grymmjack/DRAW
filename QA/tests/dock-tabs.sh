#!/bin/bash
# =============================================================================
# dock-tabs.sh — QA test: tabs and collapsed slots in a dock column (GUI/DOCK).
# An arrangement puts the layers and edit bar as TABS in the outermost right
# column, with the advanced bar collapsed to its title strip under them:
#   RIGHT.1 = layers+editbar | !advbar
#   tab       click the "Edit Bar" tab       -> it shows, saved as *editbar
#   expand    click the collapsed title strip -> the advanced bar shows, ! gone
#   collapse  click the tab strip's chevron   -> the tabbed slot collapses (!)
# Geometry at 958x514: tab strip y=0..10 ("Layers" x~870, "Edit Bar" x~912,
# chevron x~862); the collapsed strip sits on the column's bottom (y~487).
# QA-OPTIONS: WORKSPACE=default DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_1=AUTO;layers+editbar|!advbar
# =============================================================================

info "=== Dock tabs + collapse Test ==="
wait_for 0.8 "settle"
key Escape
park_mouse
wait_for 0.3 "settle"

COL0=$(( VIEWPORT_W - LP_W ))
cfg_dock() { grep -m1 "^$1=" "$QA_CFG" | cut -d= -f2- | tr -d '\r'; }

# --- switch tab ----------------------------------------------------------------
snap_region $COL0 20 $LP_W 160 "tab-before"; T0="$SNAP_RESULT"
click 912 5
wait_for 0.5 "tab"
park_mouse
wait_for 0.3 "settle"
snap_region $COL0 20 $LP_W 160 "tab-after"; T1="$SNAP_RESULT"
assert_regions_differ "$T0" "$T1" "clicking the Edit Bar tab shows the edit bar"
R1=$(cfg_dock DOCK_RIGHT_1)
if [[ "$R1" == *"*editbar"* ]]; then
    pass "active tab saved ($R1)"
else
    fail "active tab not saved (DOCK_RIGHT_1='$R1')"
fi
screenshot "dock-tabs-editbar"

# --- expand the collapsed advanced bar ---------------------------------------------
snap_region $COL0 300 $LP_W 180 "exp-before"; E0="$SNAP_RESULT"
click $(( COL0 + 30 )) 487
wait_for 0.5 "expand"
park_mouse
wait_for 0.3 "settle"
snap_region $COL0 300 $LP_W 180 "exp-after"; E1="$SNAP_RESULT"
assert_regions_differ "$E0" "$E1" "clicking the collapsed title expands the advanced bar"
R1=$(cfg_dock DOCK_RIGHT_1)
if [[ "$R1" == *advbar* && "$R1" != *"!advbar"* ]]; then
    pass "expanded slot saved ($R1)"
else
    fail "expand not saved (DOCK_RIGHT_1='$R1')"
fi

# --- collapse the tabbed slot by its chevron --------------------------------------
snap_region $COL0 20 $LP_W 160 "col-before"; C0="$SNAP_RESULT"
click 862 5
wait_for 0.5 "collapse"
park_mouse
wait_for 0.3 "settle"
snap_region $COL0 20 $LP_W 160 "col-after"; C1="$SNAP_RESULT"
assert_regions_differ "$C0" "$C1" "the chevron collapses the tabbed slot"
R1=$(cfg_dock DOCK_RIGHT_1)
if [[ "$R1" == *"!"*layers* ]]; then
    pass "collapsed slot saved ($R1)"
else
    fail "collapse not saved (DOCK_RIGHT_1='$R1')"
fi
screenshot "dock-tabs-collapsed"

assert_no_crash
assert_window_exists
info "=== Dock tabs + collapse Test PASSED ==="
