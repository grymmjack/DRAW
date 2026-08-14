#!/bin/bash
# =============================================================================
# effect-wave.sh — QA test / regression guard
#
# EFFECTS > Wave / Ripple... sinusoidally displaces pixels. (Added 2026-08-14.)
# Draws a straight horizontal green line, applies Wave, and asserts the region
# changed (the line becomes wavy).
#
# EFFECTS menu index 21 (0-based) -> dropdown item viewport y = 20 + 21*12 = 272.
# =============================================================================

info "=== Effect: Wave / Ripple Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 90 )) $(( CANVAS_CY )) $(( CANVAS_CX + 90 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 80 )); GY=$(( CANVAS_CY - 18 )); GW=160; GH=36
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "wave-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 272 ; wait_for 0.7 "Wave dialog open"
screenshot "wave-dialog"
drag 400 317 560 317 ; wait_for 0.2 "Amplitude up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "wave-after"
AFTER="$SNAP_RESULT"
screenshot "wave-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Wave must ripple the straight green line"
assert_no_crash
assert_window_exists
info "=== Effect: Wave / Ripple Test PASSED ==="
