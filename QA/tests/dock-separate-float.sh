#!/bin/bash
# =============================================================================
# dock-separate-float.sh — QA test: float every panel of the toolbox column at
# once, move the floating windows, drop a floating one straight onto a dock
# target (no dock back), dock the others back by double-click in reverse order.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== Dock: float the toolbox column Test ==="
dk_begin
dk_scr
dk_move drawer float $(( CAN_LX + 40 )) $(( DOCK_TOP + 40 ))
dk_expect_floating drawer
dk_check "drawer floating"
dk_move organizer float $(( CAN_LX + 250 )) $(( DOCK_TOP + 40 ))
dk_expect_floating organizer
dk_check "organizer floating"
dk_move toolbox float $(( CAN_LX + 450 )) $(( DOCK_TOP + 40 ))
dk_expect_floating toolbox
dk_check "toolbox floating (its column is gone)"
dk_expect_tree '^[^|]*$' "no stacked slots left on the right"
screenshot "dock-float-all"

# move a floating window by its title: it stays floating, saved at the new place
dk_p organizer; OX=$P_FX
dk_move organizer float $(( CAN_LX + 300 )) $(( DOCK_BOT - 120 ))
dk_expect_floating organizer
dk_p organizer
if (( P_FX != OX )); then pass "floating organizer moved ($OX -> $P_FX)"; else fail "floating organizer did not move"; fi
dk_check "organizer moved while floating"

# floating -> straight onto a dock target: the drawer as a tab of the layers
dk_move drawer tab layers
dk_expect_tabs layers drawer
dk_check "floating drawer dropped as a tab of the layers"

# dock the others back by double-click, toolbox first (its column was gone)
dk_grab_point toolbox && double_click "$GX" "$GY"; dk_park; dk_settle
dk_expect_docked toolbox
dk_check "toolbox docked back"
dk_grab_point organizer && double_click "$GX" "$GY"; dk_park; dk_settle
dk_expect_docked organizer
dk_check "organizer docked back"
screenshot "dock-float-back"

assert_window_exists
info "=== Dock: float the toolbox column Test PASSED ==="
