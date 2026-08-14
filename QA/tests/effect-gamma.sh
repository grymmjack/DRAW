#!/bin/bash
# =============================================================================
# effect-gamma.sh — QA test / regression guard
#
# EFFECTS > Gamma... must open a dialog and, on OK with a non-zero amount,
# change the layer's midtones. (Added 2026-08-14 — first of the new effects.)
#
# Draws a mid-grey stroke, opens Gamma via the command palette, drags the
# bipolar slider well positive (lighten midtones), applies, and asserts the
# grey region changed. Guards the whole wire-up: menu/action/dialog/engine.
# =============================================================================

info "=== Effect: Gamma Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Mid-grey stroke. ANSI32 chip index 16 (0-based) = RGB 112,112,112 — a true
# midtone, so gamma actually shifts it (gamma maps 0->0 and 255->255 unchanged,
# so pure black/white/primaries would NOT change).
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 16*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Mid-grey FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 8 )); GW=120; GH=16
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "gamma-before"
BEFORE="$SNAP_RESULT"

# Open Gamma via the command palette (robust vs. submenu geometry).
key question ; wait_for 0.5 "Command palette"
type_text "Gamma" ; wait_for 0.5 "Filtered"
key Return ; wait_for 0.7 "Gamma dialog open"
screenshot "gamma-dialog"

# Drag the AMOUNT slider (viewport y~317) from centre to the far right to push
# the amount strongly positive (lighten midtones), then commit with Return
# (keyboard OK — avoids per-dialog OK-button geometry).
drag 479 317 590 317 ; wait_for 0.3 "Amount raised"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "gamma-after"
AFTER="$SNAP_RESULT"
screenshot "gamma-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Gamma with a positive amount must change the stroke's midtones"
assert_no_crash
assert_window_exists
info "=== Effect: Gamma Test PASSED ==="
