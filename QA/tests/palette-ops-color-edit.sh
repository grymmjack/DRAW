#!/bin/bash
# =============================================================================
# palette-ops-color-edit.sh — QA test / regression guard
#
# Double-clicking a swatch in Palette Ops mode must open the color picker and,
# on OK, actually change that palette entry (and any canvas pixels using it).
#
# REGRESSION GUARDED (fixed 2026-08-13):
#   PALETTE_OPS_change_color read CP_STATE.result AFTER DRAW_pick_color&
#   returned. When the floating Color Mixer is open, DRAW_pick_color& re-inits
#   the mixer on close (COLORMIXER_ensure_initialized -> CP_init), which resets
#   CP_STATE.result to CP_RESULT_NONE — so the guard wrongly bailed and the edit
#   silently no-op'd. The bug therefore ONLY reproduces with the mixer OPEN,
#   which is exactly what this test sets up.
#
# The picker is driven by keyboard only (Tab -> clear hex -> type hex ->
# Enter=commit -> Enter=OK) so no fragile in-dialog pixel math is needed.
# =============================================================================

info "=== Palette Ops Color Edit Test ==="

# -- Establish known state --
canvas_focus b
wait_for 0.3 "Canvas focused, brush tool"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Organizer widget geometry (viewport px). Toolbox is right-docked in the
#    QA cfg. Column 0 holds Color Mixer (row 0) above Palette Ops (row 1).
#    Mirrors SCREEN.BM: organizer top = TB_TOP(0) + TB_ROWS*TB_BTN_H*scale +
#    (TB_ROWS-1)*TB_BTN_PADDING*scale + 1 == TOOLBAR_H + 1. The toolbar starts
#    at TB_TOP=0 (NOT below the menu bar), so do NOT add MENU_BAR_H here.
#    orgX0 = toolboxX+1; colW/rowH scale with TOOLBAR_SCALE. --
ORG_TOP=$(( TOOLBAR_H + 1 ))
ORG_COLW=$(( 11 * TOOLBAR_SCALE ))
ORG_ROW0=$(( 10 * TOOLBAR_SCALE ))
ORG_SP=$(( 1 * TOOLBAR_SCALE ))
ORG_COL0_CX=$(( TB_X + 1 + ORG_COLW / 2 ))
MIXER_BTN_Y=$(( ORG_TOP + ORG_ROW0 / 2 ))
PALOPS_BTN_Y=$(( ORG_TOP + ORG_ROW0 + ORG_SP + ORG_ROW0 / 2 ))

# -- Palette chip (row 0, index 2). swatches_start = arrow(2)+ARROW_W(12)+2 = 16;
#    each chip is CHIP_W+1 wide; row-0 centre Y == PAL_NAME_Y band. --
CHIP_W=${PALETTE_CHIP_WIDTH:-16}
CHIP_X=$(( 16 + 2 * (CHIP_W + 1) + CHIP_W / 2 ))
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))

# -- Real palette-strip band (the conservative PALETTE_H reservation is larger
#    than the ~12px strip; snap the actual strip so a one-chip recolor shows). --
STRIP_Y=$(( VIEWPORT_H - STATUS_H - 12 ))
STRIP_H=12

# -- Open the Color Mixer FIRST (its button dispatches a command, which would
#    auto-deactivate Palette Ops; do it before Palette Ops is on). This also
#    initializes the mixer, arming the regression condition. --
info "Open Color Mixer (organizer col0 row0)"
click $ORG_COL0_CX $MIXER_BTN_Y
wait_for 0.5 "Color Mixer open + initialized"
assert_no_crash

# -- Activate Palette Ops (organizer col0 row1). This is a direct call, not a
#    command, so it does not deactivate itself. --
info "Activate Palette Ops (organizer col0 row1)"
click $ORG_COL0_CX $PALOPS_BTN_Y
wait_for 0.4 "Palette Ops active"
assert_no_crash

# -- Baseline snapshot of the palette strip --
park_mouse
snap_region 0 $STRIP_Y $VIEWPORT_W $STRIP_H "palops-strip-before"
BEFORE="$SNAP_RESULT"
screenshot "palops-before-edit"
assert_no_crash

# -- Double-click chip #2 to open the picker for that color --
info "Double-click chip #2 at ($CHIP_X,$CHIP_Y)"
double_click $CHIP_X $CHIP_Y
wait_for 0.7 "Color picker modal open"
assert_no_crash

# -- Drive the modal picker by keyboard: focus hex, clear, type a distinctive
#    color, commit (Enter), then OK (Enter). --
info "Set hex to AB12CD and confirm"
key Tab
wait_for 0.15 "Hex field focused"
key BackSpace BackSpace BackSpace BackSpace BackSpace BackSpace BackSpace BackSpace
type_text "AB12CD"
wait_for 0.15 "Hex typed"
key Return
wait_for 0.15 "Hex committed"
key Return
wait_for 0.6 "Picker confirmed, edit applied"
assert_no_crash

# -- The edited swatch must now differ in the palette strip --
park_mouse
snap_region 0 $STRIP_Y $VIEWPORT_W $STRIP_H "palops-strip-after"
AFTER="$SNAP_RESULT"
screenshot "palops-after-edit"
assert_regions_differ "$BEFORE" "$AFTER" \
    "Palette Ops double-click color edit must recolor the swatch (mixer open)"

# -- Final checks --
assert_no_crash
assert_window_exists
info "=== Palette Ops Color Edit Test PASSED ==="
