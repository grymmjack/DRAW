#!/bin/bash
# TEMP probe — paint on the group's CHILD vs a layer OUTSIDE the group
SCRATCH=/tmp/claude-1000/-home-grymmjack-git-DRAW/9e389e29-f47e-4b1d-b015-2356aabe5dd5/scratchpad
LAYER_MID_X=$(( LP_X + LP_W / 2 ))
row_y() { echo $(( LP_Y + 16 + $1 * 20 + 10 )); }
CR_X=$(( CANVAS_CX - 50 )); CR_Y=$(( CANVAS_CY - 50 ))

canvas_focus b
wait_for 0.4 "ready"; key grave; wait_for 0.2 "hidden"
click $(( CANVAS_CX - 30 )) "$CANVAS_CY"; wait_for 0.3 "dot bg"
key ctrl+shift+n; wait_for 0.5 "layer2"
click $(( CANVAS_CX + 30 )) "$CANVAS_CY"; wait_for 0.3 "dot l2"
key ctrl+shift+g; wait_for 0.8 "grouped"

for spec in "1:CHILD(Layer2)" "2:OUTSIDE(Background)"; do
    r=${spec%%:*}; label=${spec##*:}
    click "$LAYER_MID_X" "$(row_y $r)"; wait_for 0.5 "selected row $r"
    canvas_focus b; wait_for 0.3 "brush"
    park_mouse
    snap_region "$CR_X" "$CR_Y" 100 100 "paint-before-$r"; B="$SNAP_RESULT"
    drag $(( CANVAS_CX - 20 + r*4 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 20 + r*4 )) $(( CANVAS_CY + 20 ))
    wait_for 0.5 "drew on row $r"
    park_mouse
    snap_region "$CR_X" "$CR_Y" 100 100 "paint-after-$r"; A="$SNAP_RESULT"
    n=$(_parse_ae "$(compare -metric AE -fuzz 2% "$B" "$A" /dev/null 2>&1 || true)")
    echo "PROBE: row $r $label -> $n px changed"
    cp "$A" "$SCRATCH/paint-row$r.png"
done
pass "probe done"
