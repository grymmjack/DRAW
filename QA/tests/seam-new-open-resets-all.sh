#!/bin/bash
# =============================================================================
# seam-new-open-resets-all.sh — SEAM TEST: File>New dialog seam (open + cancel)
#
# File>New (DRW_new_canvas) resets EVERY tool/overlay/selection state from the
# previous document (CLAUDE.md gotcha #15) — but only AFTER its "New Canvas" size
# input box (DRAW_input_box_ex$) is confirmed with the OK button. That modal is a
# screen-centred dialog that this viewport-based harness cannot keyboard-complete
# (Enter does not submit it), so the full New→reset→draw path is verified by code
# inspection (see PLANS/INPUT-SEAMS-AUDIT.md §A3 + BUG-3 in BUGS-v2.0.0.md), not
# here.
#
# What this test DOES guard robustly: opening the New dialog while tool state is
# active and then CANCELLING it (Escape) must leave the app fully usable — the
# original document intact and drawing working — with no crash or stuck modal.
# =============================================================================

info "=== SEAM: File>New dialog open + cancel is non-destructive ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Draw content --
info "Draw content"
drag $(( CANVAS_CX - 25 )) $CANVAS_CY $(( CANVAS_CX + 25 )) $CANVAS_CY
wait_for 0.3 "Stroke"
park_mouse
snap_region $(( CANVAS_CX - 45 )) $(( CANVAS_CY - 20 )) 90 40 "seam-new-content"
CONTENT="$SNAP_RESULT"

# -- Build up tool state: selection + partial polygon --
info "Activate selection + start a partial polygon"
key ctrl+a
wait_for 0.4 "Select all"
key p
wait_for 0.2 "Polygon tool"
click $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 15 ))
wait_for 0.2 "Vertex 1"
click $(( CANVAS_CX + 15 )) $(( CANVAS_CY - 15 ))
wait_for 0.2 "Vertex 2 (partial polygon)"
assert_no_crash

# -- File>New opens the size dialog; CANCEL it with Escape --
info "File>New (Ctrl+N) — dialog opens; Escape cancels it"
key ctrl+n
wait_for 1.4 "New Canvas size dialog open"
key Escape
wait_for 0.8 "Dialog cancelled"
assert_no_crash

# -- Original content must be intact (New was cancelled) --
park_mouse
snap_region $(( CANVAS_CX - 45 )) $(( CANVAS_CY - 20 )) 90 40 "seam-new-after-cancel"
AFTER_CANCEL="$SNAP_RESULT"
assert_regions_same "$CONTENT" "$AFTER_CANCEL" "Cancelling File>New must leave the original document intact"

# -- App must be fully usable: switch to brush and draw; the stroke must land --
info "After cancel: switch to brush and draw — must land (no stuck modal)"
key b
wait_for 0.3 "Brush"
key grave
wait_for 0.1 "Pointer hidden"
park_mouse
snap_region $(( CANVAS_CX - 45 )) $(( CANVAS_CY + 8 )) 90 34 "seam-new-below-empty"
BELOW_EMPTY="$SNAP_RESULT"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 22 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 22 ))
wait_for 0.4 "Stroke after cancel"
park_mouse
snap_region $(( CANVAS_CX - 45 )) $(( CANVAS_CY + 8 )) 90 34 "seam-new-below-drawn"
BELOW_DRAWN="$SNAP_RESULT"
assert_regions_differ "$BELOW_EMPTY" "$BELOW_DRAWN" "Drawing must work after cancelling the New dialog (no stuck modal)"
screenshot "seam-new-cancel"

assert_no_crash
assert_window_exists
info "=== SEAM new-dialog-cancel test COMPLETE ==="
