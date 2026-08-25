#!/bin/bash
# =============================================================================
# seam-transform-then.sh — SEAM TEST: TRANSFORM overlay → tool switch
# Reproduces BUG-2 (BUGS-v2.0.0.md): the TRANSFORM overlay is orphaned by an
# ordinary tool switch. TOOLS_reset_all (GUI/GUI.BM:22) never calls
# TRANSFORM_commit/_cancel, so switching tools while TRANSFORM.ACTIVE leaves the
# overlay live — it keeps baking onto the canvas and cannot be erased until the
# file is reloaded ("things on the doc I could not erase until I loaded again").
#
# EXPECTED (fixed): switching tools dismisses the transform overlay (commit or
# cancel) → the canvas returns to the pre-transform content (no orphaned handles).
# CURRENT (buggy): the overlay handles/tint persist after the switch → the
# after-switch region still differs from the pre-transform region → this test
# FAILS (RED) until BUG-2 is fixed.
# =============================================================================

info "=== SEAM: Transform → tool switch (BUG-2 orphaned overlay) ==="

# -- Establish known state: brush, big size, pointer hidden --
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw a distinct L-shape to transform --
info "Drawing L-shape content"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 15 ))
wait_for 0.3 "Top line"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 15 )) $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 15 ))
wait_for 0.3 "Left line (L-shape)"
assert_no_crash

# -- Snap BEFORE transform (content only, no overlay) --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "seam-xform-before"
BEFORE="$SNAP_RESULT"

# -- Select all + enter transform mode via command palette --
info "Select all (Ctrl+A) then enter transform"
key ctrl+a
wait_for 0.6 "Selection made"
key question
wait_for 0.4 "Palette opened"
type_text "transform scale"
wait_for 0.3 "Filter applied"
key Return
wait_for 1.0 "Transform overlay active"
assert_no_crash

# -- Sanity: the overlay must be visible (handles/tint differ from BEFORE) --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "seam-xform-active"
ACTIVE="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$ACTIVE" "Transform overlay must be visible (setup sanity)"

# -- THE SEAM: switch to the brush WITHOUT committing the transform (press B) --
info "Switching tool (B) while transform overlay is active — the seam"
key b
wait_for 0.8 "Tool switched to brush"
assert_no_crash

# -- Snap AFTER the switch --
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "seam-xform-after-switch"
AFTER="$SNAP_RESULT"

# -- ASSERTION: switching tools must DISMISS the transform overlay, so the
#    after-switch region must DIFFER from the active-overlay region (handles/tint
#    gone). RED until BUG-2 fixed: currently the overlay persists unchanged
#    (AFTER == ACTIVE), so regions are identical and this fails.
#    (We compare ACTIVE vs AFTER, not BEFORE vs AFTER, because the Ctrl+A marquee
#    is preserved across the switch and would otherwise mask the result.) --
assert_regions_differ "$ACTIVE" "$AFTER" "Switching tools must dismiss the TRANSFORM overlay (BUG-2: orphaned overlay is un-erasable until reload)"
screenshot "seam-xform-after-switch"

# -- Cleanup: cancel any lingering transform, deselect, undo the strokes --
key Escape
wait_for 0.3 "Cancel any transform"
key ctrl+d
wait_for 0.2 "Deselect"
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Undo strokes"
assert_no_crash
assert_window_exists
info "=== SEAM Transform → switch test COMPLETE ==="
