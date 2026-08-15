#!/bin/bash
# =============================================================================
# posterize-dither-color.sh — QA test / regression guard
#
# Posterize with a dither mode enabled must preserve COLOUR. The dither routines
# used to reduce every pixel to 1-bit grayscale (black/white); they now dither
# per-channel to the posterize level count. (Fixed 2026-08-14.)
#
# Draws cyan/gray/magenta strokes, applies Posterize + Ordered-2x2 dither, and
# asserts the result still contains many colours (not the ~2 of a B/W collapse).
# The old code physically could not exceed 2 colours from the dither, so the
# > 6 threshold is a hard guard.
# =============================================================================

info "=== Posterize + Dither Colour Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Three strokes in three palette colours (chip centre: x = 16 + i*17 + 8).
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 5*17 + 8 ))  "$CHIP_Y" ; wait_for 0.2 "Colour 1"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 40 )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY - 40 ))
click $(( 16 + 15*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Colour 2"
drag $(( CANVAS_CX - 80 )) "$CANVAS_CY" $(( CANVAS_CX + 80 )) "$CANVAS_CY"
click $(( 16 + 25*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Colour 3"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY + 40 )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY + 40 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

STRIP_X=$(( CANVAS_CX - 90 )); STRIP_Y=$(( CANVAS_CY - 55 )); STRIP_W=180; STRIP_H=110

# Open Posterize, turn on a dither mode, and apply.
key question ; wait_for 0.5 "Command palette"
type_text "Posterize" ; wait_for 0.5 "Filtered"
key Return ; wait_for 0.7 "Posterize dialog open"
# Dialog is centred; DITHER is now a DROPDOWN box ~ (478,311), OK ~ (414,395).
# Open the dropdown, arrow to the first algorithm (index 1 = OFF is index 0),
# and Enter to commit — keyboard nav avoids pixel-targeting a popup row.
click 478 311 ; wait_for 0.4 "Dither dropdown open"
key Down ; wait_for 0.2 "Highlight first algorithm"
key Return ; wait_for 0.3 "Dither mode committed"
click 414 395 ; wait_for 0.7 "Applied via OK"
assert_no_crash

park_mouse
snap_region "$STRIP_X" "$STRIP_Y" "$STRIP_W" "$STRIP_H" "posterize-dither-result"
RESULT_IMG="$SNAP_RESULT"
NCOLOURS=$(magick "$RESULT_IMG" -format %k info: 2>/dev/null)
info "  [colours] unique colours after posterize+dither: ${NCOLOURS:-?}"
screenshot "posterize-dither-canvas"

if [[ "${NCOLOURS:-0}" -gt 6 ]] 2>/dev/null; then
    pass "Posterize+dither preserved colour (${NCOLOURS} unique colours)"
else
    fail "Posterize+dither collapsed to ~B/W (${NCOLOURS:-?} unique colours, expected > 6)"
fi

assert_no_crash
assert_window_exists
info "=== Posterize + Dither Colour Test PASSED ==="
