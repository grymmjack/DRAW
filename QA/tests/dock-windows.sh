#!/bin/bash
# =============================================================================
# dock-windows.sh — QA test: the floating windows dock and undock (GUI/DOCK).
# Dragging a window's own title bar over a dock target shows the drop preview
# and docks it on release; dragging a docked window's title off the docks floats
# it again. Saved to the --config file (QA/DRAW.qa.cfg), so the test greps it.
#   Preview     (floating, QA default) title -> left screen edge -> DOCK_LEFT_1
#   Preview     docked title -> canvas  -> floating again
#   Color Mixer (floating at 300,60)  title -> right screen edge -> DOCK_RIGHT_1
# (Preview first: a new column narrows the work area and moves floating windows.)
# Geometry at 958x514: the Preview's title bar is at y~390, x 721..770.
# QA-OPTIONS: WORKSPACE=default COLOR_MIXER_VISIBLE=1 COLOR_MIXER_X=300 COLOR_MIXER_Y=60
# =============================================================================

info "=== Dock floating windows Test ==="
wait_for 1.2 "settle"
key Escape
park_mouse
wait_for 0.3 "settle"

cfg_docks() { grep '^DOCK_\(LEFT\|RIGHT\)_[0-9]*=' "$QA_CFG" | tr -d '\r' | tr '\n' ' '; }

slow_drag() {
    local x1=$1 y1=$2 x2=$3 y2=$4 steps=7 i
    mouse_down "$x1" "$y1"
    wait_for 0.2 "grab"
    for (( i = 1; i <= steps; i++ )); do
        hover $(( x1 + (x2 - x1) * i / steps )) $(( y1 + (y2 - y1) * i / steps ))
        wait_for 0.12 "drag"
    done
    wait_for 0.3 "target"
    mouse_up
    wait_for 0.8 "drop"
}

# --- Preview -> left edge ------------------------------------------------------------
snap_region 721 395 110 90 "preview-before"; P0="$SNAP_RESULT"
slow_drag 740 390 2 $(( VIEWPORT_H / 2 ))
park_mouse
wait_for 0.3 "settle"
snap_region 721 395 110 90 "preview-after"; P1="$SNAP_RESULT"
assert_regions_differ "$P0" "$P1" "the Preview left its floating spot"
L1=$(grep -m1 '^DOCK_LEFT_1=' "$QA_CFG" | tr -d '\r')
if [[ "$L1" == *preview* ]]; then
    pass "Preview docked in a new outermost left column ($L1)"
else
    fail "Preview not docked ($(cfg_docks))"
fi
screenshot "dock-windows-preview"

# --- Preview: docked title -> canvas = floating again ---------------------------------
slow_drag 20 5 $CANVAS_CX $CANVAS_CY
park_mouse
wait_for 0.3 "settle"
if [[ "$(cfg_docks)" != *preview* ]]; then
    pass "Preview floats again (no dock line holds it)"
else
    fail "Preview still docked ($(cfg_docks))"
fi
screenshot "dock-windows-undocked"

# --- Color Mixer -> right edge -------------------------------------------------
snap_region 300 70 200 140 "mixer-before"; M0="$SNAP_RESULT"
slow_drag 310 64 $(( VIEWPORT_W - 6 )) $(( VIEWPORT_H / 2 ))
park_mouse
wait_for 0.3 "settle"
snap_region 300 70 200 140 "mixer-after"; M1="$SNAP_RESULT"
assert_regions_differ "$M0" "$M1" "the Color Mixer left its floating spot"
R1=$(grep -m1 '^DOCK_RIGHT_1=' "$QA_CFG" | tr -d '\r')
if [[ "$R1" == *colormixer* ]]; then
    pass "Color Mixer docked in a new outermost right column ($R1)"
else
    fail "Color Mixer not docked ($(cfg_docks))"
fi
screenshot "dock-windows-mixer"

assert_no_crash
assert_window_exists
info "=== Dock floating windows Test PASSED ==="
