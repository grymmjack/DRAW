#!/bin/bash
# =============================================================================
# brightness-contrast-preserve-blacks.sh — QA test / regression guard
#
# Brightness/Contrast dialog "Preserve Blacks" toggle: when ON, pure-black
# (0,0,0) pixels stay black while everything else brightens. (Added 2026-08-14.)
#
# Draws a blue stroke + a black stroke, raises brightness with Preserve Blacks
# ON, and asserts the black stroke is STILL black while the blue stroke brightens
# (proving the op ran). A broken toggle would lift the black to grey.
# =============================================================================

info "=== Brightness/Contrast Preserve Blacks Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 2*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Blue"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 30 )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY - 30 ))
click $(( 16 + 0*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Black"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY + 30 )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY + 30 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

BLK_X=$(( CANVAS_CX - 60 )); BLK_Y=$(( CANVAS_CY + 22 )); BLK_W=120; BLK_H=16
BLU_X=$(( CANVAS_CX - 60 )); BLU_Y=$(( CANVAS_CY - 38 )); BLU_W=120; BLU_H=16

park_mouse
snap_region "$BLU_X" "$BLU_Y" "$BLU_W" "$BLU_H" "pb-blue-before"
BLUE_BEFORE="$SNAP_RESULT"

# Open Brightness/Contrast, enable Preserve Blacks, raise brightness, apply.
key question ; wait_for 0.5 "Command palette"
type_text "Brightness" ; wait_for 0.5 "Filtered"
key Return ; wait_for 0.7 "BC dialog open"
click 439 347 ; wait_for 0.3 "Preserve Blacks ON"          # toggle
drag 477 284 580 284 ; wait_for 0.3 "Brightness raised"    # brightness slider
screenshot "pb-dialog"
click 414 398 ; wait_for 0.7 "Applied (OK)"                # OK
assert_no_crash

park_mouse
snap_region "$BLK_X" "$BLK_Y" "$BLK_W" "$BLK_H" "pb-black-after"
BLACK_AFTER="$SNAP_RESULT"
BMEAN=$(magick "$BLACK_AFTER" -format '%[fx:int(mean*255)]' info: 2>/dev/null)
info "  [black mean after +brightness w/ preserve] ${BMEAN:-?}"

snap_region "$BLU_X" "$BLU_Y" "$BLU_W" "$BLU_H" "pb-blue-after"
BLUE_AFTER="$SNAP_RESULT"
screenshot "pb-canvas-after"

# The op must have run (blue changed) AND black must still be black.
assert_regions_differ "$BLUE_BEFORE" "$BLUE_AFTER" "Brightness increase should brighten the blue stroke"
if [[ "${BMEAN:-99}" -le 8 ]] 2>/dev/null; then
    pass "Preserve Blacks kept the black stroke black (mean ${BMEAN})"
else
    fail "Preserve Blacks failed — black stroke lifted to grey (mean ${BMEAN})"
fi

assert_no_crash
assert_window_exists
info "=== Brightness/Contrast Preserve Blacks Test PASSED ==="
