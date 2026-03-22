#!/bin/bash
# =============================================================================
# layer-opacity.sh — QA test: Change layer opacity via scroll wheel
# Tests: Scroll wheel on opacity area in layer panel
# Verifies canvas rendering changes with opacity adjustment
# =============================================================================

# -- Opacity area in layer panel (LAYERS_DOCK=LEFT, first layer row) --
OPACITY_X=50
OPACITY_Y=42

# -- Canvas center region for opacity checks --
CW=160
CH=120
CX=$(( CANVAS_CX - CW / 2 ))
CY=$(( CANVAS_CY - CH / 2 ))

# -- Establish known state --
info "=== Layer Opacity Test ==="
canvas_focus b
wait_for 0.3 "Canvas focused, brush tool"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw something on canvas so opacity change is visible --
info "Drawing brush stroke on canvas"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 ))
wait_for 0.3 "Wait for brush stroke"
assert_no_crash

park_mouse
snap_region $CX $CY $CW $CH "canvas-full-opacity"
CANVAS_FULL_OPACITY="$SNAP_RESULT"
screenshot "canvas-full-opacity"

# -- Reduce opacity by scrolling down on opacity area --
info "Reducing opacity via scroll wheel"
scroll_down $OPACITY_X $OPACITY_Y
scroll_down $OPACITY_X $OPACITY_Y
scroll_down $OPACITY_X $OPACITY_Y
scroll_down $OPACITY_X $OPACITY_Y
scroll_down $OPACITY_X $OPACITY_Y
wait_for 0.5 "Wait for opacity reduction"
assert_no_crash

park_mouse
snap_region $CX $CY $CW $CH "canvas-reduced-opacity"
CANVAS_REDUCED="$SNAP_RESULT"
assert_regions_differ "$CANVAS_FULL_OPACITY" "$CANVAS_REDUCED" "Canvas should look different at reduced opacity"
screenshot "canvas-reduced-opacity"

# -- Restore opacity by scrolling back up --
info "Restoring opacity via scroll wheel"
scroll_up $OPACITY_X $OPACITY_Y
scroll_up $OPACITY_X $OPACITY_Y
scroll_up $OPACITY_X $OPACITY_Y
scroll_up $OPACITY_X $OPACITY_Y
scroll_up $OPACITY_X $OPACITY_Y
wait_for 0.5 "Wait for opacity restore"
assert_no_crash

park_mouse
snap_region $CX $CY $CW $CH "canvas-restored-opacity"
CANVAS_RESTORED="$SNAP_RESULT"
assert_regions_differ "$CANVAS_REDUCED" "$CANVAS_RESTORED" "Canvas should change when opacity is restored"
assert_regions_same "$CANVAS_FULL_OPACITY" "$CANVAS_RESTORED" "Restoring opacity should match original state"
screenshot "canvas-restored-opacity"

# -- Undo brush stroke to clean up --
info "Undoing brush stroke with Ctrl+Z"
key ctrl+z
wait_for 0.5 "Wait for undo"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Layer Opacity Test PASSED ==="
