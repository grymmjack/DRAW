#!/bin/bash
# =============================================================================
# effect-glow.sh — QA test / regression guard
#
# EFFECTS > Glow... additively blooms a blurred copy over the layer (alpha kept).
# (Added 2026-08-14.) Draws a bright saturated stroke, opens Glow, bumps radius
# + intensity, commits with Return, asserts the region brightened/changed.
# =============================================================================

info "=== Effect: Glow Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Bright green stroke (chip 11 = 76,255,77) — glow adds a blurred bloom of it.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "glow-before"
BEFORE="$SNAP_RESULT"

# Open Glow via the EFFECTS menu (deterministic; the command palette open is
# racy under the harness). EFFECTS root @ (395,6); dropdown items start at
# viewport y~20, 12px apart: GAMMA20 SEPIA32 THRESHOLD44 COLORIZE56 GLOW68.
open_effect 1 0 ; wait_for 0.5 "Glow dialog open"
screenshot "glow-dialog"
drag 400 317 560 317 ; wait_for 0.2 "Radius up"
drag 400 355 580 355 ; wait_for 0.2 "Intensity up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "glow-after"
AFTER="$SNAP_RESULT"
screenshot "glow-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Glow must bloom/brighten the stroke"
assert_no_crash
assert_window_exists
info "=== Effect: Glow Test PASSED ==="
