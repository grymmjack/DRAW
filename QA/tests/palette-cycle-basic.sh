#!/bin/bash
# =============================================================================
# palette-cycle-basic.sh — QA test: palette color cycling end to end
#
# Draws a filled rect with palette chip #2, marks chips 2-5 in Color Ops,
# creates a cycle range from the marked chips (command palette), then:
#   Shift+Tab ON  -> the canvas animates (two snaps a beat apart differ, and
#                    differ from the uncycled art)
#   Shift+Tab OFF -> the canvas shows the true colors again (== before)
#   Ctrl+Z        -> the range is gone: Shift+Tab no longer animates
# =============================================================================

info "=== Palette Cycle Basic Test ==="
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

# -- FG = chip #2, filled rect --
info "FG = chip 2, draw filled rect"
click $(chip_x 2) $CHIP_Y
wait_for 0.2 "FG picked"
key shift+r
wait_for 0.2 "Rect filled tool"
drag $ART_X $ART_Y $(( ART_X + 120 )) $(( ART_Y + 80 ))
wait_for 0.4 "Rect drawn"
assert_no_crash

park_mouse
snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "cyc-art"
ART="$SNAP_RESULT"

# -- Color Ops: mark chips 2..5, range from marked --
info "Color Ops: mark chips 2-5"
click $ORG_COL0_CX $PALOPS_BTN_Y
wait_for 0.4 "Color Ops active"
for i in 2 3 4 5; do right_click $(chip_x $i) $CHIP_Y; wait_for 0.15 "mark chip $i"; done
park_mouse
info "Range from marked chips (command palette)"
key question
wait_for 0.4 "Command palette open"
type_text "range from marked"
wait_for 0.3 "Filtered"
key Return
wait_for 0.4 "Range added"
assert_no_crash

# -- Cycling on: the art animates --
info "Shift+Tab: cycling ON"
park_mouse
with_mods shift key Tab
wait_for 0.25 "Cycling"
snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "cyc-on-a"
ON_A="$SNAP_RESULT"
wait_for 0.33 "a few steps later"
snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "cyc-on-b"
ON_B="$SNAP_RESULT"
screenshot "cyc-on"
assert_regions_differ "$ON_A" "$ON_B" "Cycling must animate the canvas"

# -- Cycling off: true colors --
info "Shift+Tab: cycling OFF"
with_mods shift key Tab
wait_for 0.3 "Cycling off"
snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "cyc-off"
OFF="$SNAP_RESULT"
assert_regions_same "$ART" "$OFF" "Cycling off must restore the true colors"

# -- Undo the range: cycling no longer animates --
info "Ctrl+Z removes the range"
key ctrl+z
wait_for 0.3 "Undone"
with_mods shift key Tab
wait_for 0.25 "Cycling on (no ranges)"
snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "cyc-undo-a"
U_A="$SNAP_RESULT"
wait_for 0.33 "later"
snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "cyc-undo-b"
U_B="$SNAP_RESULT"
assert_regions_same "$U_A" "$U_B" "After undoing the range nothing cycles"
with_mods shift key Tab
wait_for 0.2 "Cycling off"

assert_no_crash
assert_window_exists
info "=== Palette Cycle Basic Test PASSED ==="
