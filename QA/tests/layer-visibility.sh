#!/bin/bash
# =============================================================================
# layer-visibility.sh — QA test: Toggle layer visibility
# Tests: Click eye icon in layer panel to hide/show layer
# Verifies canvas updates when layer visibility is toggled
# =============================================================================

# -- Eye icon location (LAYERS_DOCK=LEFT, first layer row) --
EYE_X=5
EYE_Y=42

# -- Canvas center region for visibility checks --
CW=80
CH=80
CX=$(( CANVAS_CX - CW / 2 ))
CY=$(( CANVAS_CY - CH / 2 ))

# -- Establish known state --
info "=== Layer Visibility Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Draw something on canvas so visibility has visible effect --
info "Drawing brush stroke on canvas"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 ))
wait_for 0.3 "Wait for brush stroke"
assert_no_crash

CANVAS_WITH_CONTENT=$(snap_region $CX $CY $CW $CH "canvas-with-content")
screenshot "canvas-with-brush-stroke"

# -- Toggle visibility OFF: click eye icon --
info "Hiding layer by clicking eye icon"
click $EYE_X $EYE_Y
wait_for 0.5 "Wait for visibility toggle off"
assert_no_crash

CANVAS_HIDDEN=$(snap_region $CX $CY $CW $CH "canvas-layer-hidden")
assert_regions_differ "$CANVAS_WITH_CONTENT" "$CANVAS_HIDDEN" "Canvas should change when layer is hidden"
screenshot "canvas-layer-hidden"

# -- Toggle visibility ON: click eye icon again --
info "Showing layer by clicking eye icon again"
click $EYE_X $EYE_Y
wait_for 0.5 "Wait for visibility toggle on"
assert_no_crash

CANVAS_VISIBLE=$(snap_region $CX $CY $CW $CH "canvas-layer-visible-again")
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
