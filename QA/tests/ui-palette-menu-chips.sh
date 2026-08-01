#!/bin/bash
# =============================================================================
# ui-palette-menu-chips.sh — QA test: color chips in the palette dropdown menu
# Tests: click the palette name to open the dropdown, verify per-palette color
#        chips render beside the names, Escape closes it.
#
# Chips are drawn inline right of each name (4x4px, 32 per chip row, 64 max)
# when CFG.PALETTE_MENU_SHOW_CHIPS is on — see PALETTE_MENU_draw_chips in
# GUI/PALETTE-STRIP.BM. Colors come from the lazily-parsed PALETTE_PREVIEW_*
# cache in GUI/PALETTE-LOADER.BM, budgeted to 8 .GPL files per frame, so the
# menu needs a moment to fill in every row.
# =============================================================================

info "=== Palette Menu Chips Test ==="

# -- Establish known state --
canvas_focus b
wait_for 0.3 "Canvas focused, brush tool"
key grave
wait_for 0.1 "Pointer arrow hidden"

# The dropdown opens above the palette strip and is right-aligned.
# Menu width with chips = 180 name + 4 gap + 32*4 chips + 76 "...and N more".
MENU_REGION_W=400
MENU_REGION_X=$(( VP_W - MENU_REGION_W ))
MENU_REGION_Y=$WORK_TOP
MENU_REGION_H=$(( PAL_Y - WORK_TOP ))

# Chips occupy the right-hand column of each row: name col (180) + gap (4).
# Menu is right-aligned at VP_W - W - 4, so the chip column starts here.
CHIP_COL_X=$(( VP_W - 208 ))
CHIP_COL_W=128

# -- Baseline: dropdown closed --
park_mouse
snap_region $MENU_REGION_X $MENU_REGION_Y $MENU_REGION_W $MENU_REGION_H "palmenu-closed"
CLOSED="$SNAP_RESULT"
snap_region $CHIP_COL_X $MENU_REGION_Y $CHIP_COL_W $MENU_REGION_H "palmenu-chipcol-closed"
CHIP_COL_CLOSED="$SNAP_RESULT"
CHIP_COLORS_CLOSED=$(magick "$CHIP_COL_CLOSED" -format %k info: 2>/dev/null)
info "  [chips] unique colors in chip column while CLOSED: ${CHIP_COLORS_CLOSED:-?}"
assert_no_crash

# -- Open the dropdown by clicking the palette name on the right of the strip --
info "Open palette dropdown (click palette name at $PAL_NAME_X,$PAL_NAME_Y)"
click $PAL_NAME_X $PAL_NAME_Y
wait_for 1.0 "Dropdown open, chip cache filling (8 .GPL parses per frame)"
assert_no_crash

# -- Do NOT park_mouse: moving off the menu changes hover/closes it --
snap_region $MENU_REGION_X $MENU_REGION_Y $MENU_REGION_W $MENU_REGION_H "palmenu-open"
MENU_OPEN="$SNAP_RESULT"
assert_regions_differ "$CLOSED" "$MENU_OPEN" "Palette dropdown should be visible"
screenshot "palette-menu-chips"

# -- The chip column is where the chips live; it must both change when the
#    menu opens AND be far more colorful than a name-only list would be
#    (name-only = background + border + separator + 2 text colors).
snap_region $CHIP_COL_X $MENU_REGION_Y $CHIP_COL_W $MENU_REGION_H "palmenu-chipcol-open"
CHIP_COL_OPEN="$SNAP_RESULT"
assert_regions_differ "$CHIP_COL_CLOSED" "$CHIP_COL_OPEN" \
    "Chip column should be covered by the open dropdown"

CHIP_COLORS_OPEN=$(magick "$CHIP_COL_OPEN" -format %k info: 2>/dev/null)
info "  [chips] unique colors in chip column while OPEN: ${CHIP_COLORS_OPEN:-?}"
if [[ "${CHIP_COLORS_OPEN:-0}" -gt 16 ]] 2>/dev/null; then
    pass "chip column renders palette colors (${CHIP_COLORS_OPEN} unique colors)"
else
    fail "chip column looks name-only (${CHIP_COLORS_OPEN:-?} unique colors, expected >16)"
fi

# -- Close the dropdown --
info "Close palette dropdown (Escape)"
key Escape
wait_for 0.4 "Dropdown closed"
assert_no_crash

park_mouse
snap_region $MENU_REGION_X $MENU_REGION_Y $MENU_REGION_W $MENU_REGION_H "palmenu-reclosed"
RECLOSED="$SNAP_RESULT"
assert_regions_differ "$MENU_OPEN" "$RECLOSED" "Dropdown should disappear after Escape"

assert_no_crash
assert_window_exists
info "=== Palette Menu Chips Test PASSED ==="
