#!/bin/bash
# =============================================================================
# palette-ops-help-card-top.sh — QA test: HELP_CARD_EDGE=TOP docks the help
# card under the menu bar instead of above the palette strip.
# QA-OPTIONS: HELP_CARD_EDGE=TOP
# =============================================================================

info "=== Palette Ops Help Card (top edge) Test ==="
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
TOP_Y=$(( MENU_BAR_H + 20 ))
BOT_Y=$(( VIEWPORT_H - STATUS_H - 14 - 70 ))

click $ORG_COL0_CX $PALOPS_BTN_Y
wait_for 0.4 "Palette Ops active"
park_mouse
wait_for 0.3 "settle"
snap_region $(( CANVAS_CX - 150 )) $TOP_Y 300 50 "top-none"; TOP_NONE="$SNAP_RESULT"
snap_region $(( CANVAS_CX - 150 )) $BOT_Y 300 60 "bot-none"; BOT_NONE="$SNAP_RESULT"

hover $(chip_x 3) $CHIP_Y
wait_for 0.9 "help card delay"
snap_region $(( CANVAS_CX - 150 )) $TOP_Y 300 50 "top-card"; TOP_CARD="$SNAP_RESULT"
snap_region $(( CANVAS_CX - 150 )) $BOT_Y 300 60 "bot-card"; BOT_CARD="$SNAP_RESULT"
screenshot "help-card-top"
assert_regions_differ "$TOP_NONE" "$TOP_CARD" "HELP_CARD_EDGE=TOP: card appears under the menu bar"
assert_regions_same "$BOT_NONE" "$BOT_CARD" "HELP_CARD_EDGE=TOP: nothing appears above the strip"

park_mouse
assert_no_crash
assert_window_exists
info "=== Palette Ops Help Card (top edge) Test PASSED ==="
