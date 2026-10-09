#!/bin/bash
# =============================================================================
# dock-float-workarea.sh — QA test: a floating window stays in the work area
# when a dock column grows under it. The floating Browser sits near the left
# docks; docking the Color Mixer as a new left column pushes the work area's
# left edge past it. Before the fix the Browser stayed put, drawn over the
# layers (dock-fuzz-browser-19 step 4: 'window browser covers layers (96x220)');
# FPANEL_settle now moves floating windows to a free spot whenever the work
# area changes.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt BROWSER_VISIBLE=1 BROWSER_POS_X=300 BROWSER_POS_Y=60 COLOR_MIXER_VISIBLE=1
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"

# the floating window NAME lies inside the canvas work area (SCR line)
in_work_area() {
    local name=$1 label=$2 line
    dk_scr
    line=$(grep "^WIN $name " "$DK_DUMP") || { fail "$label: no WIN line for $name"; return; }
    read -r _ _ wx wy ww wh ws <<< "$line"
    if (( ws > 0 )); then fail "$label: $name is docked"; return; fi
    if (( wx >= CAN_LX - 1 && wx + ww <= CAN_RX + 1 )); then
        pass "$label: $name ($wx..$(( wx + ww ))) inside the work area ($CAN_LX..$CAN_RX)"
    else
        fail "$label: $name ($wx..$(( wx + ww ))) outside the work area ($CAN_LX..$CAN_RX)"
    fi
}

info "=== Dock: a floating window follows the work area ==="
dk_begin
dk_check "start"
in_work_area browser "start"

dk_move_expect drawer edge-left
dk_move_expect layers edge-right
dk_move_expect layers newcol editbar
dk_check "layers beside the edit bar"
in_work_area browser "layers beside the edit bar"

# the column that used to leave the Browser over the layers
dk_move_expect colormixer newcol drawer
dk_check "mixer in a new left column"
in_work_area browser "mixer in a new left column"

# and back: floating the mixer again leaves everything valid
dk_move_expect colormixer float
dk_check "mixer floating again"
in_work_area browser "mixer floating again"

screenshot "dock-float-workarea"
assert_window_exists
info "=== Dock: a floating window follows the work area PASSED ==="
