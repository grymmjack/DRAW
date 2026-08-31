#!/bin/bash
# =============================================================================
# effect-text-rasterize-undo.sh — BUG-I guard
#
# Applying an image effect to a TEXT layer must auto-rasterize it, then a SINGLE
# Ctrl+Z must restore the pre-effect editable text (rasterize+effect = one undo).
#   * Make a text layer, commit it.
#   * Snap the text region.
#   * Apply Add Noise -> text rasterizes + noise applied (region changes).
#   * ONE Ctrl+Z -> the region must return to the pre-effect text (single undo).
# =============================================================================

info "=== BUG-I: effect on text layer rasterizes, single-undo restores text ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key t ; wait_for 0.5 "Text tool"
click "$CANVAS_CX" "$CANVAS_CY" ; wait_for 0.3 "Editing started"
type_text "RASTER"
wait_for 0.4 "Typed"
key Escape ; wait_for 0.4 "Text committed (text layer)"
key grave ; wait_for 0.2 "pointer hidden"
assert_no_crash

WX=$(( CANVAS_CX - 45 )); WY=$(( CANVAS_CY - 12 )); WW=90; WH=28
park_mouse
snap_region "$WX" "$WY" "$WW" "$WH" "I-text-before"
BEFORE="$SNAP_RESULT"

# Apply Add Noise (should auto-rasterize the text first).
open_effect 5 0 ; wait_for 0.5 "Add Noise dialog"
key Return ; wait_for 0.8 "Applied (rasterize + noise)"
assert_no_crash
park_mouse
snap_region "$WX" "$WY" "$WW" "$WH" "I-text-after-effect"
AFTEREFFECT="$SNAP_RESULT"
screenshot "I-after-effect"

# ONE Ctrl+Z must restore the pre-effect text.
key ctrl+z ; wait_for 0.6 "Single undo"
key grave ; wait_for 0.2 "pointer hidden"
park_mouse
snap_region "$WX" "$WY" "$WW" "$WH" "I-text-after-undo"
AFTERUNDO="$SNAP_RESULT"
screenshot "I-after-undo"

assert_regions_differ "$BEFORE" "$AFTEREFFECT" "Effect must visibly change the text (rasterize + noise)"
assert_regions_same   "$BEFORE" "$AFTERUNDO"  "A SINGLE Ctrl+Z must restore the pre-effect text (BUG-I)"
assert_no_crash
assert_window_exists
info "=== BUG-I test complete ==="
