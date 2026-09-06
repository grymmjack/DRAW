#!/bin/bash
# =============================================================================
# float-click-outside-deselect.sh — clicking OUTSIDE a floating selection must
# FINALIZE it and DESELECT, not re-grab a new float.
#
# TempodiBasic 2.0.3 report: after copy/paste (a float), clicking outside the
# selection then dragging re-stamped the content ("these lasts stamps on the
# pictures"), and there was no obvious way to null the selection. The MOVE tool's
# click-outside branch used to commit the float then IMMEDIATELY re-capture and
# start transforming a NEW float, so a float stayed "live" after the click and a
# subsequent drag moved/stamped it. The fix drops it (MOVE_reset + MARQUEE_clear +
# MAGIC_WAND_reset), matching the marquee tools' click-to-deselect.
#
# This uses a MOVE float, which goes through the exact same click-outside branch a
# paste float uses (the IS_PASTE difference only changes how MOVE_reset composites,
# not the re-grab-vs-drop behavior). It floats a magenta block, then does ONE drag
# gesture that STARTS OUTSIDE the float:
#   pre-fix  -> re-grabs the float and drags the content away from centre (centre changes)
#   post-fix -> drops the float, so the content stays put (centre unchanged)
# =============================================================================

info "=== Float click-outside deselect Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4 5 6 7 8; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# -- Magenta block at centre (same palette chip as selection-rotate-float) -----
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 25*17 + 8 )) "$CHIP_Y" ; wait_for 0.3 "Magenta"
for dy in -40 -24 -8 8 24 40; do
  drag $(( CANVAS_CX - 65 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + 65 )) $(( CANVAS_CY + dy ))
  wait_for 0.1 "stroke"
done
key grave
wait_for 0.1 "Pointer hidden"
park_mouse
wait_for 0.3 "Block drawn"
assert_no_crash

# -- Marquee-select a big sub-rect (leaves clear margins to click OUTSIDE) ------
key m
wait_for 0.5 "Marquee tool"
drag $(( CANVAS_CX - 55 )) $(( CANVAS_CY - 40 )) $(( CANVAS_CX + 55 )) $(( CANVAS_CY + 40 ))
wait_for 0.5 "Selection made"

# -- Float it: Move tool, bare click INSIDE the selection to grab (no move) -----
key v
wait_for 0.4 "Move tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.4 "Float grabbed"
assert_no_crash

# -- Snap the float's location (centre) BEFORE the outside gesture. The region
#    sits FULLY inside the selection, so if a re-grabbed float lifts+moves the
#    centre content the whole region changes (well past the ~same tolerance). ---
park_mouse
CEN_X=$(( CANVAS_CX - 35 )) ; CEN_Y=$(( CANVAS_CY - 25 )) ; CEN_W=70 ; CEN_H=50
snap_region "$CEN_X" "$CEN_Y" "$CEN_W" "$CEN_H" "float-center-before"
BEFORE="$SNAP_RESULT"

# -- ONE gesture: press + drag STARTING OUTSIDE the float, moving it clear of
#    the centre. Pre-fix this re-grabs and drags the centre content away (centre
#    empties); post-fix the float is dropped, so nothing moves. -----------------
drag $(( CANVAS_CX - 90 )) $(( CANVAS_CY - 70 )) $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 10 ))
wait_for 0.5 "Clicked/dragged outside the float"
assert_no_crash

park_mouse
snap_region "$CEN_X" "$CEN_Y" "$CEN_W" "$CEN_H" "float-center-after"
AFTER="$SNAP_RESULT"

# Clicking outside must drop the float (content stays), NOT re-grab and drag it.
assert_regions_same "$BEFORE" "$AFTER" \
  "Clicking outside a float must finalize+deselect it, not re-grab and drag the content"

screenshot "float-click-outside-deselect"
assert_no_crash
assert_window_exists
info "=== Float click-outside deselect Test COMPLETE ==="
