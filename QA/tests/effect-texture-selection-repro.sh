#!/bin/bash
# =============================================================================
# effect-texture-selection-repro.sh — REPRO for BUG-R
#
# Do TEXTURE effects honour an active selection (Clip to Selection ON = default)?
# Paint a solid block across the whole sample area, make a PARTIAL rectangular
# marquee on the LEFT half, apply WOOD, and sample a strip on the RIGHT (OUTSIDE
# the selection). If that strip changed, WOOD ignored the selection = BUG-R.
# WOOD = TEXTURE cat 8 child 0 -> open_effect 8 0.
# =============================================================================

info "=== REPRO: texture honours selection (BUG-R) ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10; do key bracketright; done
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
# Solid green block across the whole width of the sample band.
for dy in -40 -30 -20 -10 0 10 20 30 40; do
    drag $(( CANVAS_CX - 90 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 90 )) $(( CANVAS_CY + dy ))
done
key grave ; wait_for 0.3 "Block drawn"
assert_no_crash

# Partial rectangular marquee on the LEFT of the block (selshape-style coords that
# reliably create a real box, not a 1x1). Screenshot to confirm the selection.
key m ; wait_for 0.3 "Rect marquee tool"
drag $(( CANVAS_CX - 55 )) $(( CANVAS_CY - 30 )) $(( CANVAS_CX - 5 )) $(( CANVAS_CY + 30 ))
wait_for 0.4 "Left selection made"
park_mouse
screenshot "R-selection-made"

# Sample OUTSIDE the selection (right side of block, well clear of the marquee).
OX=$(( CANVAS_CX + 25 )); OY=$(( CANVAS_CY - 12 )); OW=35; OH=24
park_mouse
snap_region "$OX" "$OY" "$OW" "$OH" "R-outside-before"
OUTBEFORE="$SNAP_RESULT"
# Sample INSIDE the selection (left side, clear of the marching ants).
IX=$(( CANVAS_CX - 45 )); IY=$(( CANVAS_CY - 12 )); IW=30; IH=24
snap_region "$IX" "$IY" "$IW" "$IH" "R-inside-before"
INBEFORE="$SNAP_RESULT"

open_effect 8 0 ; wait_for 0.5 "Wood dialog open"
screenshot "R-wood-dialog"
key Return ; wait_for 0.7 "Applied"
assert_no_crash

park_mouse
snap_region "$OX" "$OY" "$OW" "$OH" "R-outside-after"
OUTAFTER="$SNAP_RESULT"
snap_region "$IX" "$IY" "$IW" "$IH" "R-inside-after"
INAFTER="$SNAP_RESULT"
screenshot "R-wood-canvas-after"

# Inside MUST change (wood applied there); outside must NOT (honoured selection).
assert_regions_differ "$INBEFORE" "$INAFTER" "Wood must apply INSIDE the selection"
assert_regions_same   "$OUTBEFORE" "$OUTAFTER" "Wood must NOT touch OUTSIDE the selection (BUG-R)"
assert_no_crash
assert_window_exists
info "=== REPRO complete ==="
