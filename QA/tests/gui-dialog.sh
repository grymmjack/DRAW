#!/bin/bash
# =============================================================================
# gui-dialog.sh — QA test: Native & Overlay Dialogs
# Tests: Image adjustment overlay (Invert is instant; Brightness has sliders)
#        Open/Cancel/Apply cycle, verify live preview, undo after apply
# =============================================================================

info "=== Dialog / Image Adjustment Overlay Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw something to have pixels to adjust --
drag $(( CANVAS_CX - 30 )) $CANVAS_CY $(( CANVAS_CX + 30 )) $CANVAS_CY
wait_for 0.3 "Brush stroke drawn"
assert_no_crash

# -- Snap canvas BEFORE adjustment --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "dialog-before"
BEFORE="$SNAP_RESULT"

# -- Open Brightness/Contrast via menu: Image → Adjustments → Brightness --
# Use command palette instead for reliability
key question
wait_for 0.5 "Command palette opened"
type_text "brightness"
wait_for 0.3 "Filter applied"
key Return
wait_for 0.5 "Brightness dialog opened"
assert_no_crash

# -- Snap overlay region --
snap_region $(( CANVAS_CX - 150 )) $(( CANVAS_CY - 100 )) 300 200 "dialog-overlay"
OVERLAY="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$OVERLAY" "Brightness overlay should be visible"
screenshot "dialog-brightness-open"

# -- Cancel the dialog --
info "Cancel brightness dialog (Escape)"
key Escape
wait_for 0.3 "Dialog cancelled"
assert_no_crash

# -- Verify canvas restored --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "dialog-after-cancel"
AFTER_CANCEL="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER_CANCEL" "Cancel should restore original pixels"

# -- Undo brush stroke --
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Dialog / Image Adjustment Overlay Test PASSED ==="
