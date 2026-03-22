#!/bin/bash
# =============================================================================
# edit-undo-redo.sh — QA test: Multi-step undo/redo chain
# Tests: Ctrl+Z (undo ×3), Ctrl+Y (redo ×3) after drawing 3 brush strokes
# Verifies strokes are removed on undo and restored on redo
# =============================================================================

# -- Establish known state --
info "=== Edit Undo/Redo Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw 3 brush strokes at different positions --
info "Drawing stroke 1"
drag $(( CANVAS_CX - 25 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 25 )) $(( CANVAS_CY - 20 ))
wait_for 0.3 "Stroke 1 drawn"
assert_no_crash

info "Drawing stroke 2"
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.3 "Stroke 2 drawn"
assert_no_crash

info "Drawing stroke 3"
drag $(( CANVAS_CX - 25 )) $(( CANVAS_CY + 20 )) $(( CANVAS_CX + 25 )) $(( CANVAS_CY + 20 ))
wait_for 0.3 "Stroke 3 drawn"
assert_no_crash

# -- Snap canvas after all 3 strokes --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "undo-redo-all-strokes"
ALL_STROKES="$SNAP_RESULT"
screenshot "undo-redo-3-strokes"

# -- Undo 3 times --
info "Undoing 3 strokes with Ctrl+Z"
key ctrl+z
wait_for 0.3 "Undo stroke 3"
key ctrl+z
wait_for 0.3 "Undo stroke 2"
key ctrl+z
wait_for 0.3 "Undo stroke 1"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "undo-redo-after-undo"
AFTER_UNDO="$SNAP_RESULT"
assert_regions_differ "$ALL_STROKES" "$AFTER_UNDO" "Undo should remove all strokes"
screenshot "undo-redo-after-undo"

# -- Redo 3 times --
info "Redoing 3 strokes with Ctrl+Y"
key ctrl+y
wait_for 0.3 "Redo stroke 1"
key ctrl+y
wait_for 0.3 "Redo stroke 2"
key ctrl+y
wait_for 0.3 "Redo stroke 3"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "undo-redo-after-redo"
AFTER_REDO="$SNAP_RESULT"
assert_regions_differ "$AFTER_UNDO" "$AFTER_REDO" "Redo should restore all strokes"
screenshot "undo-redo-after-redo"

# -- Clean up: undo all strokes --
info "Cleaning up — undoing all strokes"
key ctrl+z
key ctrl+z
key ctrl+z
wait_for 0.3 "Cleanup complete"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Edit Undo/Redo Test PASSED ==="
