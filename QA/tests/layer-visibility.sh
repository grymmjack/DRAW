#!/bin/bash
# =============================================================================
# layer-visibility.sh — QA test: Toggle layer visibility
# Tests: Click eye icon in layer panel to hide/show layer
# Verifies canvas updates when layer visibility is toggled
# =============================================================================

# -- Eye icon location (LAYERS_DOCK=LEFT, first layer row) --
# Panel Y=0, header = 16px, first row Y = 16-35 (20px high)
# Eye icon hit-zone: localX < 14, centered in 20px row
# Midpoint of first row = 16 + 10 = 26
EYE_X=7
EYE_Y=26

# -- Establish known state --
info "=== Layer Visibility Test ==="
canvas_focus b
wait_for 0.3 "Canvas focused, brush tool"
key bracketright
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw something on canvas so visibility has visible effect --
info "Drawing brush stroke on canvas"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 30 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 30 ))
wait_for 0.3 "Wait for brush stroke"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "canvas-with-content"
CANVAS_WITH_CONTENT="$SNAP_RESULT"
screenshot "canvas-with-brush-stroke"

# -- Toggle visibility OFF: click eye icon --
info "Hiding layer by clicking eye icon"
click $EYE_X $EYE_Y
wait_for 0.5 "Wait for visibility toggle off"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "canvas-layer-hidden"
CANVAS_HIDDEN="$SNAP_RESULT"
assert_regions_differ "$CANVAS_WITH_CONTENT" "$CANVAS_HIDDEN" "Canvas should change when layer is hidden"
screenshot "canvas-layer-hidden"

# -- Toggle visibility ON: click eye icon again --
info "Showing layer by clicking eye icon again"
click $EYE_X $EYE_Y
wait_for 0.5 "Wait for visibility toggle on"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "canvas-layer-visible-again"
CANVAS_VISIBLE="$SNAP_RESULT"
assert_regions_differ "$CANVAS_HIDDEN" "$CANVAS_VISIBLE" "Canvas should change when layer is shown again"
screenshot "canvas-layer-visible-again"

# -- Undo brush stroke to clean up --
info "Undoing brush stroke with Ctrl+Z"
key ctrl+z
wait_for 0.5 "Wait for undo"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Layer Visibility Test PASSED ==="
