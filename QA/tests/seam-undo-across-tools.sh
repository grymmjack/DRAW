#!/bin/bash
# =============================================================================
# seam-undo-across-tools.sh — SEAM TEST: undo across tool switches
# History is unified (TOOLS/HISTORY). Undo must target the most recent committed
# action regardless of which tool is currently selected. Draw with the brush,
# switch tools and draw a line, switch to the eraser, then Ctrl+Z must undo the
# LINE (not a no-op, not the brush stroke), leaving the brush stroke intact.
# =============================================================================

info "=== SEAM: undo across tool switches ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Empty baseline --
park_mouse
snap_region $(( CANVAS_CX - 55 )) $(( CANVAS_CY - 40 )) 110 80 "seam-undo-empty"
EMPTY="$SNAP_RESULT"

# -- Action 1: brush stroke (upper area) --
info "Brush stroke (action 1)"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 30 )) $(( CANVAS_CY - 20 ))
wait_for 0.4 "Stroke"
park_mouse
snap_region $(( CANVAS_CX - 55 )) $(( CANVAS_CY - 40 )) 110 80 "seam-undo-after-brush"
AFTER_BRUSH="$SNAP_RESULT"
assert_regions_differ "$EMPTY" "$AFTER_BRUSH" "Brush stroke drawn (setup)"

# -- Switch to LINE and draw a line (action 2, lower area) --
info "Switch to line tool; draw a line (action 2)"
key l
wait_for 0.2 "Line tool"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY + 20 )) $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 20 ))
wait_for 0.4 "Line drawn"
park_mouse
snap_region $(( CANVAS_CX - 55 )) $(( CANVAS_CY - 40 )) 110 80 "seam-undo-after-line"
AFTER_LINE="$SNAP_RESULT"
assert_regions_differ "$AFTER_BRUSH" "$AFTER_LINE" "Line drawn (setup)"

# -- Switch to the ERASER, then Ctrl+Z: must undo the LINE (cross-tool) --
info "Switch to eraser; Ctrl+Z must undo the LINE, keep the brush stroke"
key e
wait_for 0.2 "Eraser"
key ctrl+z
wait_for 0.4 "Undo"
park_mouse
snap_region $(( CANVAS_CX - 55 )) $(( CANVAS_CY - 40 )) 110 80 "seam-undo-after-undo"
AFTER_UNDO="$SNAP_RESULT"
assert_regions_same "$AFTER_BRUSH" "$AFTER_UNDO" "Ctrl+Z (while on eraser) must undo the LINE and restore the brush-only state (cross-tool undo)"
screenshot "seam-undo-across-tools"

# -- Second undo removes the brush stroke → empty --
key ctrl+z
wait_for 0.4 "Undo brush"
park_mouse
snap_region $(( CANVAS_CX - 55 )) $(( CANVAS_CY - 40 )) 110 80 "seam-undo-empty2"
AFTER_UNDO2="$SNAP_RESULT"
assert_regions_same "$EMPTY" "$AFTER_UNDO2" "Second Ctrl+Z undoes the brush stroke (back to empty)"

assert_no_crash
assert_window_exists
info "=== SEAM undo-across-tools test COMPLETE ==="
