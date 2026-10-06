#!/bin/bash
# =============================================================================
# palette-cycle-strip.sh — QA test: range bands + cycling swatches on the strip
#
#   Ctrl+L-drag chips 2..5        -> a band appears under the swatches
#   Ctrl+L-click (direction REV)  -> the band pattern changes (solid -> dash-dot)
#   Shift+Tab                     -> the strip swatches themselves animate
#   Shift+Tab off                 -> the strip is still again
# =============================================================================

info "=== Palette Cycle Strip Test ==="
canvas_focus b
wait_for 0.3 "Canvas focused, brush tool"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Geometry (see palette-ops-color-edit.sh for the derivation) --
ORG_TOP=$(( TOOLBAR_H + 1 ))
ORG_COLW=$(( 11 * TOOLBAR_SCALE ))
ORG_ROW0=$(( 10 * TOOLBAR_SCALE ))
ORG_SP=$(( 1 * TOOLBAR_SCALE ))
ORG_COL0_CX=$(( TB_X + 1 + ORG_COLW / 2 ))
PALOPS_BTN_Y=$(( ORG_TOP + ORG_ROW0 + ORG_SP + ORG_ROW0 / 2 ))
CHIP_W=${PALETTE_CHIP_WIDTH:-16}
chip_x() { echo $(( 16 + $1 * (CHIP_W + 1) + CHIP_W / 2 )); }
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
ART_X=$(( CANVAS_CX - 60 )); ART_Y=$(( CANVAS_CY - 40 ))

# -- FG = chip #2, flood-fill the (transparent) canvas with it: one click,
#    deterministic (a rect drag occasionally lands before the tool switch) --
info "FG = chip 2, fill the canvas"
park_mouse
snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "cyc-empty"
EMPTY="$SNAP_RESULT"
click $(chip_x 2) $CHIP_Y
wait_for 0.2 "FG picked"
key f
wait_for 0.3 "Fill tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Canvas filled"
assert_no_crash

park_mouse
snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "cyc-art"
ART="$SNAP_RESULT"
assert_regions_differ "$EMPTY" "$ART" "Setup: the canvas must be filled with chip 2"

# helper: two canvas snaps a beat apart -> sets A_SNAP / B_SNAP
two_snaps() {
    snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "$1-a"; A_SNAP="$SNAP_RESULT"
    wait_for 0.35 "$1: a few steps later"
    snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "$1-b"; B_SNAP="$SNAP_RESULT"
}

STRIP_Y=$(( VIEWPORT_H - STATUS_H - 14 ))
snap_strip() { snap_region 0 $STRIP_Y 400 14 "$1"; STRIP_SNAP="$SNAP_RESULT"; }

info "Color Ops on"
click $ORG_COL0_CX $PALOPS_BTN_Y
wait_for 0.4 "Color Ops active"
park_mouse
snap_strip "strip-none"; S_NONE="$STRIP_SNAP"

info "Ctrl+drag chips 2..5 -> band"
ctrl_drag $(chip_x 2) $CHIP_Y $(chip_x 5) $CHIP_Y
park_mouse
wait_for 0.4 "Range created"
snap_strip "strip-fwd"; S_FWD="$STRIP_SNAP"
assert_regions_differ "$S_NONE" "$S_FWD" "A range band must appear under the swatches"

info "Ctrl+click -> REV (band pattern changes)"
with_mods ctrl click $(chip_x 3) $CHIP_Y
park_mouse
wait_for 0.4 "Direction changed"
snap_strip "strip-rev"; S_REV="$STRIP_SNAP"
assert_regions_differ "$S_FWD" "$S_REV" "Direction change must change the band pattern"

info "Shift+Tab -> swatches animate"
with_mods shift key Tab
wait_for 0.3 "Cycling"
snap_strip "strip-cyc-a"; A="$STRIP_SNAP"
wait_for 0.35 "later"
snap_strip "strip-cyc-b"; B="$STRIP_SNAP"
screenshot "cyc-strip"
assert_regions_differ "$A" "$B" "Range swatches must cycle on the strip"

info "Shift+Tab off -> strip still"
with_mods shift key Tab
wait_for 0.4 "Cycling off"
snap_strip "strip-off-a"; A="$STRIP_SNAP"
wait_for 0.35 "later"
snap_strip "strip-off-b"; B="$STRIP_SNAP"
assert_regions_same "$A" "$B" "Strip is still with cycling off"
assert_regions_same "$S_REV" "$A" "Strip shows the true colors again"

assert_no_crash
assert_window_exists
info "=== Palette Cycle Strip Test PASSED ==="
