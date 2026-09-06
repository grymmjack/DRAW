#!/bin/bash
# =============================================================================
# apron-fill-after-move.sh — BUG-14: FILLED shapes must land on the canvas after
# a Move has promoted the layer to an apron-extended buffer.
#
# Companion to apron-paint-after-move.sh (which covers the brush). When content
# is moved past the canvas edge the layer is promoted (imgHandle becomes larger
# than the canvas, canvas (x,y) -> buffer (x+apronW,y+apronH)). The three FILLED
# shape commits — rect (LINE BF in MOUSE.BM), ellipse (ELLIPSE_fill_scanline),
# polygon (POLY_FILL_scanline) — wrote RAW canvas coords into that offset buffer,
# so the fill landed ~apronW/H off, in the apron border, invisible on the canvas.
# This promotes the layer via a Move, then draws each filled shape at a known
# clear spot and asserts the region there actually changes.
#
# Deterministic (does not depend on splash/startup timing): the Move ALWAYS
# promotes the layer, so a raw-coord fill ALWAYS lands off-canvas here.
# =============================================================================

info "=== BUG-14: filled shapes land correctly after a Move promotes the apron ==="

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

# -- Select all, then Move the content far to the right (past the edge -> promote) --
info "Select all + move content past the right edge (promotes the apron)"
key ctrl+a
wait_for 0.5 "Select all"
key v
wait_for 0.3 "Move tool"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 120 )) $CANVAS_CY
wait_for 0.5 "Moved right past the edge"
assert_no_crash

# -- Commit the move (tool switch) and deselect; layer STAYS promoted (the shape
#    tools are apron-allowed, so they do not demote it). --
key b
wait_for 0.3 "Brush (commits move)"
key ctrl+d
wait_for 0.2 "Deselect"
key grave
wait_for 0.1 "Pointer hidden"

# -- FILLED RECTANGLE on the promoted layer. Positions stay near canvas centre
#    (within the proven-visible zone; apron-paint-after-move paints at CX-30,CY-25)
#    and clear of the content we shifted to the RIGHT edge. --------------------
info "Filled rectangle on the promoted layer"
key shift+r
wait_for 0.3 "Filled rect tool"
RX=$(( CANVAS_CX - 38 )) ; RY=$(( CANVAS_CY - 28 ))
park_mouse
snap_region $(( RX - 14 )) $(( RY - 12 )) 32 28 "apron-fill-rect-before"
BEFORE="$SNAP_RESULT"
drag $(( RX - 10 )) $(( RY - 8 )) $(( RX + 10 )) $(( RY + 8 ))
wait_for 0.4 "Filled rect drawn"
park_mouse
snap_region $(( RX - 14 )) $(( RY - 12 )) 32 28 "apron-fill-rect-after"
assert_regions_differ "$BEFORE" "$SNAP_RESULT" \
    "Filled RECT must land on canvas after a Move promotes the apron (BUG-14)"
assert_no_crash

# -- FILLED ELLIPSE (lower, same column) -------------------------------------
info "Filled ellipse on the promoted layer"
key shift+c
wait_for 0.3 "Filled ellipse tool"
EX=$(( CANVAS_CX - 38 )) ; EY=$(( CANVAS_CY + 24 ))
park_mouse
snap_region $(( EX - 15 )) $(( EY - 13 )) 34 28 "apron-fill-ellipse-before"
BEFORE="$SNAP_RESULT"
drag $(( EX - 11 )) $(( EY - 9 )) $(( EX + 11 )) $(( EY + 9 ))
wait_for 0.4 "Filled ellipse drawn"
park_mouse
snap_region $(( EX - 15 )) $(( EY - 13 )) 34 28 "apron-fill-ellipse-after"
assert_regions_differ "$BEFORE" "$SNAP_RESULT" \
    "Filled ELLIPSE must land on canvas after a Move promotes the apron (BUG-14)"
assert_no_crash

# -- FILLED POLYGON (upper-centre; click 3 vertices + Return) -----------------
info "Filled polygon on the promoted layer"
key shift+p
wait_for 0.3 "Filled polygon tool"
PSX=$(( CANVAS_CX + 8 )) ; PSY=$(( CANVAS_CY - 20 ))
park_mouse
snap_region $(( PSX - 20 )) $(( PSY - 6 )) 40 38 "apron-fill-poly-before"
BEFORE="$SNAP_RESULT"
click $PSX $PSY
wait_for 0.2 "poly v1 (top)"
click $(( PSX + 15 )) $(( PSY + 26 ))
wait_for 0.2 "poly v2 (bottom right)"
click $(( PSX - 15 )) $(( PSY + 26 ))
wait_for 0.2 "poly v3 (bottom left)"
key Return
wait_for 0.5 "poly commit"
park_mouse
snap_region $(( PSX - 20 )) $(( PSY - 6 )) 40 38 "apron-fill-poly-after"
assert_regions_differ "$BEFORE" "$SNAP_RESULT" \
    "Filled POLYGON must land on canvas after a Move promotes the apron (BUG-14)"

screenshot "apron-fill-after-move"
assert_no_crash
assert_window_exists
info "=== BUG-14 apron filled-shapes test COMPLETE ==="
