#!/bin/bash
# =============================================================================
# apron-select-after-move.sh — selections on a layer a Move has promoted to an
# apron-extended buffer must land where they were drawn, and Delete must clear
# what they cover (Rick, 2026-10-10: masking the top of a pistol selected an
# empty patch at the bottom right instead). Selection tools keep the layer
# promoted, so canvas (x,y) is buffer (x+apronW, y+apronH) - gotcha #14.
#
# Two bugs, which cancelled out for polygon / freehand Delete:
#  1. POLY_FILL_scanline (shared with the filled polygon tool) offset its writes
#     by the apron even into the canvas-sized SELECTION MASK -> the selection was
#     shifted down-right by the apron and clipped at the canvas edge.
#  2. Clear / Cut / Copy (TOOLS/SELECTION.BM) used canvas coords on the buffer ->
#     a correct (rectangle) selection deleted the wrong pixels, up-left.
#
# Each section paints a mark, selects around it and checks the marching ants are
# there (bug 1), presses Delete and asserts the mark is gone (bug 2). A WITNESS
# mark outside every selection must survive - an empty (fully clipped) selection
# would otherwise let Delete clear the whole layer and pass by accident.
# =============================================================================

info "=== Polygon / freehand selection after a Move promotes the apron ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Promote the layer: draw, select all, Move the content past the right edge --
info "Draw content and move it past the right edge (promotes the apron)"
drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.3 "Stroke"
key ctrl+a
wait_for 0.5 "Select all"
key v
wait_for 0.3 "Move tool"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 120 )) $CANVAS_CY
wait_for 0.5 "Moved right past the edge"
key b
wait_for 0.3 "Brush (commits move)"
key ctrl+d
wait_for 0.2 "Deselect"
key grave
wait_for 0.1 "Pointer hidden"
assert_no_crash

# Mark spots: polygon target (upper left), freehand target (upper middle), witness
# (lower left). All left of the moved content, which now sits right of CX+80.
PX=$(( CANVAS_CX - 40 )); PY=$(( CANVAS_CY - 28 ))
FX=$(( CANVAS_CX + 2 ));  FY=$(( CANVAS_CY - 28 ))
RX=$(( CANVAS_CX - 40 )); RY=$(( CANVAS_CY + 1 ))
WX=$(( CANVAS_CX - 40 )); WY=$(( CANVAS_CY + 30 ))
BOX=28   # snap box around each mark (marks are ~12px, selections ~24px)

park_mouse
snap_region $(( PX - BOX/2 )) $(( PY - BOX/2 )) $BOX $BOX "sel-poly-blank";  P_BLANK="$SNAP_RESULT"
snap_region $(( FX - BOX/2 )) $(( FY - BOX/2 )) $BOX $BOX "sel-free-blank";  F_BLANK="$SNAP_RESULT"
snap_region $(( RX - BOX/2 )) $(( RY - BOX/2 )) $BOX $BOX "sel-rect-blank";  R_BLANK="$SNAP_RESULT"
snap_region $(( WX - BOX/2 )) $(( WY - BOX/2 )) $BOX $BOX "sel-wit-blank";   W_BLANK="$SNAP_RESULT"

info "Paint the marks on the promoted layer"
drag $(( PX - 5 )) $PY $(( PX + 5 )) $PY; wait_for 0.3 "polygon target"
drag $(( FX - 5 )) $FY $(( FX + 5 )) $FY; wait_for 0.3 "freehand target"
drag $(( RX - 5 )) $RY $(( RX + 5 )) $RY; wait_for 0.3 "rectangle target"
drag $(( WX - 5 )) $WY $(( WX + 5 )) $WY; wait_for 0.3 "witness"
park_mouse
snap_region $(( PX - BOX/2 )) $(( PY - BOX/2 )) $BOX $BOX "sel-poly-marked"; P_MARKED="$SNAP_RESULT"
assert_regions_differ "$P_BLANK" "$P_MARKED" "the polygon target mark was painted"
snap_region $(( FX - BOX/2 )) $(( FY - BOX/2 )) $BOX $BOX "sel-free-marked"; F_MARKED="$SNAP_RESULT"
assert_regions_differ "$F_BLANK" "$F_MARKED" "the freehand target mark was painted"
snap_region $(( RX - BOX/2 )) $(( RY - BOX/2 )) $BOX $BOX "sel-rect-marked"; R_MARKED="$SNAP_RESULT"
assert_regions_differ "$R_BLANK" "$R_MARKED" "the rectangle target mark was painted"
snap_region $(( WX - BOX/2 )) $(( WY - BOX/2 )) $BOX $BOX "sel-wit-marked"; W_MARKED="$SNAP_RESULT"
assert_regions_differ "$W_BLANK" "$W_MARKED" "the witness mark was painted"

