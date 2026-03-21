#!/bin/bash
# =============================================================================
# ui-organizer.sh — QA test: Organizer widget interaction via brush size
# Tests: ] (increase brush size), [ (decrease brush size)
# Verifies organizer brush-size widget updates visually
# =============================================================================

# -- Organizer region (below toolbar in toolbar column) --
TOOLBAR_H=$(( 83 * TOOLBAR_SCALE ))
ORG_H=$(( 32 * TOOLBAR_SCALE ))
if [[ "$TOOLBOX_DOCK" == "LEFT" ]]; then
    ORG_X=0
else
    ORG_X=$(( VIEWPORT_W - TOOLBAR_W ))
fi
ORG_Y=$(( MENU_BAR_H + TOOLBAR_H ))
ORG_W=$TOOLBAR_W

# -- Establish known state --
info "=== UI Organizer Test ==="
key b
wait_for 0.3 "Switch to brush tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.3 "Focus canvas"

# -- Snap organizer region before --
BEFORE=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "organizer-before")
assert_no_crash

# -- Increase brush size: ] --
info "Increase brush size (])"
key bracketright
wait_for 0.3 "Brush size increased"
assert_no_crash

# -- Snap after increase --
AFTER_INC=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "organizer-after-inc")
assert_regions_differ "$BEFORE" "$AFTER_INC" "Organizer should update after brush size increase"
screenshot "organizer-brush-inc"

# -- Decrease brush size back: [ --
info "Decrease brush size ([)"
key bracketleft
wait_for 0.3 "Brush size decreased"
assert_no_crash

# -- Snap after decrease --
AFTER_DEC=$(snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "organizer-after-dec")
assert_regions_differ "$AFTER_INC" "$AFTER_DEC" "Organizer should update after brush size decrease"
screenshot "organizer-brush-dec"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== UI Organizer Test PASSED ==="
