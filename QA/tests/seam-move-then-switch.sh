#!/bin/bash
# =============================================================================
# seam-move-then-switch.sh — SEAM TEST: move in progress → tool switch
# Moving content and then switching tools must COMMIT the move cleanly (the
# content ends up at its new position on the layer, the old position is vacated),
# with no crash and the result erasable (on a real layer).
# =============================================================================

info "=== SEAM: move → tool switch commits the move ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

LEFT_X=$(( CANVAS_CX - 35 ))
RIGHT_X=$(( CANVAS_CX + 35 ))

# -- Baselines for the LEFT (source) and RIGHT (destination) probes --
park_mouse
snap_region $(( LEFT_X - 14 )) $(( CANVAS_CY - 14 )) 28 28 "seam-move-left-empty";  LEFT_EMPTY="$SNAP_RESULT"
snap_region $(( RIGHT_X - 14 )) $(( CANVAS_CY - 14 )) 28 28 "seam-move-right-empty"; RIGHT_EMPTY="$SNAP_RESULT"

# -- Draw a compact blob at LEFT --
info "Draw content at LEFT"
drag $(( LEFT_X - 8 )) $CANVAS_CY $(( LEFT_X + 8 )) $CANVAS_CY
wait_for 0.3 "Blob"
drag $LEFT_X $(( CANVAS_CY - 8 )) $LEFT_X $(( CANVAS_CY + 8 ))
wait_for 0.3 "Blob cross"
park_mouse
snap_region $(( LEFT_X - 14 )) $(( CANVAS_CY - 14 )) 28 28 "seam-move-left-drawn"; LEFT_DRAWN="$SNAP_RESULT"
assert_regions_differ "$LEFT_EMPTY" "$LEFT_DRAWN" "Content drawn at LEFT (setup)"

# -- Move: select move tool, drag the whole layer LEFT→RIGHT --
info "Move tool: drag content LEFT → RIGHT"
key v
wait_for 0.3 "Move tool (captures layer)"
drag $LEFT_X $CANVAS_CY $RIGHT_X $CANVAS_CY
wait_for 0.4 "Dragged right"
assert_no_crash

# -- THE SEAM: switch to brush; the move must be committed --
info "Switch to brush (B) — move commits"
key b
wait_for 0.4 "Tool switched"
assert_no_crash

# -- LEFT vacated, RIGHT now has the content --
park_mouse
snap_region $(( LEFT_X - 14 )) $(( CANVAS_CY - 14 )) 28 28 "seam-move-left-after";  LEFT_AFTER="$SNAP_RESULT"
snap_region $(( RIGHT_X - 14 )) $(( CANVAS_CY - 14 )) 28 28 "seam-move-right-after"; RIGHT_AFTER="$SNAP_RESULT"
assert_regions_differ "$RIGHT_EMPTY" "$RIGHT_AFTER" "Moved content must arrive at the RIGHT position"
assert_regions_differ "$LEFT_DRAWN"  "$LEFT_AFTER"  "Source LEFT position must change (content moved away)"
screenshot "seam-move-then-switch"

assert_no_crash
assert_window_exists
info "=== SEAM move-then-switch test COMPLETE ==="
