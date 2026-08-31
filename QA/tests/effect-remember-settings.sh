#!/bin/bash
# =============================================================================
# effect-remember-settings.sh — BUG-K guard (Crystallize template)
#
# Effects must remember their last settings (Last-Set slot) and restore them on
# reopen instead of snapping back to defaults.
#   * Open Crystallize (CELL SIZE defaults to 12 -> slider near the left).
#   * Drag CELL SIZE far right, apply (OK).
#   * Reopen Crystallize -> the slider must show the remembered (large) value,
#     NOT reset to the default. Compare the slider strip: reopen != default-open.
# Crystallize = PIXELATE cat 4 child 0. Slider at vp y=317, x 369..589.
# =============================================================================

info "=== BUG-K: effect remembers last settings on reopen ==="

canvas_focus b
wait_for 0.3 "Brush ready"
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 21*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG colour"
for dy in -20 -10 0 10 20; do
    drag $(( CANVAS_CX - 50 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 50 )) $(( CANVAS_CY + dy ))
done
key grave ; wait_for 0.3 "Content drawn"

SLX=359; SLY=310; SLW=242; SLH=16

# First open — default cell size (slider near left).
open_effect 4 0 ; wait_for 0.5 "Crystallize (default)"
screenshot "K-open-default"
park_mouse
snap_region "$SLX" "$SLY" "$SLW" "$SLH" "K-slider-default"
DEFAULT="$SNAP_RESULT"
# Drag CELL SIZE far right, then apply.
drag 369 317 589 317 ; wait_for 0.3 "Cell size increased"
snap_region "$SLX" "$SLY" "$SLW" "$SLH" "K-slider-changed"
CHANGED="$SNAP_RESULT"
key Return ; wait_for 0.7 "Applied (OK)"
assert_no_crash

# Reopen — must restore the remembered (large) cell size, not the default.
open_effect 4 0 ; wait_for 0.5 "Crystallize (reopen)"
screenshot "K-reopen"
park_mouse
snap_region "$SLX" "$SLY" "$SLW" "$SLH" "K-slider-reopen"
REOPEN="$SNAP_RESULT"
key Escape ; wait_for 0.3 "closed"

assert_regions_differ "$DEFAULT" "$CHANGED" "Dragging the slider must change it (sanity)"
assert_regions_same   "$CHANGED" "$REOPEN"  "Reopen must restore the remembered cell size (BUG-K)"
assert_no_crash
assert_window_exists
info "=== BUG-K test complete ==="
