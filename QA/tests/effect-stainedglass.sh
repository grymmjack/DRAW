#!/bin/bash
# =============================================================================
# effect-stainedglass.sh — QA test / regression guard
#
# EFFECTS > Stained Glass... Voronoi panes with dark leading between them.
# (Added 2026-08-14.) Crossing green + red strokes, apply, assert the region
# changed (panes + dark borders).
#
# EFFECTS menu index 26 (0-based) -> dropdown item viewport y = 20 + 26*12 = 332.
# =============================================================================

info "=== Effect: Stained Glass Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG"
drag "$CANVAS_CX" $(( CANVAS_CY - 50 )) "$CANVAS_CX" $(( CANVAS_CY + 50 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "stainedglass-before"
BEFORE="$SNAP_RESULT"

click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 332 ; wait_for 0.7 "Stained Glass dialog open"
screenshot "stainedglass-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "stainedglass-after"
AFTER="$SNAP_RESULT"
screenshot "stainedglass-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Stained Glass must add panes with dark borders"
assert_no_crash
assert_window_exists
info "=== Effect: Stained Glass Test PASSED ==="
