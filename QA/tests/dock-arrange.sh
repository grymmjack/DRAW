#!/bin/bash
# =============================================================================
# dock-arrange.sh — QA test: arranging docked panels by hand (GUI/DOCK).
# An arrangement (DOCK_* keys) puts the layers over the edit bar in the
# outermost right column (layers@2 | editbar). Then:
#   divider  drag the line between layers and edit bar up -> shares saved
#   float    drag the layers header onto the canvas        -> DOCK_FLOAT_LAYERS
#   dock back double-click the floating title               -> back in its column
#   move     drag the layers header to the left edge        -> DOCK_LEFT_1 has it
# Every change is saved to the --config file (QA/DRAW.qa.cfg, rebuilt before
# every test), so the test greps it.
# QA-OPTIONS: WORKSPACE=default DOCK_CUSTOM=1 DOCK_LEFT_1=AUTO;toolbox|organizer|drawer DOCK_RIGHT_1=AUTO;layers@2|editbar DOCK_RIGHT_2=AUTO;advbar
# =============================================================================

info "=== Dock arrange Test ==="
wait_for 0.8 "settle"
key Escape
park_mouse
wait_for 0.3 "settle"

COLX=$(( VIEWPORT_W - LP_W / 2 ))   # middle of the outermost right column (layers width)
DIVY=326                            # 2px above the layers@2 | editbar boundary (y=328 at 958x514): the divider; the boundary itself is the edit bar's grip

cfg_dock() { grep -m1 "^$1=" "$QA_CFG" | cut -d= -f2- | tr -d '\r'; }

# slow multi-frame drag (DRAW idles at 15 fps): press, step, release
slow_drag() {
    local x1=$1 y1=$2 x2=$3 y2=$4 steps=6 i
    mouse_down "$x1" "$y1"
    wait_for 0.15 "grab"
    for (( i = 1; i <= steps; i++ )); do
        hover $(( x1 + (x2 - x1) * i / steps )) $(( y1 + (y2 - y1) * i / steps ))
        wait_for 0.1 "drag"
    done
    wait_for 0.2 "target"
    mouse_up
    wait_for 0.6 "drop"
}

# --- divider: layers 2/3 -> smaller ------------------------------------------
snap_region $(( VIEWPORT_W - LP_W )) 180 $LP_W 160 "div-before"; D0="$SNAP_RESULT"
slow_drag $COLX $DIVY $COLX 200
park_mouse
wait_for 0.3 "settle"
snap_region $(( VIEWPORT_W - LP_W )) 180 $LP_W 160 "div-after"; D1="$SNAP_RESULT"
assert_regions_differ "$D0" "$D1" "dragging the slot divider moved the edit bar up"
R1=$(cfg_dock DOCK_RIGHT_1)
if [[ "$R1" == *layers@* && "$R1" != *layers@2\ * && "$R1" == *editbar* ]]; then
    pass "new shares saved ($R1)"
else
    fail "slot shares not saved (DOCK_RIGHT_1='$R1')"
fi

# --- float: layers header -> canvas ------------------------------------------
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "float-before"; F0="$SNAP_RESULT"
slow_drag $COLX 6 $CANVAS_CX $CANVAS_CY
park_mouse
wait_for 0.3 "settle"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "float-after"; F1="$SNAP_RESULT"
assert_regions_differ "$F0" "$F1" "the layers panel floats over the canvas"
FL=$(cfg_dock DOCK_FLOAT_LAYERS)
if [[ -n "$FL" && "$(cfg_dock DOCK_RIGHT_1)" != *layers* ]]; then
    pass "floating layers saved (DOCK_FLOAT_LAYERS=$FL)"
else
    fail "float not saved (DOCK_FLOAT_LAYERS='$FL', DOCK_RIGHT_1='$(cfg_dock DOCK_RIGHT_1)')"
fi
screenshot "dock-arrange-float"

# --- dock back: double-click the floating title (the pointer is still on it) --
double_click $CANVAS_CX $CANVAS_CY
wait_for 0.6 "dock back"
park_mouse
wait_for 0.3 "settle"
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 40 )) 120 80 "back-after"; B1="$SNAP_RESULT"
assert_regions_differ "$F1" "$B1" "the floating layers panel left the canvas"
if [[ -z "$(cfg_dock DOCK_FLOAT_LAYERS)" ]] && grep -q '^DOCK_\(LEFT\|RIGHT\)_[0-9]*=.*layers' "$QA_CFG"; then
    pass "docked back ($(grep '^DOCK_.*layers' "$QA_CFG" | tr -d '\r'))"
else
    fail "dock back not saved"
fi
SH=$(grep -m1 '^DOCK_RIGHT_[0-9]*=.*layers' "$QA_CFG" | grep -o 'layers@[0-9]*' | cut -d@ -f2)
if [[ -n "$SH" && "$SH" -ge 50 ]]; then
    pass "docked back with a fair share of the column (layers@$SH)"
else
    fail "docked back with a sliver of the column (share '${SH:-1}' next to px shares)"
fi

# --- move: layers header -> left screen edge -----------------------------------
LX=$(grep -m1 '^DOCK_RIGHT_[0-9]*=.*layers' "$QA_CFG" >/dev/null && echo $COLX)
slow_drag ${LX:-$COLX} 6 2 $(( VIEWPORT_H / 2 ))
park_mouse
wait_for 0.3 "settle"
L1=$(cfg_dock DOCK_LEFT_1)
if [[ "$L1" == *layers* ]]; then
    pass "layers moved to a new outermost left column (DOCK_LEFT_1=$L1)"
else
    fail "move to the left edge not saved (DOCK_LEFT_1='$L1')"
fi
screenshot "dock-arrange-moved"

assert_no_crash
assert_window_exists
info "=== Dock arrange Test PASSED ==="
