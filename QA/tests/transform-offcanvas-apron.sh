#!/bin/bash
# QA-OPTIONS: DEVELOPER_MODE=TRUE
# =============================================================================
# transform-offcanvas-apron.sh — BUG-12: a transform whose result overflows the
# canvas must grow an apron (preserve the off-canvas pixels) like Move, instead
# of clipping — and must NOT crash while doing it.
#
# The visual "did the off-canvas part survive" check is a manual/judge call
# (confirmed by Rick). This is the stability guard: drive a transform-scale that
# pushes content past the edge, commit, then move the layer — asserting no crash.
# The harness's console trap (assert_no_crash_log) catches any runtime error in
# the new promote/offset commit path (a #300 in the apron blit, etc.).
# =============================================================================

info "=== BUG-12: transform overflow grows an apron without crashing ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Draw an asymmetric mark near center so a scale-up pushes corners off-canvas. --
info "Draw an asymmetric mark near center"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 30 )) $(( CANVAS_CY - 20 ))
wait_for 0.2 "top bar"
drag $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX - 30 )) $(( CANVAS_CY + 20 ))
wait_for 0.3 "left edge"
assert_no_crash

# -- Enter Transform ▸ Scale via the command palette (no hotkey; see transform-overlay.sh). --
info "Enter Transform (Scale) via command palette"
key question
wait_for 0.5 "Command palette open"
type_text "transform scale"
wait_for 0.3 "Query typed"
key Return
wait_for 1.0 "Transform overlay active"
assert_no_crash

# -- Drag a corner handle far outward so the scaled result overflows the canvas
#    on multiple edges (this is what promotes the apron on commit). --
info "Scale a corner past the canvas edges (apron-overflow)"
drag $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 20 )) $(( CANVAS_CX + 140 )) $(( CANVAS_CY + 130 ))
wait_for 0.5 "Scaled past the edge"
assert_no_crash

# -- Commit (Enter). This is the promote + apron-offset blit path. --
info "Commit the transform (Enter)"
key Return
wait_for 0.6 "Committed"
assert_no_crash

# -- Move the layer so the off-canvas overflow would come back on-canvas. --
info "Move the layer to exercise the freshly-grown apron"
key v
wait_for 0.3 "Move tool"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 ))
wait_for 0.5 "Moved"
assert_no_crash

screenshot "transform-offcanvas-apron"

key Escape
wait_for 0.2 "Settle"
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Undo"
assert_no_crash
assert_window_exists
info "=== BUG-12 transform-offcanvas apron test COMPLETE ==="
