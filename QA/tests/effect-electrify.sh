#!/bin/bash
# =============================================================================
# effect-electrify.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Electrify... crackling electric blue-white arcs around the shape edge (noise-thresholded filaments).
# alpha edge. (Added 2026-08-14, Eye Candy.) Transparent layer: green blob, FG
# set to magenta, apply, assert a ring appears in the band around the blob.
#
# SHAPE is EFFECTS category index 7; Electrify is child 18 -> open_effect 7 18.
# =============================================================================

info "=== Effect: Electrify Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 20 )) "$CANVAS_CY" $(( CANVAS_CX + 20 )) "$CANVAS_CY"
click $(( 16 + 28*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "FG magenta (ring colour)"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Band around the blob where the ring falls.
GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 18 )); GW=80; GH=36
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "electrify-before"
BEFORE="$SNAP_RESULT"

open_effect 7 18 ; wait_for 0.5 "Electrify dialog open"
screenshot "electrify-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "electrify-after"
AFTER="$SNAP_RESULT"
screenshot "electrify-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Electrify must crackle electric arcs around the shape edge"
assert_no_crash
assert_window_exists
info "=== Effect: Electrify Test PASSED ==="
