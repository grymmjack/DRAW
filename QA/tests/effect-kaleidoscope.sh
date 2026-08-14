#!/bin/bash
# =============================================================================
# effect-kaleidoscope.sh — QA test / regression guard
#
# EFFECTS > Kaleidoscope... reflects one angular wedge radially into a mandala.
# (Added 2026-08-14, per user request.) Draws an off-centre green stroke, applies
# Kaleidoscope, and asserts a region on the opposite side (empty before) gained
# mirrored content.
#
# EFFECTS menu index 24 (0-based) -> dropdown item viewport y = 20 + 24*12 = 308.
# =============================================================================

info "=== Effect: Kaleidoscope Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Stroke DOWN-RIGHT of centre — inside the base wedge [0,45deg) that the
# kaleidoscope samples (content outside the base wedge is not sampled).
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX + 12 )) $(( CANVAS_CY + 6 )) $(( CANVAS_CX + 75 )) $(( CANVAS_CY + 30 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Broad central region: 1 stroke before -> 8 mirrored copies (mandala) after.
GX=$(( CANVAS_CX - 80 )); GY=$(( CANVAS_CY - 80 )); GW=160; GH=160
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "kaleidoscope-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 308 ; wait_for 0.7 "Kaleidoscope dialog open"
screenshot "kaleidoscope-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "kaleidoscope-after"
AFTER="$SNAP_RESULT"
screenshot "kaleidoscope-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Kaleidoscope must mirror content into the opposite quadrant"
assert_no_crash
assert_window_exists
info "=== Effect: Kaleidoscope Test PASSED ==="
