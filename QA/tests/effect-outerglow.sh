#!/bin/bash
# =============================================================================
# effect-outerglow.sh — QA test / regression guard
#
# EFFECTS > Outer Glow... radiates a soft coloured halo (FG colour) outside the
# shape's alpha edges. (Added 2026-08-14.) Transparent layer: green stroke, FG
# set to magenta (glow colour), apply Outer Glow, assert a halo appears in the
# band around the stroke.
#
# EFFECTS menu index 18 (0-based) -> dropdown item viewport y = 20 + 18*12 = 236.
# =============================================================================

info "=== Effect: Outer Glow Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 60 )) $(( CANVAS_CY )) $(( CANVAS_CX + 60 )) $(( CANVAS_CY ))
click $(( 16 + 28*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG magenta (glow colour)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Band taller than the stroke so the halo above/below shows.
GX=$(( CANVAS_CX - 50 )); GY=$(( CANVAS_CY - 22 )); GW=100; GH=44
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "outerglow-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 236 ; wait_for 0.7 "Outer Glow dialog open"
screenshot "outerglow-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "outerglow-after"
AFTER="$SNAP_RESULT"
screenshot "outerglow-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Outer Glow must add a halo around the stroke"
assert_no_crash
assert_window_exists
info "=== Effect: Outer Glow Test PASSED ==="
