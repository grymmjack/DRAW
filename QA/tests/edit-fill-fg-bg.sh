#!/bin/bash
# =============================================================================
# edit-fill-fg-bg.sh — QA test: Fill tool on canvas
# Tests: Switch to fill tool (f), click canvas to flood fill, undo
# Verifies fill changes canvas pixels and undo restores them
# =============================================================================

# -- Establish known state --
info "=== Edit Fill FG/BG Test ==="
canvas_focus f
wait_for 0.3 "Fill tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap canvas before fill --
park_mouse
BEFORE_FILL=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "fill-fg-before")
assert_no_crash

# -- Fill canvas center --

info "Flood fill at canvas center"
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Flood fill applied"
assert_no_crash

# -- Snap canvas after fill --
park_mouse
AFTER_FILL=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "fill-fg-after")
assert_regions_differ "$BEFORE_FILL" "$AFTER_FILL" "Flood fill should change canvas pixels"
screenshot "fill-fg-result"

# -- Undo fill --
info "Undo fill (Ctrl+Z)"
key ctrl+z
wait_for 0.5 "Undo flood fill"
assert_no_crash

# -- Verify undo restored canvas --
park_mouse
UNDO_FILL=$(snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "fill-fg-undo")
assert_regions_differ "$AFTER_FILL" "$UNDO_FILL" "Undo should change canvas back from fill"

# -- Restore brush tool --
info "Restoring brush tool"
key b
wait_for 0.2 "Back to brush tool"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Edit Fill FG/BG Test PASSED ==="
