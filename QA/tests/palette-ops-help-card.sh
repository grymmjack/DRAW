#!/bin/bash
# =============================================================================
# palette-ops-help-card.sh — QA test: gesture help card (GUI/HELP-CARD)
#
# Palette Ops on, hover a strip swatch -> after HELP_CARD_DELAY the Palette Ops
# card appears just above the strip (bottom edge of the canvas area); moving
# away hides it; with color cycling on (Shift+Tab) the hover shows the cycling
# card instead (different content).
# =============================================================================

info "=== Palette Ops Help Card Test ==="
canvas_focus b
wait_for 0.3 "Canvas focused"
key grave
wait_for 0.1 "Pointer arrow hidden"

ORG_TOP=$(( TOOLBAR_H + 1 ))
ORG_COLW=$(( 11 * TOOLBAR_SCALE )); ORG_ROW0=$(( 10 * TOOLBAR_SCALE )); ORG_SP=$(( 1 * TOOLBAR_SCALE ))
ORG_COL0_CX=$(( TB_X + 1 + ORG_COLW / 2 ))
PALOPS_BTN_Y=$(( ORG_TOP + ORG_ROW0 + ORG_SP + ORG_ROW0 / 2 ))
CHIP_W=${PALETTE_CHIP_WIDTH:-16}
chip_x() { echo $(( 16 + $1 * (CHIP_W + 1) + CHIP_W / 2 )); }
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
# band of the canvas area right above the strip, where the card docks
BAND_Y=$(( VIEWPORT_H - STATUS_H - 14 - 70 ))
snap_band() { snap_region $(( CANVAS_CX - 150 )) $BAND_Y 300 60 "$1"; BAND="$SNAP_RESULT"; }

info "Palette Ops on"
click $ORG_COL0_CX $PALOPS_BTN_Y
wait_for 0.4 "Palette Ops active"
park_mouse
wait_for 0.3 "settle"
snap_band "card-none"; NONE="$BAND"

info "Hover a swatch -> Palette Ops card"
hover $(chip_x 3) $CHIP_Y
wait_for 0.9 "help card delay"
snap_band "card-palops"; PALOPS="$BAND"
screenshot "help-card-palops"
assert_regions_differ "$NONE" "$PALOPS" "Hovering the strip in Palette Ops must show the help card"

info "Move away -> card hides"
park_mouse
wait_for 0.5 "hidden"
snap_band "card-hidden"; HIDDEN="$BAND"
assert_regions_same "$NONE" "$HIDDEN" "Leaving the strip must hide the help card"

info "Shift+Tab (cycling on) + hover -> cycling card"
with_mods shift key Tab
wait_for 0.3 "cycling on"
hover $(chip_x 3) $CHIP_Y
wait_for 0.9 "help card delay"
snap_band "card-cycle"; CYC="$BAND"
screenshot "help-card-cycle"
assert_regions_differ "$PALOPS" "$CYC" "With cycling on the card must show the cycling gestures"
park_mouse
with_mods shift key Tab
wait_for 0.3 "cycling off"

assert_no_crash
assert_window_exists
info "=== Palette Ops Help Card Test PASSED ==="
