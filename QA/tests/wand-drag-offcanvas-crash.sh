#!/bin/bash
# QA-OPTIONS: DEVELOPER_MODE=TRUE
# =============================================================================
# wand-drag-offcanvas-crash.sh — the UNDERLYING #300 the forum crash exposed.
#
# The forum's exact path (wand → copy → paste → drag) is already closed in 2.x:
# CLIPBOARD_paste calls MAGIC_WAND_reset, so a pasted float carries no wand mask.
# But the ROOT defect it exposed is still present: MOVE translates
# MARQUEE.WAND_MIN/MAX by the drag delta unclamped (MOVE.BM ~1077), and
# MAGIC_WAND_build_edge_cache scans those bounds against the canvas-sized
# SELECTION_MASK unclamped (MARQUEE.BM ~2059). So dragging a plain WAND selection
# off-canvas drives the _MEMGET offset out of the _MEM region → ERR 300.
#
# This test makes a real wand selection and drags it off the top-left corner with
# the Move tool, asserting NO CRASH. Before the clamp fix it dies mid-drag.
# =============================================================================

info "=== Wand selection dragged off-canvas must not crash (#300 root) ==="

# Capture is automatic: the harness snapshots DRAW's crash-log dir AND greps its
# captured console output for runtime-error text (assert_no_crash_log). This #300
# recurs inside the render loop and never flushes a crash-report FILE, so the
# console grep is what actually catches it. DEVELOPER_MODE=TRUE (QA-OPTIONS above)
# makes the crash notice a non-blocking banner — never a modal that could hang.

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Draw a solid blob at center for the wand to select. --
info "Draw a solid blob at center"
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.2 "blob a"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 6 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 6 ))
wait_for 0.2 "blob b"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 6 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 6 ))
wait_for 0.3 "blob c (solid patch)"
assert_no_crash

# -- Wand-select the blob. --
info "Wand-select the blob"
key w
wait_for 0.2 "Wand mode"
click $CANVAS_CX $CANVAS_CY
wait_for 0.4 "Wand selection"
assert_no_crash

# -- Move tool, then drag the selection FAR off the top-left corner. This is the
#    #300 trigger: WAND_MIN/MAX go negative, edge-cache scans out-of-range mask. --
info "Move-drag the wand selection off the top-left corner (the #300 trigger)"
key v
wait_for 0.3 "Move tool"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 120 ))
wait_for 0.6 "Dragged wand selection off-canvas"
assert_no_crash

# -- Exercise negative + over-max on each axis with a couple more edge drags. --
drag $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 120 )) $(( CANVAS_CX + 140 )) $(( CANVAS_CY - 120 ))
wait_for 0.4 "top / over-max X"
assert_no_crash
drag $(( CANVAS_CX + 140 )) $(( CANVAS_CY - 120 )) $(( CANVAS_CX + 140 )) $(( CANVAS_CY + 140 ))
wait_for 0.4 "over-max Y"
assert_no_crash

screenshot "wand-drag-offcanvas"

# -- Cleanup. --
key Escape
wait_for 0.3 "Cancel move"
key ctrl+d
wait_for 0.2 "Deselect"
assert_no_crash
assert_window_exists
# The decisive assertion is automatic: the harness's assert_no_crash_log greps
# DRAW's captured console output for "Memory region out of range" (the #300) after
# this test — so a regression fails the run without anything more here.
info "=== wand drag off-canvas crash test COMPLETE ==="
