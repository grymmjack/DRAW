#!/bin/bash
# =============================================================================
# file-extract-images.sh — QA test: Extract Images Tool
# Tests: Open extract config via command palette, cancel, verify no crash
# NOTE: Actual extraction requires output directory; this tests dialog cycle.
# =============================================================================

info "=== Extract Images Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw distinct sprites to extract --
click $(( CANVAS_CX - 40 )) $CANVAS_CY
wait_for 0.2 "Sprite 1"
click $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.2 "Sprite 2"
assert_no_crash

# -- Snap canvas before --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 40 )) 160 80 "extract-before"
BEFORE="$SNAP_RESULT"

# -- Open Extract Images via command palette --
info "Open Extract Images"
key question
wait_for 0.5 "Command palette"
type_text "extract"
wait_for 0.3 "Filter"
key Return
wait_for 0.5 "Extract Images opened"
assert_no_crash
screenshot "extract-images-dialog"

# -- Cancel the dialog --
info "Cancel Extract Images (Escape)"
key Escape
wait_for 0.3 "Dialog cancelled"
assert_no_crash

# -- Verify canvas unchanged --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 40 )) 160 80 "extract-after-cancel"
AFTER_CANCEL="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER_CANCEL" "Cancel should not change canvas"

# -- Clean up --
key ctrl+z
wait_for 0.2 "Undo"
key ctrl+z
wait_for 0.2 "Undo"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Extract Images Test PASSED ==="
