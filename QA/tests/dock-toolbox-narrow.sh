#!/bin/bash
# =============================================================================
# dock-toolbox-narrow.sh — QA test: a toolbox docked alone in its column takes
# the columns its buttons need, not extra ones for an organizer / drawer that
# live elsewhere (TOOLBAR_reflow + DOCK_with_toolbox%). Rick's arrangement:
#   LEFT.1 = drawer, LEFT.2 = toolbox, the organizer floating, 1 column asked.
# At 958x514 / toolbar scale 2 the 28 buttons need 2 columns (1 column = 672px
# of buttons, taller than the window); before the fix the organizer's and the
# drawer's heights were counted too and it took 3.
# The drawer's own column keeps at least one bin's width.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt TOOLBOX_COLUMNS=1 DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;drawer DOCK_LEFT_2=AUTO;toolbox DOCK_RIGHT_1=AUTO;layers DOCK_RIGHT_2=AUTO;advbar DOCK_RIGHT_3=AUTO;editbar DOCK_FLOAT_ORGANIZER=486,90,170,80
# =============================================================================

source "$DRAW_ROOT/QA/dock-lib.sh"

info "=== Docked toolbox alone in its column: no extra columns ==="
wait_for 1.0 "settle"
key Escape
dk_park
dk_settle

N=$(awk '$1 == "BTN" && $2 == "toolbox"' "$DK_DUMP" | wc -l)
COLS=$(awk '$1 == "BTN" && $2 == "toolbox" {print $7}' "$DK_DUMP" | sort -un | wc -l)
info "toolbox: $N buttons in $COLS columns"
if (( COLS == 2 )); then pass "the toolbox uses the 2 columns its 28 buttons need (not 3)"; else fail "the toolbox has $COLS columns"; fi
dk_p toolbox
TBW=$P_W
dk_p drawer
if (( P_W >= 20 )); then pass "the drawer's own column keeps a usable width ($P_W px)"; else fail "the drawer column is $P_W px"; fi
dk_floating organizer && pass "the organizer still floats" || fail "the organizer is not floating"
info "toolbox panel width $TBW px"
assert_no_crash
