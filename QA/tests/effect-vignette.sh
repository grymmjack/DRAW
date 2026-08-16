#!/bin/bash
# =============================================================================
# effect-vignette.sh — QA test / regression guard
#
# EFFECTS > Vignette... darkens the image toward its edges/corners.
# (Added 2026-08-14.) Flood-fills the layer flat grey, applies Vignette via the
# EFFECTS menu, and asserts a CORNER region darkened (centre barely changes, so
# we must sample a corner).
#
# EFFECTS menu index 6 (0-based) -> dropdown item viewport y = 20 + 6*12 = 92.
# =============================================================================

info "=== Effect: Vignette Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"

# Flood-fill the whole layer flat mid-grey (chip 16 = 112,112,112) with the Fill
# tool, so the vignette's corner darkening is clearly visible.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 16*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Grey FG"
key f ; wait_for 0.2 "Fill tool"
click "$CANVAS_CX" "$CANVAS_CY" ; wait_for 0.4 "Layer flooded grey"
key grave
wait_for 0.3 "Filled"
assert_no_crash

# Sample a corner (canvas is 320x200 @2x -> ~160x100 viewport half-extent).
CX=$(( CANVAS_CX - 150 )); CY=$(( CANVAS_CY - 90 )); CW=36; CH=36
park_mouse
snap_region "$CX" "$CY" "$CW" "$CH" "vignette-before"
BEFORE="$SNAP_RESULT"

# Open Vignette via EFFECTS menu, ensure strength is high, commit with Return.
open_effect 1 2 ; wait_for 0.5 "Vignette dialog open"
screenshot "vignette-dialog"
drag 400 317 590 317 ; wait_for 0.2 "Strength up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$CX" "$CY" "$CW" "$CH" "vignette-after"
AFTER="$SNAP_RESULT"
screenshot "vignette-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Vignette must darken the corner of the flat-grey layer"
assert_no_crash
assert_window_exists
info "=== Effect: Vignette Test PASSED ==="
