#!/bin/bash
# =============================================================================
# edit-stroke-selection.sh — QA test: Stroke selection outline
# Tests: Select All → stroke selection draws outline on canvas
# =============================================================================

info "=== Stroke Selection Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw a filled area to have clear selection context --
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 15 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 10 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 5 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 5 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $CANVAS_CY $(( CANVAS_CX + 15 )) $CANVAS_CY
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY + 5 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 5 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY + 10 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 10 ))
wait_for 0.2
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY + 15 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 15 ))
wait_for 0.3 "Filled area drawn"
assert_no_crash

# -- Make a DEFINED marquee rectangle in the centre (NOT a whole-canvas Ctrl+A).
#    The stroke dialog defaults to TYPE=OUTSIDE, so a whole-canvas selection would
#    stroke OUTSIDE the canvas (invisible); a defined interior rectangle strokes a
#    clearly on-canvas outline we can capture. --
info "Select a defined rectangle with the Marquee tool"
key Escape
wait_for 0.2 "Clear any active state"
canvas_focus m
wait_for 0.3 "Marquee tool"
key grave
drag $(( CANVAS_CX - 45 )) $(( CANVAS_CY - 32 )) $(( CANVAS_CX + 45 )) $(( CANVAS_CY + 32 ))
wait_for 0.4 "Marquee selection made"
assert_no_crash

# -- Snap before stroke selection (the centre region that the outline will cross) --
park_mouse
STROKE_X=$(( CANVAS_CX - 60 )); STROKE_Y=$(( CANVAS_CY - 45 )); STROKE_W=120; STROKE_H=90
snap_region "$STROKE_X" "$STROKE_Y" "$STROKE_W" "$STROKE_H" "stroke-sel-before"
BEFORE="$SNAP_RESULT"

# -- Apply stroke selection via Command Palette, then in the STROKE SELECTION
#    dialog set TYPE=ON (draw on the selection edge, on-canvas) and bump the WIDTH
#    for a clear line, then OK. Dialog buttons (viewport): ON @ (480,261),
#    WIDTH + @ (507,302), OK @ (414,337). --
info "Opening Command Palette and invoking Stroke Selection"
key shift+slash
wait_for 0.5 "Command palette opened"
type_text "Stroke Selection"
wait_for 0.5 "Typed stroke"
key Return
wait_for 1.0 "Stroke dialog opened"
click 480 261
wait_for 0.2 "TYPE = ON"
click 507 302
wait_for 0.1 "Width +"
click 507 302
wait_for 0.1 "Width +"
click 507 302
wait_for 0.2 "Width bumped"
click 414 337
wait_for 1.0 "Stroke selection applied (OK)"
assert_no_crash

park_mouse
snap_region "$STROKE_X" "$STROKE_Y" "$STROKE_W" "$STROKE_H" "stroke-sel-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Stroke selection should draw outline on canvas"
screenshot "after-stroke-selection"

# -- Undo stroke and deselect --
info "Undoing stroke selection (Ctrl+Z)"
wake_draw
key ctrl+z
wait_for 0.5 "Stroke undone"
key Escape
wait_for 0.2 "Deselect"
assert_no_crash

# -- Cleanup undo history --
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Cleanup"
assert_no_crash

assert_window_exists
info "=== Stroke Selection Test PASSED ==="
