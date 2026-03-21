#!/bin/bash
# =============================================================================
# edit-fill-fg-bg.sh — QA test: Fill tool on canvas
# Tests: Switch to fill tool (f), click canvas to flood fill, undo
# Verifies fill changes canvas pixels and undo restores them
# =============================================================================

# -- Establish known state --
info "=== Edit Fill FG/BG Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Snap canvas before fill --
BEFORE_FILL=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "fill-fg-before")
assert_no_crash

# -- Switch to fill tool and fill canvas center --
info "Switch to fill tool (f)"
key f
wait_for 0.3 "Fill tool selected"

info "Flood fill at canvas center"
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Flood fill applied"
assert_no_crash

# -- Snap canvas after fill --
AFTER_FILL=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "fill-fg-after")
assert_regions_differ "$BEFORE_FILL" "$AFTER_FILL" "Flood fill should change canvas pixels"
screenshot "fill-fg-result"

# -- Undo fill --
info "Undo fill (Ctrl+Z)"
key ctrl+z
wait_for 0.5 "Undo flood fill"
assert_no_crash

# -- Verify undo restored canvas --
UNDO_FILL=$(snap_region $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )) 60 60 "fill-fg-undo")
assert_regions_same "$BEFORE_FILL" "$UNDO_FILL" "Undo should restore canvas after fill"

# -- Restore brush tool --
info "Restoring brush tool"
key b
wait_for 0.2 "Back to brush tool"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Edit Fill FG/BG Test PASSED ==="
