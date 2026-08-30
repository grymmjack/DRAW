#!/bin/bash
# =============================================================================
# phantom-undo-noop.sh — QA: no-op operations must NOT push an undo state.
#
# The audit (undo system) found many sites that recorded an undo even when the
# operation changed nothing on the canvas. A phantom undo is invisible: pressing
# Ctrl+Z appears to "do nothing", forcing extra presses.
#
# Deterministic GUI signal, no internal hooks needed: after a REAL op followed by
# an identical NO-OP op, a SINGLE Ctrl+Z must reverse the REAL op. If the no-op
# recorded a phantom, that first Ctrl+Z reverses the phantom (no visible change)
# and the real op stays on screen — which these region-diffs catch.
#
# Covers behaviorally: F1 (Fill), F2 (Clear), F11 (Flip). The dialog/mode-driven
# findings (F3-F6, F10, F12) are covered by phantom-undo-guards.sh (source guards)
# since they can't be driven reliably headless.
# =============================================================================

info "=== Phantom-undo: no-op ops must not push an undo ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key grave
wait_for 0.1 "Pointer hidden"

# -- Baseline blank region --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "pu-blank"
BLANK="$SNAP_RESULT"

# =============================================================================
# F1 — Flood Fill: filling a pixel already the fill color paints nothing.
# =============================================================================
info "F1: fill (real) then fill same spot (no-op) → 1 undo reverses the real fill"
key f
wait_for 0.3 "Fill tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "First fill (real)"
assert_no_crash
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "pu-fill1"
FILL1="$SNAP_RESULT"
assert_regions_differ "$BLANK" "$FILL1" "first fill should change the canvas"

# Fill the SAME spot again — already that color, so a no-op.
click $CANVAS_CX $CANVAS_CY
wait_for 0.4 "Second fill (no-op)"
assert_no_crash

# ONE undo must reverse the real fill → back to blank. If the no-op fill recorded a
# phantom, this undo reverses that instead and the canvas stays filled.
key ctrl+z
wait_for 0.4 "Undo"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "pu-fill-undo"
FILL_UNDO="$SNAP_RESULT"
assert_regions_same "$BLANK" "$FILL_UNDO" "one undo must reverse the real fill (no phantom from the no-op fill)"
screenshot "phantom-undo-fill"

# =============================================================================
# F2 — Clear (Delete): clearing an already-empty layer clears nothing.
# =============================================================================
info "F2: fill, clear (real), clear again (no-op) → 1 undo restores the fill"
key f
wait_for 0.2 "Fill tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Fill for clear test (real)"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "pu-fill2"
FILL2="$SNAP_RESULT"
assert_regions_differ "$BLANK" "$FILL2" "fill for clear test should change the canvas"

key Delete
wait_for 0.4 "Clear (real)"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "pu-clear1"
CLEAR1="$SNAP_RESULT"
assert_regions_differ "$FILL2" "$CLEAR1" "clear should remove the fill"

# Clear again — layer already empty, so a no-op.
key Delete
wait_for 0.4 "Clear again (no-op)"
assert_no_crash

# ONE undo must reverse the real clear → fill returns.
key ctrl+z
wait_for 0.4 "Undo clear"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "pu-clear-undo"
CLEAR_UNDO="$SNAP_RESULT"
assert_regions_same "$FILL2" "$CLEAR_UNDO" "one undo must restore the fill (no phantom from the second clear)"
screenshot "phantom-undo-clear"

# Reset to blank for the flip test.
key ctrl+z
wait_for 0.3 "Undo back to blank"

# =============================================================================
# F11 — Flip H: flipping a uniformly-filled layer is visually identical.
# =============================================================================
info "F11: fill uniform, flip H (no-op), → 1 undo reverses the fill"
key f
wait_for 0.2 "Fill tool"
click $CANVAS_CX $CANVAS_CY
wait_for 0.5 "Uniform fill (real)"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "pu-fill3"
FILL3="$SNAP_RESULT"
assert_regions_differ "$BLANK" "$FILL3" "uniform fill should change the canvas"

# Flip H — a uniformly filled layer maps onto itself, so no visible change.
key h
wait_for 0.5 "Flip H (no-op on uniform fill)"
assert_no_crash
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "pu-flip"
FLIP="$SNAP_RESULT"
assert_regions_same "$FILL3" "$FLIP" "flip of a uniform fill is visually identical"

# ONE undo must reverse the fill → blank. If the no-op flip recorded a phantom,
# this undo reverses that instead and the canvas stays filled.
key ctrl+z
wait_for 0.4 "Undo"
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "pu-flip-undo"
FLIP_UNDO="$SNAP_RESULT"
assert_regions_same "$BLANK" "$FLIP_UNDO" "one undo must reverse the fill (no phantom from the no-op flip)"
screenshot "phantom-undo-flip"

assert_no_crash
assert_window_exists
info "=== Phantom-undo no-op test COMPLETE ==="
