#!/bin/bash
# =============================================================================
# seam-eraser-reaches-all.sh — SEAM TEST: transform → eraser (BUG-2 companion)
# The user's report: "things on the doc I could not erase until I loaded again."
# Root cause = orphaned TRANSFORM overlay (BUG-2). This test proves the eraser
# can remove content after the transform→eraser seam: enter transform, switch to
# the eraser (which — with the BUG-2 fix — commits the transform), then erase.
# The erase must actually change pixels (i.e. the content is on a real layer and
# reachable), not be blocked by a stuck overlay / hijacked mouse.
# =============================================================================

info "=== SEAM: eraser reaches content after transform→eraser switch ==="

canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer hidden"

# -- Draw solid content to erase --
info "Drawing content"
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.3 "Horizontal stroke"
drag $CANVAS_CX $(( CANVAS_CY - 18 )) $CANVAS_CX $(( CANVAS_CY + 18 ))
wait_for 0.3 "Vertical stroke (plus shape)"
assert_no_crash

# -- Select all + enter transform overlay --
key ctrl+a
wait_for 0.6 "Select all"
key question
wait_for 0.4 "Palette opened"
type_text "transform scale"
wait_for 0.3 "Filter"
key Return
wait_for 1.0 "Transform overlay active"
assert_no_crash

# -- THE SEAM: switch to the eraser while transform is active --
info "Switching to eraser (E) while transform overlay is active"
key e
wait_for 0.6 "Eraser active (transform should have committed)"
assert_no_crash

# -- Snap BEFORE erasing (content present; any selection ants are constant) --
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 30 )) 80 60 "seam-eraser-before"
BEFORE="$SNAP_RESULT"

# -- Erase across the content --
info "Erasing across the content"
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.3 "Erase stroke 1"
drag $CANVAS_CX $(( CANVAS_CY - 18 )) $CANVAS_CX $(( CANVAS_CY + 18 ))
wait_for 0.3 "Erase stroke 2"
assert_no_crash

# -- Snap AFTER erasing --
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 30 )) 80 60 "seam-eraser-after"
AFTER="$SNAP_RESULT"

# The eraser MUST have changed the content (removed pixels). If the transform
# overlay were still orphaned (pre-fix), the mouse would drive transform handles
# and the content would be untouched → regions identical → FAIL.
assert_regions_differ "$BEFORE" "$AFTER" "Eraser must remove content after a transform→eraser switch (BUG-2: was un-erasable until reload)"
screenshot "seam-eraser-after"

# -- Cleanup --
key Escape
wait_for 0.2 "Cancel"
key ctrl+d
wait_for 0.2 "Deselect"
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Undo"
assert_no_crash
assert_window_exists
info "=== SEAM eraser-reaches-all test COMPLETE ==="
