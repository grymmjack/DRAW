#!/bin/bash
# =============================================================================
# ui-organizer.sh — QA test: Organizer widget interaction via brush size
# Tests: ] (increase brush size), [ (decrease brush size)
# Verifies organizer brush-size widget updates visually
# =============================================================================

# -- Organizer region (below toolbar in toolbar column) --
if [[ "$TOOLBOX_DOCK" == "LEFT" ]]; then
    ORG_X=0
else
    ORG_X=$(( VIEWPORT_W - TOOLBAR_W ))
fi
ORG_Y=$(( MENU_BAR_H + TOOLBAR_H ))
ORG_W=$TOOLBAR_W
ORG_H=$ORGANIZER_H

# -- Establish known state --
info "=== UI Organizer Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"

# Increase brush size for visibility and hide pointer arrow
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap organizer region before --
park_mouse
snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "organizer-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Increase brush size: ] --
info "Increase brush size (])"
key bracketright
wait_for 0.3 "Brush size increased"
assert_no_crash

# -- Snap after increase --
park_mouse
snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "organizer-after-inc"
AFTER_INC="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER_INC" "Organizer should update after brush size increase"
screenshot "organizer-brush-inc"

# -- Decrease brush size back: [ --
info "Decrease brush size ([)"
key bracketleft
wait_for 0.3 "Brush size decreased"
assert_no_crash

# -- Snap after decrease --
park_mouse
snap_region $ORG_X $ORG_Y $ORG_W $ORG_H "organizer-after-dec"
AFTER_DEC="$SNAP_RESULT"
assert_regions_differ "$AFTER_INC" "$AFTER_DEC" "Organizer should update after brush size decrease"
screenshot "organizer-brush-dec"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== UI Organizer Test PASSED ==="
