#!/bin/bash
# =============================================================================
# effect-inout-visual.sh — visual proof for BUG-F/G/L (inner/outer masking)
#
# Draw a solid green block surrounded by transparency, then apply Wind, Extrude
# and Wave (each with the default both-toggles-on) and screenshot — the streaks /
# raised blocks / ripple should visibly SPILL past the block's edge into the
# transparent area. Also asserts a strip OUTSIDE the block changed for each.
# =============================================================================

info "=== VISUAL: inner/outer spill (BUG-F/G/L) ==="

draw_block() {
    canvas_focus b ; wait_for 0.2 "brush"
    key ctrl+shift+n ; wait_for 0.4 "fresh transparent layer"
    for n in 1 2 3 4 5 6 7 8 9 10; do key bracketright; done
    CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
    click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "green"
    for dy in -30 -20 -10 0 10 20 30; do drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + dy )); done
    key grave ; wait_for 0.2 "block drawn"
}

# --- WIND (G): streaks blow right past the edge ---
draw_block
OX=$(( CANVAS_CX + 45 )); OY=$(( CANVAS_CY - 30 )); OW=50; OH=60
park_mouse ; snap_region "$OX" "$OY" "$OW" "$OH" "IO-wind-out-before"; WB="$SNAP_RESULT"
open_effect 1 8 ; wait_for 0.5 "Wind"; key Return ; wait_for 0.7 "wind applied"
key grave; park_mouse; snap_region "$OX" "$OY" "$OW" "$OH" "IO-wind-out-after"; WA="$SNAP_RESULT"
screenshot "IO-wind"
assert_regions_differ "$WB" "$WA" "Wind must blow streaks OUTSIDE the block (BUG-G)"
assert_no_crash

# --- EXTRUDE (F): raised blocks spill up-left past the edge ---
draw_block
EX=$(( CANVAS_CX - 95 )); EY=$(( CANVAS_CY - 60 )); EW=55; EH=55
park_mouse ; snap_region "$EX" "$EY" "$EW" "$EH" "IO-extr-out-before"; EB="$SNAP_RESULT"
open_effect 4 3 ; wait_for 0.5 "Extrude"; key Return ; wait_for 0.7 "extrude applied"
key grave; park_mouse; snap_region "$EX" "$EY" "$EW" "$EH" "IO-extr-out-after"; EA="$SNAP_RESULT"
screenshot "IO-extrude"
assert_regions_differ "$EB" "$EA" "Extrude must raise blocks OUTSIDE the shape (BUG-F)"
assert_no_crash

assert_window_exists
info "=== VISUAL inner/outer complete — inspect IO-* screenshots ==="
