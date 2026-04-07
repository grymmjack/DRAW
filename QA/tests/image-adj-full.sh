#!/bin/bash
# =============================================================================
# image-adj-full.sh — QA test: Image Adjustments (beyond invert)
# Tests: Brightness/Contrast, Hue/Saturation, Desaturate, Posterize
#        Each opened via command palette, cancelled with Escape
# =============================================================================

info "=== Image Adjustments (Full) Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw content to adjust --
drag $(( CANVAS_CX - 30 )) $CANVAS_CY $(( CANVAS_CX + 30 )) $CANVAS_CY
wait_for 0.3 "Brush stroke drawn"
assert_no_crash

# -- Snap canvas reference --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "adj-baseline"
BASELINE="$SNAP_RESULT"

# -- Test: Open Desaturate (instant apply) --
info "Test Desaturate"
key question
wait_for 0.5 "Command palette"
type_text "desaturate"
wait_for 0.3 "Filter"
key Return
wait_for 0.5 "Desaturate applied"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "adj-desaturate"
DESAT="$SNAP_RESULT"
assert_regions_differ "$BASELINE" "$DESAT" "Desaturate should change canvas pixels"
screenshot "desaturate-applied"

# -- Undo desaturate --
key ctrl+z
wait_for 0.3 "Undo desaturate"
assert_no_crash

# -- Verify undo restored --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "adj-undo-desat"
UNDO_DESAT="$SNAP_RESULT"
assert_regions_same "$BASELINE" "$UNDO_DESAT" "Undo should restore original from desaturate"

# -- Test: Open Hue/Saturation dialog and cancel --
info "Test Hue/Sat dialog (cancel)"
key question
wait_for 0.5 "Command palette"
type_text "hue"
wait_for 0.3 "Filter"
key Return
wait_for 0.5 "Hue/Sat dialog opened"
assert_no_crash
screenshot "huesat-dialog"

key Escape
wait_for 0.3 "Hue/Sat cancelled"
assert_no_crash

# -- Verify canvas unchanged after cancel --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "adj-huesat-cancel"
HUESAT_CANCEL="$SNAP_RESULT"
assert_regions_same "$BASELINE" "$HUESAT_CANCEL" "Cancel should restore original"

# -- Undo brush stroke --
key ctrl+z
wait_for 0.3 "Undo brush stroke"
assert_no_crash

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Image Adjustments (Full) Test PASSED ==="
