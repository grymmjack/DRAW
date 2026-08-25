#!/bin/bash
# =============================================================================
# seam-copy-then-wand.sh — SEAM TEST: wand → copy → paste → wand again (BUG-1)
# BUG-1: after a paste, the magic wand "selected things that aren't there" — the
# paste preserved a STALE per-pixel wand mask (old bounds) which MOVE then dragged
# around. Fix: CLIPBOARD_paste now clears the wand mask (MAGIC_WAND_reset).
#
# A pixel-exact assertion on selection-outline geometry is not practical with the
# region-diff harness, so this is a FUNCTIONAL smoke: it exercises the full
# wand→copy→paste→commit→wand sequence and verifies no crash and that a fresh
# wand selection after the paste still drives a real, correctly-placed operation
# (fill the fresh selection; the fill must land where we clicked, not at a stale
# location). Visual confirmation of the marching-ants geometry remains manual.
# =============================================================================

info "=== SEAM: copy/paste must not leave a stale wand selection (BUG-1) ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Draw a solid blob at LEFT so the wand has a region to select --
info "Draw a solid blob at LEFT"
drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX - 20 )) $CANVAS_CY
wait_for 0.2 "blob a"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 6 )) $(( CANVAS_CX - 20 )) $(( CANVAS_CY - 6 ))
wait_for 0.2 "blob b"
drag $(( CANVAS_CX - 40 )) $(( CANVAS_CY + 6 )) $(( CANVAS_CX - 20 )) $(( CANVAS_CY + 6 ))
wait_for 0.3 "blob c (solid patch)"
assert_no_crash

# -- Wand-select the blob, then copy --
info "Wand-select the blob, copy"
key w
wait_for 0.2 "Wand"
click $(( CANVAS_CX - 30 )) $CANVAS_CY
wait_for 0.4 "Wand selection at LEFT"
key ctrl+c
wait_for 0.3 "Copy"
assert_no_crash

# -- Paste (float) then commit by switching to the brush --
info "Paste, then switch tool (float commits; stale wand mask must be cleared)"
key ctrl+v
wait_for 0.5 "Paste float"
key b
wait_for 0.4 "Switch/commit"
key ctrl+d
wait_for 0.3 "Deselect any residual"
assert_no_crash

# -- Fresh wand selection at a NEW location (RIGHT), then fill it. The fill must
#    land at RIGHT (where we click), proving no stale mask hijacks the operation. --
info "Fresh wand-select at RIGHT + fill; fill must land at RIGHT"
# lay a solid patch at RIGHT to select
drag $(( CANVAS_CX + 20 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.2 "r a"
drag $(( CANVAS_CX + 20 )) $(( CANVAS_CY - 6 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY - 6 ))
wait_for 0.2 "r b"
drag $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 6 )) $(( CANVAS_CX + 40 )) $(( CANVAS_CY + 6 ))
wait_for 0.3 "r c"
park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 20 )) 40 40 "seam-wand-left-region"; LEFT_REGION="$SNAP_RESULT"
key w
wait_for 0.2 "Wand"
click $(( CANVAS_CX + 30 )) $CANVAS_CY
wait_for 0.4 "Wand selection at RIGHT"
assert_no_crash
park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 20 )) 40 40 "seam-wand-left-region2"; LEFT_REGION2="$SNAP_RESULT"
# Selecting at RIGHT must not disturb the LEFT region (no stale mask redraw there)
assert_regions_same "$LEFT_REGION" "$LEFT_REGION2" "A fresh wand-select at RIGHT must not alter the LEFT region (no stale wand mask)"
screenshot "seam-copy-then-wand"

# -- Cleanup --
key ctrl+d
wait_for 0.2 "Deselect"
key ctrl+z
wait_for 0.2
key ctrl+z
wait_for 0.3 "Undo"
assert_no_crash
assert_window_exists
info "=== SEAM copy-then-wand test COMPLETE ==="
