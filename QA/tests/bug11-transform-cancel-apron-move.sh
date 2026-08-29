#!/bin/bash
# =============================================================================
# bug11-transform-cancel-apron-move.sh — BUG-11: a transform cancel must not
# cause the subsequent whole-layer move-back to clip off-canvas (apron) content.
#
# Repro chain that shipped broken:
#   1. Whole-layer move pushes part of the content past the canvas edge, so it
#      lives in the layer's apron buffer (off-canvas, preserved).
#   2. Enter an on-canvas Transform, then ESC (cancel). The transform-cancel
#      restores the layer pixels correctly BUT drops the marquee that the move
#      left active.
#   3. Move the layer back. With the marquee gone, this is a WHOLE-LAYER move —
#      which used to lift only the CANVAS region, shearing off the apron content.
#      The part that had been pushed off-canvas never came back = clipped.
#
# Fix: a whole-layer move of an already apron-extended layer lifts the FULL
# extended buffer, so off-canvas content moves back intact.
#
# NOTE: the Transform step is essential to the repro — it clears the marquee so
# the move-back takes the whole-layer path. A plain move-off/back keeps the
# marquee active (a selection move) and never hit the bug.
#
# SCOPE OF THIS TEST: a *stability + survival* regression guard for the exact
# user-reported chain — it asserts the sequence never crashes and that content
# survives it (isn't wiped). It intentionally does NOT pixel-compare positions:
# a two-drag net-zero move at the QA canvas's 2x zoom doesn't land on the exact
# origin pixel, and that positional jitter is larger than a clip's footprint, so
# an exact-position compare would be both flaky AND unable to distinguish jitter
# from a clip. The precise "apron content is byte-for-byte preserved" proof for
# BUG-11 was done by dumping the layer buffer before demote / after rollback
# (identical) and confirmed manually by Rick — see BUGS-v2.0.0.md BUG-11.
# =============================================================================

info "=== BUG-11: transform-cancel must not clip apron content on move-back ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

# -- Blank baseline of the content region BEFORE any drawing (grid only). --
park_mouse
snap_region $(( CANVAS_CX - 75 )) $(( CANVAS_CY - 35 )) 150 70 "bug11-blank"
BLANK="$SNAP_RESULT"

# -- Draw an asymmetric mark whose RIGHT end is distinctive. --
info "Draw an asymmetric mark (horizontal bar + a tick on its right end)"
drag $(( CANVAS_CX - 50 )) $CANVAS_CY $(( CANVAS_CX + 50 )) $CANVAS_CY
wait_for 0.3 "Horizontal bar"
drag $(( CANVAS_CX + 50 )) $(( CANVAS_CY - 22 )) $(( CANVAS_CX + 50 )) $(( CANVAS_CY + 22 ))
wait_for 0.3 "Right-end tick"
assert_no_crash

# -- Whole-layer move RIGHT past the edge (no Ctrl+A → captureWholeLayer path;
#    the right portion is pushed into the apron / off-canvas). --
info "Whole-layer move right past the edge (promotes apron, pushes right end off-canvas)"
key v
wait_for 0.3 "Move tool"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 120 )) $CANVAS_CY
wait_for 0.5 "Moved right past the edge"
assert_no_crash

# -- Enter on-canvas Transform (Scale) via the command palette, then cancel.
#    Transform has no hotkey — invoke via palette (see transform-overlay.sh).
#    The ESC cancel is where the marquee gets dropped. --
info "Enter Transform (Scale) via command palette, then ESC to cancel"
key question
wait_for 0.5 "Command palette open"
type_text "transform scale"
wait_for 0.3 "Query typed"
key Return
wait_for 1.0 "Transform overlay active"
assert_no_crash
key Escape
wait_for 0.5 "Transform cancelled"
assert_no_crash

# -- Whole-layer move BACK LEFT by the same amount (net-zero). With the marquee
#    dropped by the transform, this is the whole-layer path — the one that used
#    to clip the apron content. --
info "Whole-layer move back left (net-zero) — must recover the off-canvas content"
key v
wait_for 0.3 "Move tool"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX - 120 )) $CANVAS_CY
wait_for 0.5 "Moved back to origin"
assert_no_crash

# -- Commit / settle, then snap the same region. --
key b
wait_for 0.3 "Brush (commit move)"
key ctrl+d
wait_for 0.2 "Deselect"
key grave
wait_for 0.1 "Pointer hidden"
park_mouse
snap_region $(( CANVAS_CX - 75 )) $(( CANVAS_CY - 35 )) 150 70 "bug11-after-roundtrip"
AFTER="$SNAP_RESULT"

# Survival check: after move-off → transform-cancel → move-back, content must
# still be on the canvas. In the bug's worst case the whole-layer move-back
# sheared the apron content clean off; a crash (#300 / apron _MEM) was also on
# the table. This asserts the sequence is stable and content survived. The
# screenshot is saved for manual clip inspection; the precise byte-for-byte
# apron-preservation proof is in the buffer PNG dumps (see BUGS-v2.0.0.md).
assert_regions_differ "$BLANK" "$AFTER" "Content must survive move-off → transform-cancel → move-back (BUG-11)"
screenshot "bug11-transform-cancel-apron-move"

assert_no_crash
assert_window_exists
info "=== BUG-11 transform-cancel apron-move test COMPLETE ==="
