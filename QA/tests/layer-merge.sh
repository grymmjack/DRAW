#!/bin/bash
# =============================================================================
# layer-merge.sh — QA test: Merge layers
# Tests: Ctrl+Alt+E (merge down), undo
# =============================================================================

info "=== Layer Merge Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw on layer 1 --
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 10 ))
wait_for 0.3 "Stroke on layer 1"
assert_no_crash

# -- Create a new layer --
info "Creating new layer (Ctrl+Shift+N)"
key ctrl+shift+n
wait_for 0.5 "New layer created"
assert_no_crash

# -- Draw on layer 2 --
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 10 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 10 ))
wait_for 0.3 "Stroke on layer 2"
assert_no_crash

# -- Snap layer panel before merge --
click $CANVAS_CX $CANVAS_CY
snap_region $LP_X $LP_Y $LP_W $LP_H "merge-panel-before"
PANEL_BEFORE="$SNAP_RESULT"

# -- Merge down: Ctrl+Alt+E --
info "Merge layer down (Ctrl+Alt+E)"
key ctrl+alt+e
wait_for 0.8 "Layer merged down"
assert_no_crash

click $CANVAS_CX $CANVAS_CY
snap_region $LP_X $LP_Y $LP_W $LP_H "merge-panel-after"
PANEL_AFTER="$SNAP_RESULT"
assert_regions_differ "$PANEL_BEFORE" "$PANEL_AFTER" "Layer panel should change after merge"
screenshot "after-merge-down"

# -- Undo merge --
info "Undoing merge (Ctrl+Z)"
key ctrl+z
wait_for 0.5 "Merge undone"
assert_no_crash

click $CANVAS_CX $CANVAS_CY
snap_region $LP_X $LP_Y $LP_W $LP_H "merge-panel-undo"
PANEL_UNDO="$SNAP_RESULT"
assert_regions_same "$PANEL_BEFORE" "$PANEL_UNDO" "Undo should restore original layer state"

# -- Cleanup: undo layer and strokes --
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Cleanup"
assert_no_crash

assert_window_exists
info "=== Layer Merge Test PASSED ==="
