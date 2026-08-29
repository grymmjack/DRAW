#!/bin/bash
# =============================================================================
# wand-paste-drag-offcanvas-crash.sh — forum-reported crash:
#   Magic Wand select → Copy → Paste → drag the floating selection → CRASH
#   "Critical Error #300 — Line 2062 (in MARQUEE.BM) — Memory region out of range"
#   (reported on DRAW 1.1, Kubuntu 24.04; reproduces in 2.x by code inspection).
#
# Root cause: MOVE translates the wand bounds (MARQUEE.WAND_MIN/MAX_X/Y) by the
# drag delta with NO clamp (MOVE.BM ~1077), and MAGIC_WAND_build_edge_cache scans
# those bounds against the canvas-sized SELECTION_MASK with NO clamp
# (MARQUEE.BM ~2059). Drag a pasted wand selection off-canvas → the _MEMGET
# offset (y*stride + x*4) lands outside the _MEM region → ERR 300.
#
# This test reproduces the exact chain and asserts NO CRASH. Before the fix it
# fails (the app dies mid-drag); after the clamp it passes.
# =============================================================================

info "=== Forum crash: wand → copy → paste → drag off-canvas must not crash (#300) ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Draw a solid blob at center so the wand has a region to select. --
info "Draw a solid blob at center"
drag $(( CANVAS_CX - 20 )) $CANVAS_CY $(( CANVAS_CX + 20 )) $CANVAS_CY
wait_for 0.2 "blob a"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 6 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 6 ))
wait_for 0.2 "blob b"
drag $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 6 )) $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 6 ))
wait_for 0.3 "blob c (solid patch)"
assert_no_crash

# -- Wand-select the blob, then copy. --
info "Wand-select the blob, copy"
key w
wait_for 0.2 "Wand mode"
click $CANVAS_CX $CANVAS_CY
wait_for 0.4 "Wand selection"
key ctrl+c
wait_for 0.3 "Copy"
assert_no_crash

# -- Paste: creates a floating selection carrying the wand mask + bounds. --
info "Paste (float)"
key ctrl+v
wait_for 0.5 "Paste float"
assert_no_crash

# -- Drag the float FAR off the top-left corner. This translates WAND_MIN/MAX
#    negative; the marching-ants edge cache then scans out-of-range mask memory.
#    A single big drag (past the edge in both axes) is the #300 trigger. --
info "Drag the pasted float off the top-left corner (the crash trigger)"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 120 ))
wait_for 0.6 "Dragged float off-canvas"
assert_no_crash

# -- A couple more drags along the edges to exercise negative + over-max bounds. --
info "Nudge it further along the edges"
drag $(( CANVAS_CX - 120 )) $(( CANVAS_CY - 120 )) $(( CANVAS_CX + 140 )) $(( CANVAS_CY - 120 ))
wait_for 0.4 "top edge"
assert_no_crash
drag $(( CANVAS_CX + 140 )) $(( CANVAS_CY - 120 )) $(( CANVAS_CX + 140 )) $(( CANVAS_CY + 140 ))
wait_for 0.4 "right/bottom edge"
assert_no_crash

screenshot "wand-paste-drag-offcanvas"

# -- Settle / cleanup. --
key Escape
wait_for 0.3 "Cancel float"
key ctrl+d
wait_for 0.2 "Deselect"
assert_no_crash
assert_window_exists
info "=== wand paste-drag off-canvas crash test COMPLETE ==="
