#!/bin/bash
# =============================================================================
# effect-dropdown-wheel.sh — QA test / regression guard
#
# The shared dialog DROPDOWN must SCROLL with the mouse wheel while open (fixed
# 2026-08-16). The bug: DIALOG_dropdown_input auto-scrolled the highlighted
# (selected) row into view EVERY frame, so a wheel scroll was undone on the very
# next frame — the list snapped back so the selected item (under the pointer)
# stayed visible and you could never scroll away from it. Now the auto-follow
# only runs on an arrow-key move, leaving the wheel free.
#
# Posterize's dither dropdown has 23 items (> the 8 visible), so it scrolls. We
# open it, snapshot a strip of the OPEN list, wheel DOWN a few times over the
# list, and snapshot the same strip: with the fix the list scrolled so the strip
# shows different labels (differ); with the bug it snaps back (identical).
#
# Posterize opened via the command palette; dither dropdown box ~ (478,311).
# =============================================================================

info "=== Dropdown Mouse-Wheel Scroll Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6; do key bracketright; done
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 5*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "A colour"
drag $(( CANVAS_CX - 60 )) "$CANVAS_CY" $(( CANVAS_CX + 60 )) "$CANVAS_CY"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Open Posterize and its dither dropdown.
key question ; wait_for 0.5 "Command palette"
type_text "Posterize" ; wait_for 0.5 "Filtered"
key Return ; wait_for 0.7 "Posterize dialog open"
click 478 311 ; wait_for 0.4 "Dither dropdown open"
screenshot "dd-wheel-open"

# Snapshot a strip across the top rows of the OPEN list.
LX=380; LY=330; LW=180; LH=54
park_mouse
snap_region "$LX" "$LY" "$LW" "$LH" "dd-wheel-before"
BEFORE="$SNAP_RESULT"

# Wheel down over the list — should scroll it (not snap back to the selection).
scroll_down 470 362
scroll_down 470 362
scroll_down 470 362
scroll_down 470 362
wait_for 0.3 "Wheeled the list down"
screenshot "dd-wheel-scrolled"

park_mouse
snap_region "$LX" "$LY" "$LW" "$LH" "dd-wheel-after"
AFTER="$SNAP_RESULT"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Mouse wheel must scroll the open dropdown list (must not snap back to the selection)"
assert_no_crash
assert_window_exists
info "=== Dropdown Mouse-Wheel Scroll Test PASSED ==="
