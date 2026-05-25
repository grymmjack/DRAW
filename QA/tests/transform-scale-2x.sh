#!/bin/bash
# =============================================================================
# transform-scale-2x.sh — QA test: Ctrl+Home / Ctrl+End scale 2x per-axis
# Actions 331 (Scale 2x Horizontal) / 333 (Scale 2x Vertical).
#
# Recently-added feature (commits 449569b etc). Operates on:
#   1. Active custom brush (priority), OR
#   2. Floating MOVE selection, OR
#   3. Auto-lifts an inline marquee then scales.
# This test exercises path #3 (auto-lift from inline marquee).
# =============================================================================

info "=== Scale 2x H/V (Ctrl+Home / Ctrl+End) Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw an asymmetric shape (offset L) on the canvas --
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 15 ))
wait_for 0.3 "Top line"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.3 "Left edge"
assert_no_crash

# -- Make a marquee around the shape --
key m
wait_for 0.3 "Marquee tool"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 25 )) $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 25 ))
wait_for 0.4 "Marquee created"

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "scale-2x-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Ctrl+Home = Scale 2x Horizontal (auto-lifts marquee, doubles width) --
info "Ctrl+Home (Scale 2x Horizontal — auto-lifts marquee)"
key ctrl+Home
wait_for 0.6 "Scale H applied"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "scale-2x-h"
SCALE_H="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$SCALE_H" "Ctrl+Home should double width of selection"

# -- Ctrl+End = Scale 2x Vertical (operates on floating selection from Ctrl+Home) --
info "Ctrl+End (Scale 2x Vertical)"
key ctrl+End
wait_for 0.6 "Scale V applied"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "scale-2x-hv"
SCALE_HV="$SNAP_RESULT"
assert_regions_differ "$SCALE_H" "$SCALE_HV" "Ctrl+End should double height of selection"

# -- Cancel the move (Escape) and undo to clean up --
key Escape
wait_for 0.3 "Move cancelled"
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Undo strokes"
assert_no_crash

assert_window_exists
info "=== Scale 2x H/V Test PASSED ==="
