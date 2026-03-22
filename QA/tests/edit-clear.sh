#!/bin/bash
# =============================================================================
# edit-clear.sh — QA test: Clear canvas (Delete) and undo
# Tests: Draw stroke, Delete (clear layer), Ctrl+Z (undo clear)
# Verifies clear removes content and undo restores it
# =============================================================================

# -- Establish known state --
info "=== Edit Clear Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw a brush stroke --
info "Drawing brush stroke"
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.5 "Brush stroke drawn"
assert_no_crash

# -- Snap canvas after stroke --
park_mouse
WITH_STROKE=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "clear-with-stroke")
screenshot "clear-before"

# -- Clear canvas: Delete key --
info "Clear canvas (Delete)"
key Delete
wait_for 0.5 "Canvas cleared"
assert_no_crash

# -- Snap canvas after clear --
park_mouse
AFTER_CLEAR=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "clear-after-clear")
assert_regions_differ "$WITH_STROKE" "$AFTER_CLEAR" "Clear should remove all canvas content"
screenshot "clear-after"

# -- Undo clear --
info "Undo clear (Ctrl+Z)"
key ctrl+z
wait_for 0.5 "Undo clear"
assert_no_crash

# -- Verify undo restored the stroke (compare vs cleared state — content should return) --
park_mouse
AFTER_UNDO=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "clear-after-undo")
assert_regions_differ "$AFTER_CLEAR" "$AFTER_UNDO" "Undo should restore canvas after clear"
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
