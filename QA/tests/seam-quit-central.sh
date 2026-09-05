#!/bin/bash
# =============================================================================
# seam-quit-central.sh — Phase 2A.2b: Ctrl+Q (Quit, 212) via CENTRAL DISPATCH
#
# Ctrl+Q was a DEAD binding (registered dispatched=FALSE, no legacy handler);
# migrated to dispatched=TRUE, reviving it (Alt+X stays the separate legacy path).
# With UNSAVED content on the canvas, action 212 shows the unsaved-changes dialog
# instead of quitting — a visible observable that proves Ctrl+Q dispatched. We
# then Escape/cancel so the harness's DRAW instance stays up.
# =============================================================================

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer hidden"

info "Draw content (marks the document unsaved)"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY ))
wait_for 0.3 "Content drawn (unsaved)"
assert_no_crash
park_mouse

snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "quit-before"
BEFORE="$SNAP_RESULT"

# -- Ctrl+Q with unsaved content -> unsaved-changes dialog (action 212 fired) --
info "Ctrl+Q (central dispatch) -> unsaved-changes dialog appears"
key ctrl+q
wait_for 0.6 "Unsaved-changes dialog shown"
assert_no_crash
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "quit-dialog"
DIALOG="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$DIALOG" "Ctrl+Q opened the unsaved-changes dialog (action 212 dispatched centrally)"

# -- Cancel the dialog so DRAW stays up for the harness --
info "Escape to cancel the quit dialog"
key Escape
wait_for 0.4 "Dialog dismissed"
assert_no_crash
assert_window_exists
