#!/bin/bash
# =============================================================================
# seam-text-then-switch.sh — SEAM TEST: text editing → tool switch
# Editing a text layer and then switching tools must commit the text (TEXT_reset
# → TEXT_commit), not leave a stuck editor swallowing keystrokes. After the
# switch the text must remain on the canvas and a subsequent brush stroke must
# land (proving keyboard/tool control returned to normal).
# =============================================================================

info "=== SEAM: text editing → tool switch commits text ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key grave
wait_for 0.1 "Pointer hidden"

# -- Empty baseline --
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) 80 40 "seam-text-empty"
EMPTY="$SNAP_RESULT"

# -- Activate text tool, place a caret, type --
info "Text tool: place caret and type"
key t
wait_for 0.3 "Text tool"
click $(( CANVAS_CX - 30 )) $CANVAS_CY
wait_for 0.3 "Caret placed"
type_text "ABC"
wait_for 0.4 "Typed"
assert_no_crash

# -- THE SEAM: Escape commits/exits the text edit; then switch to the brush.
#    (While editing, letter keys type into the text — so we must Escape first,
#    which is exactly the text→tool seam: it must commit and hand control back.) --
info "Escape to commit text edit, then switch to brush (B)"
key Escape
wait_for 0.4 "Text committed, edit exited"
key b
wait_for 0.4 "Brush tool active"
assert_no_crash
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 20 )) 80 40 "seam-text-committed"
COMMITTED="$SNAP_RESULT"
assert_regions_differ "$EMPTY" "$COMMITTED" "Text must remain committed on the canvas after switching tools"

# -- Control returned to normal: a brush stroke below must land --
info "Brush stroke below the text must land (no stuck text editor)"
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 12 )) 80 30 "seam-text-below-empty"
BELOW_EMPTY="$SNAP_RESULT"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY + 25 )) $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 25 ))
wait_for 0.4 "Stroke"
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 12 )) 80 30 "seam-text-below-drawn"
BELOW_DRAWN="$SNAP_RESULT"
assert_regions_differ "$BELOW_EMPTY" "$BELOW_DRAWN" "Brush stroke must land after text commit (keyboard/tool control returned)"
screenshot "seam-text-then-switch"

# -- Cleanup --
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Undo"
assert_no_crash
assert_window_exists
info "=== SEAM text-then-switch test COMPLETE ==="
