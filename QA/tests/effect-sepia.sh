#!/bin/bash
# =============================================================================
# effect-sepia.sh — QA test / regression guard
#
# EFFECTS > Sepia must warm-tone the active layer in one shot (no dialog).
# (Added 2026-08-14.) Draws a saturated blue stroke, applies Sepia via the
# command palette, and asserts the region changed (blue -> warm brown-grey).
# =============================================================================

info "=== Effect: Sepia Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Saturated blue stroke (chip index 3 = 75,76,255 in ANSI32) — sepia shifts it
# strongly toward warm sepia, guaranteeing a visible diff.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 3*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Blue FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "sepia-before"
BEFORE="$SNAP_RESULT"

# Apply Sepia via the command palette (one-shot, no dialog).
key question ; wait_for 0.5 "Command palette"
type_text "Sepia" ; wait_for 0.5 "Filtered"
key Return ; wait_for 0.7 "Sepia applied"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "sepia-after"
AFTER="$SNAP_RESULT"
screenshot "sepia-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Sepia must warm-tone the stroke (blue -> sepia)"
assert_no_crash
assert_window_exists
info "=== Effect: Sepia Test PASSED ==="
