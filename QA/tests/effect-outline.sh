#!/bin/bash
# =============================================================================
# effect-outline.sh — QA test / regression guard
#
# EFFECTS > Outline / Stroke... adds a coloured border along the shape's alpha
# edges, in the current FG colour. (Added 2026-08-14.) Draws a GREEN stroke,
# switches FG to RED, applies Outline (OUTSIDE), and asserts a band around the
# stroke changed (red pixels added above/below the green line).
#
# EFFECTS menu index 7 (0-based) -> dropdown item viewport y = 20 + 7*12 = 104.
# =============================================================================

info "=== Effect: Outline / Stroke Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
# The default Background layer is OPAQUE (CLS DEFAULT_LAYER_BG_COLOR), so an
# OUTSIDE stroke has no transparency to key on. Add a fresh TRANSPARENT layer.
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Green stroke (chip 11 = 76,255,77) on the transparent layer.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY ))
# Switch FG to red (chip 23 = 254,71,70) — the stroke colour for the outline.
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG (stroke colour)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Band taller than the stroke so the OUTSIDE stroke (added above/below) shows.
GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 16 )); GW=120; GH=32
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "outline-before"
BEFORE="$SNAP_RESULT"

# Open Outline via EFFECTS menu; push THICKNESS up; commit with Return.
open_effect 1 3 ; wait_for 0.5 "Outline dialog open"
screenshot "outline-dialog"
drag 400 317 540 317 ; wait_for 0.2 "Thickness up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "outline-after"
AFTER="$SNAP_RESULT"
screenshot "outline-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Outline must add a red border around the green stroke"
assert_no_crash
assert_window_exists
info "=== Effect: Outline / Stroke Test PASSED ==="
