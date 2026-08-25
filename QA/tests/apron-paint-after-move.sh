#!/bin/bash
# =============================================================================
# apron-paint-after-move.sh — BUG-14: paint must land at the cursor after a Move
# has promoted the layer to an apron-extended buffer.
#
# When content is moved past the canvas edge, the layer is promoted (imgHandle
# becomes larger than the canvas, offset by (apronW,apronH)). The paint tools
# wrote RAW canvas coords into that offset buffer, so strokes landed ~apronW/H
# off — off the visible canvas. This test promotes the layer via a Move, then
# paints at a known spot and asserts the pixel there actually changes.
# =============================================================================

info "=== BUG-14: paint lands correctly after a Move promotes the apron ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Draw content spanning the canvas so a move pushes some of it off-edge --
info "Draw content"
drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.3 "Stroke"

# -- Select all, then Move the content far to the right (past the edge → promote) --
info "Select all + move content past the right edge (promotes the apron)"
key ctrl+a
wait_for 0.5 "Select all"
key v
wait_for 0.3 "Move tool"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 120 )) $CANVAS_CY
wait_for 0.5 "Moved right past the edge"
assert_no_crash

# -- Switch back to the brush (commits the move; layer stays promoted) --
key b
wait_for 0.3 "Brush"
key ctrl+d
wait_for 0.2 "Deselect"
key grave
wait_for 0.1 "Pointer hidden"

# -- Snap a small region at a known canvas spot, paint there, snap again --
PX=$(( CANVAS_CX - 30 ))
PY=$(( CANVAS_CY - 25 ))
park_mouse
snap_region $(( PX - 12 )) $(( PY - 12 )) 24 24 "apron-paint-before"
BEFORE="$SNAP_RESULT"
info "Paint a stroke at a known canvas spot"
drag $(( PX - 8 )) $PY $(( PX + 8 )) $PY
wait_for 0.4 "Painted"
park_mouse
snap_region $(( PX - 12 )) $(( PY - 12 )) 24 24 "apron-paint-after"
AFTER="$SNAP_RESULT"

# The paint MUST have landed at the cursor spot. In the bug it lands offset by
# (apronW,apronH) — off the visible canvas — so this region wouldn't change.
assert_regions_differ "$BEFORE" "$AFTER" "Paint must land at the cursor after a Move promotes the apron (BUG-14)"
screenshot "apron-paint-after-move"

assert_no_crash
assert_window_exists
info "=== BUG-14 apron-paint test COMPLETE ==="