# -- POLYGON SELECT (action 120, no default key): 4 vertices, right-click closes --
info "Polygon select around the upper-left mark, Delete"
key question
wait_for 0.5 "Command palette"
type_text "polygon select"
wait_for 0.3 "Filter"
key Return
wait_for 0.4 "Polygon Select tool"
click $(( PX - 11 )) $(( PY - 11 )); wait_for 0.2 "v1"
click $(( PX + 11 )) $(( PY - 11 )); wait_for 0.2 "v2"
click $(( PX + 11 )) $(( PY + 11 )); wait_for 0.2 "v3"
click $(( PX - 11 )) $(( PY + 11 )); wait_for 0.2 "v4"
right_click $(( PX - 11 )) $(( PY + 11 )); wait_for 0.4 "close polygon"
park_mouse
screenshot "sel-poly-selected"
snap_region $(( PX - BOX/2 )) $(( PY - BOX/2 )) $BOX $BOX "sel-poly-ants"
assert_regions_differ "$P_MARKED" "$SNAP_RESULT" \
    "the polygon selection's marching ants are around the mark it was drawn around (not shifted by the apron)"
key Delete
wait_for 0.4 "Delete selection contents"
key ctrl+d
wait_for 0.3 "Deselect"
assert_no_crash
park_mouse
snap_region $(( PX - BOX/2 )) $(( PY - BOX/2 )) $BOX $BOX "sel-poly-after"
assert_regions_same "$P_BLANK" "$SNAP_RESULT" \
    "the polygon selection covered the mark it was drawn around (Delete removed it)" 30
snap_region $(( WX - BOX/2 )) $(( WY - BOX/2 )) $BOX $BOX "sel-wit-after-poly"
assert_regions_same "$W_MARKED" "$SNAP_RESULT" "the witness outside the polygon selection survived" 30

# -- FREEHAND SELECT (action 119): hold, trace a loop around the mark, release --
info "Freehand select around the upper-middle mark, Delete"
key question
wait_for 0.5 "Command palette"
type_text "freehand select"
wait_for 0.3 "Filter"
key Return
wait_for 0.4 "Freehand Select tool"
mouse_down $(( FX - 11 )) $(( FY - 11 ))
for pt in "$(( FX ))  $(( FY - 12 ))" "$(( FX + 11 )) $(( FY - 11 ))" "$(( FX + 12 )) $(( FY ))" \
          "$(( FX + 11 )) $(( FY + 11 ))" "$(( FX ))  $(( FY + 12 ))" "$(( FX - 11 )) $(( FY + 11 ))" \
          "$(( FX - 12 )) $(( FY ))" "$(( FX - 11 )) $(( FY - 10 ))"; do
    hover $pt; sleep 0.05
done
mouse_up
wait_for 0.4 "freehand selection closed"
park_mouse
screenshot "sel-free-selected"
snap_region $(( FX - BOX/2 )) $(( FY - BOX/2 )) $BOX $BOX "sel-free-ants"
assert_regions_differ "$F_MARKED" "$SNAP_RESULT" \
    "the freehand selection's marching ants are around the mark it was drawn around (not shifted by the apron)"
key Delete
wait_for 0.4 "Delete selection contents"
key ctrl+d
wait_for 0.3 "Deselect"
assert_no_crash
park_mouse
snap_region $(( FX - BOX/2 )) $(( FY - BOX/2 )) $BOX $BOX "sel-free-after"
assert_regions_same "$F_BLANK" "$SNAP_RESULT" \
    "the freehand selection covered the mark it was drawn around (Delete removed it)" 30
snap_region $(( WX - BOX/2 )) $(( WY - BOX/2 )) $BOX $BOX "sel-wit-after-free"
assert_regions_same "$W_MARKED" "$SNAP_RESULT" "the witness outside the freehand selection survived" 30

# -- RECTANGLE SELECT: its mask was always right; Delete cleared the wrong spot --
info "Rectangle select around the middle-left mark, Delete"
key m
wait_for 0.3 "Rect marquee tool"
drag $(( RX - 11 )) $(( RY - 10 )) $(( RX + 11 )) $(( RY + 10 ))
wait_for 0.4 "rectangle selection"
park_mouse
screenshot "sel-rect-selected"
snap_region $(( RX - BOX/2 )) $(( RY - BOX/2 )) $BOX $BOX "sel-rect-ants"
assert_regions_differ "$R_MARKED" "$SNAP_RESULT" "the rectangle selection's marching ants are around its mark"
key Delete
wait_for 0.4 "Delete selection contents"
key ctrl+d
wait_for 0.3 "Deselect"
assert_no_crash
park_mouse
snap_region $(( RX - BOX/2 )) $(( RY - BOX/2 )) $BOX $BOX "sel-rect-after"
assert_regions_same "$R_BLANK" "$SNAP_RESULT" \
    "the rectangle selection's Delete removed its mark (not a spot up-left by the apron)" 30
snap_region $(( WX - BOX/2 )) $(( WY - BOX/2 )) $BOX $BOX "sel-wit-after-rect"
assert_regions_same "$W_MARKED" "$SNAP_RESULT" "the witness outside the rectangle selection survived" 30

key b
wait_for 0.2 "Brush"
screenshot "apron-select-after-move"
assert_no_crash
assert_window_exists
info "=== apron selection test COMPLETE ==="
