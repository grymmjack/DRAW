#!/bin/bash
# =============================================================================
# edit-clear.sh — QA test: Clear canvas (BackSpace) and undo
# Tests: Draw stroke, BackSpace (clear without prompt), Ctrl+Z (undo clear)
# Verifies clear removes content and undo restores it
# =============================================================================

# -- Establish known state --
info "=== Edit Clear Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Draw a brush stroke --
info "Drawing brush stroke"
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.5 "Brush stroke drawn"
assert_no_crash

# -- Snap canvas after stroke --
WITH_STROKE=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "clear-with-stroke")
screenshot "clear-before"

# -- Clear canvas: BackSpace --
info "Clear canvas (BackSpace)"
key BackSpace
wait_for 0.5 "Canvas cleared"
assert_no_crash

# -- Snap canvas after clear --
AFTER_CLEAR=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "clear-after-clear")
assert_regions_differ "$WITH_STROKE" "$AFTER_CLEAR" "Clear should remove all canvas content"
screenshot "clear-after"

# -- Undo clear --
info "Undo clear (Ctrl+Z)"
key ctrl+z
wait_for 0.5 "Undo clear"
assert_no_crash

# -- Verify undo restored the stroke --
AFTER_UNDO=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "clear-after-undo")
assert_regions_same "$WITH_STROKE" "$AFTER_UNDO" "Undo should restore canvas after clear"
screenshot "clear-after-undo"

# -- Clean up: undo the stroke --
info "Cleaning up — undoing brush stroke"
key ctrl+z
wait_for 0.3 "Stroke undone"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Edit Clear Test PASSED ==="
