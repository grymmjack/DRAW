#!/bin/bash
# =============================================================================
# seam-partial-shape-abandon.sh — SEAM TEST: partial shape → tool switch
# Guards the shape-in-progress → tool-switch seam (CLAUDE.md gotcha #5/#9/#15):
# starting a multi-click shape (polygon) and then switching tools must NOT leave
# a phantom undo state behind. If it does, the next Ctrl+Z undoes the ghost
# (no visible change) instead of the real previous action.
#
# Method: draw a brush stroke (a real, undoable action), then place 2 polygon
# vertices WITHOUT closing, switch to the brush (abandon the polygon), then
# Ctrl+Z. A correct build undoes the BRUSH STROKE (canvas returns to empty). A
# buggy build undoes a ghost polygon state first, leaving the stroke on screen.
# =============================================================================

info "=== SEAM: partial shape abandon → no ghost undo ==="

canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Empty baseline --
park_mouse
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 45 )) 120 90 "seam-abandon-empty"
EMPTY="$SNAP_RESULT"

# -- Draw a real brush stroke (the action we expect Ctrl+Z to undo) --
info "Drawing brush stroke (the real undoable action)"
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.4 "Stroke drawn"
park_mouse
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 45 )) 120 90 "seam-abandon-stroke"
STROKE="$SNAP_RESULT"
assert_regions_differ "$EMPTY" "$STROKE" "Brush stroke must be drawn (setup sanity)"

# -- Start a polygon and place two vertices, but DO NOT close it --
info "Placing 2 polygon vertices (partial, uncommitted)"
key p
wait_for 0.2 "Polygon tool"
click $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 20 ))
wait_for 0.2 "Vertex 1"
click $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 20 ))
wait_for 0.2 "Vertex 2"
assert_no_crash

# -- THE SEAM: switch back to the brush, abandoning the partial polygon --
info "Switching to brush (abandons the partial polygon)"
key b
wait_for 0.4 "Tool switched"
assert_no_crash

# -- Undo once. Must undo the BRUSH STROKE, not a ghost polygon state. --
info "Ctrl+Z — must undo the brush stroke (not a phantom polygon undo state)"
key ctrl+z
wait_for 0.4 "Undo"
park_mouse
snap_region $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 45 )) 120 90 "seam-abandon-after-undo"
AFTER="$SNAP_RESULT"

# Correct: stroke undone → canvas empty again. Buggy: ghost undo left the stroke.
assert_regions_same "$EMPTY" "$AFTER" "Undo after abandoning a partial polygon must undo the brush stroke, not a phantom shape undo state (shape→tool seam)"
screenshot "seam-abandon-after-undo"

assert_no_crash
assert_window_exists
info "=== SEAM partial-shape-abandon test COMPLETE ==="
