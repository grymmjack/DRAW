#!/bin/bash
# =============================================================================
# file-extract-images.sh — QA test: Extract Images Tool
# Tests: Open extract config via command palette, cancel, verify no crash.
# NOTE: Actual extraction requires output directory selection (native dialog
# which is unreliable to automate). We verify the dialog opens, Escape
# closes it, and DRAW remains responsive afterward.
# =============================================================================

info "=== Extract Images Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw distinct sprites to extract (single brush clicks) --
click "$(( CANVAS_CX - 40 ))" "$CANVAS_CY"
wait_for 0.2 "Sprite 1"
click "$(( CANVAS_CX + 40 ))" "$CANVAS_CY"
wait_for 0.2 "Sprite 2"
assert_no_crash

# -- Open Extract Images via command palette --
info "Open Extract Images"
key question
wait_for 0.5 "Command palette"
type_text "extract"
wait_for 0.3 "Filter"
key Return
wait_for 1.0 "Extract Images config dialog opened"
assert_no_crash
screenshot "extract-images-dialog"

# -- Cancel the dialog --
info "Cancel Extract Images (Escape)"
key Escape
wait_for 1.0 "Dialog cancelled (give it time to fully close)"
# Defensive second Escape for any chained prompt
key Escape
wait_for 0.3 "Any remaining dialog cancelled"
assert_no_crash

# -- Verify DRAW still responsive (no strict canvas check — dialog
#    overlays can leave repaints on some window managers) --
key b
wait_for 0.3 "Switch to brush — dispatch still works post-dialog"
assert_no_crash

# -- Clean up the two dots --
key ctrl+z
wait_for 0.2 "Undo sprite 2"
key ctrl+z
wait_for 0.2 "Undo sprite 1"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Extract Images Test PASSED ==="
