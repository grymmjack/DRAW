#!/bin/bash
# =============================================================================
# palette-cycle-gestures.sh — QA test: Color Ops Ctrl gestures for cycle ranges
#
# In Color Ops mode:
#   Ctrl+L-drag chips 2..5  -> new range; Shift+Tab animates the art
#   Ctrl+R-click a chip      -> pause (art holds still) / resume (animates)
#   Ctrl+Wheel over a chip   -> speed changes (status readout changes)
#   Ctrl+M-click a chip      -> range deleted (true colors while cycling on)
#   Ctrl+Z                   -> range back (animates again)
#
# Snaps meant to catch motion are 0.15 s apart on purpose: a 4-color range at
# 10 steps/s repeats every 0.4 s, so snaps ~0.4 s apart can land on the same
# frame of the loop and look "identical" (also at 12/15 steps/s after Ctrl+Wheel).
# =============================================================================

info "=== Palette Cycle Gestures Test ==="
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
    wait_for 0.15 "$1: a few steps later"
    snap_region $(( ART_X + 10 )) $(( ART_Y + 10 )) 100 60 "$1-b"; B_SNAP="$SNAP_RESULT"
}

info "Color Ops on; Ctrl+drag chips 2..5"
click $ORG_COL0_CX $PALOPS_BTN_Y
wait_for 0.4 "Color Ops active"
ctrl_drag $(chip_x 2) $CHIP_Y $(chip_x 5) $CHIP_Y
wait_for 0.4 "Range created"
park_mouse
with_mods shift key Tab
wait_for 0.3 "Cycling on"
two_snaps "g-on"
screenshot "cyc-gestures-on"
assert_regions_differ "$A_SNAP" "$B_SNAP" "Ctrl+drag range must cycle"

info "Ctrl+R-click pauses the range"
with_mods ctrl right_click $(chip_x 3) $CHIP_Y
park_mouse
wait_for 0.3 "Paused"
two_snaps "g-paused"
assert_regions_same "$A_SNAP" "$B_SNAP" "Paused range must hold still"

info "Ctrl+R-click resumes"
with_mods ctrl right_click $(chip_x 3) $CHIP_Y
park_mouse
wait_for 0.3 "Resumed"
two_snaps "g-resumed"
assert_regions_differ "$A_SNAP" "$B_SNAP" "Resumed range must cycle again"

info "Ctrl+Wheel speeds the range up (status readout changes)"
hover $(chip_x 3) $CHIP_Y
wait_for 0.3 "hover readout"
snap_region 0 $(( VIEWPORT_H - STATUS_H )) 500 $STATUS_H "g-status-before"
ST_A="$SNAP_RESULT"
ctrl_scroll_up $(chip_x 3) $CHIP_Y
ctrl_scroll_up $(chip_x 3) $CHIP_Y
wait_for 0.3 "speed changed"
snap_region 0 $(( VIEWPORT_H - STATUS_H )) 500 $STATUS_H "g-status-after"
ST_B="$SNAP_RESULT"
assert_regions_differ "$ST_A" "$ST_B" "Ctrl+Wheel must change the range speed readout"

info "Ctrl+M-click deletes the range"
with_mods ctrl middle_click $(chip_x 3) $CHIP_Y
park_mouse
wait_for 1.0 "Deleted (wheel burst flushed too)"
two_snaps "g-deleted"
assert_regions_same "$A_SNAP" "$B_SNAP" "No range left: nothing cycles"
assert_regions_same "$ART" "$A_SNAP" "No range left: true colors"

info "Ctrl+Z restores the range"
key ctrl+z
wait_for 0.4 "Undone"
two_snaps "g-undo"
assert_regions_differ "$A_SNAP" "$B_SNAP" "Undo of delete brings the range back"
with_mods shift key Tab
wait_for 0.2 "Cycling off"

assert_no_crash
assert_window_exists
info "=== Palette Cycle Gestures Test PASSED ==="
