#!/bin/bash
# =============================================================================
# dock-resize.sh — QA test: side-docked panels resize by dragging their inner
# edge (GUI/DOCK-RESIZE). In Default the new value is saved to the --config
# file (QA/DRAW.qa.cfg, rebuilt before every test), so the test also greps it.
#   layers  (docked LEFT, 100px, boundary x=100)  dragged right  -> wider
#   toolbox (docked RIGHT, 4 columns, boundary x=TB_X) dragged left -> 6 columns
#   edit bar (docked LEFT after the layers)        dragged right -> 2 columns
# Workspace saves are NOT exercised here: they write the user's workspaces
# folder (checked by hand with an isolated XDG_DATA_HOME).
# QA-OPTIONS: WORKSPACE=default
# =============================================================================

info "=== Dock edge resize Test ==="
wait_for 0.8 "settle"
key Escape
park_mouse
wait_for 0.3 "settle"

Y=$(( VIEWPORT_H / 2 ))

# slow multi-frame drag (DRAW idles at 15 fps): press, step, release
slow_drag() {
    local x1=$1 x2=$2 y=$3 steps=6 i x
    mouse_down "$x1" "$y"
    wait_for 0.15 "grab"
    for (( i = 1; i <= steps; i++ )); do
        x=$(( x1 + (x2 - x1) * i / steps ))
        hover "$x" "$y"
        wait_for 0.1 "drag"
    done
    mouse_up
    wait_for 0.6 "drop"
}

# --- layers: 100 -> 160 ------------------------------------------------------
snap_region 100 $(( Y - 60 )) 120 120 "layers-before"; L0="$SNAP_RESULT"
slow_drag $(( LP_W - 1 )) $(( LP_W + 59 )) $Y
park_mouse
wait_for 0.3 "settle"
snap_region 100 $(( Y - 60 )) 120 120 "layers-after"; L1="$SNAP_RESULT"
assert_regions_differ "$L0" "$L1" "dragging the layers panel's inner edge widened it"
LW=$(grep -m1 '^LAYER_PANEL_WIDTH=' "$QA_CFG" | cut -d= -f2 | tr -d '\r[:space:]')
if [[ -n "$LW" && "$LW" -ge 140 && "$LW" -le 180 ]]; then
    pass "LAYER_PANEL_WIDTH saved to the config ($LW)"
else
    fail "LAYER_PANEL_WIDTH not saved as ~160 (got '$LW')"
fi

# --- toolbox: 4 -> 6 columns (pitch 24px at scale 2) --------------------------
snap_region $(( TB_X - 60 )) 20 60 100 "toolbox-before"; T0="$SNAP_RESULT"
slow_drag $(( TB_X - 1 )) $(( TB_X - 49 )) $Y
park_mouse
wait_for 0.3 "settle"
snap_region $(( TB_X - 60 )) 20 60 100 "toolbox-after"; T1="$SNAP_RESULT"
assert_regions_differ "$T0" "$T1" "dragging the toolbox's inner edge added columns"
TC=$(grep -m1 '^TOOLBOX_COLUMNS=' "$QA_CFG" | cut -d= -f2 | tr -d '\r[:space:]')
if [[ "$TC" == "6" ]]; then
    pass "TOOLBOX_COLUMNS saved to the config (6)"
else
    fail "TOOLBOX_COLUMNS not saved as 6 (got '$TC')"
fi

# --- edit bar: 1 -> 2 columns (its boundary is now right of the wider layers) -
EBX=$(( LW + 20 ))
snap_region $EBX $(( Y - 60 )) 40 120 "editbar-before"; E0="$SNAP_RESULT"
slow_drag $(( EBX - 1 )) $(( EBX + 19 )) $Y
park_mouse
wait_for 0.3 "settle"
snap_region $EBX $(( Y - 60 )) 40 120 "editbar-after"; E1="$SNAP_RESULT"
assert_regions_differ "$E0" "$E1" "dragging the edit bar's inner edge added a column"
EC=$(grep -m1 '^EDIT_BAR_COLUMNS=' "$QA_CFG" | cut -d= -f2 | tr -d '\r[:space:]')
if [[ "$EC" == "2" ]]; then
    pass "EDIT_BAR_COLUMNS saved to the config (2)"
else
    fail "EDIT_BAR_COLUMNS not saved as 2 (got '$EC')"
fi
screenshot "dock-resize"

assert_no_crash
assert_window_exists
info "=== Dock edge resize Test PASSED ==="
