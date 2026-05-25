#!/bin/bash
# =============================================================================
# tool-bezier.sh — QA test: Bezier curve tool (Q key, action 122)
# Tests: Q switch, click 3 control points, Enter commits the curve, Ctrl+Z undo.
# Phase 6a-iii added the Q binding (dispatched=TRUE).
# =============================================================================

info "=== Bezier Tool Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap baseline canvas --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "bezier-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Switch to Bezier (Q) --
info "Switch to Bezier tool (Q)"
key q
wait_for 0.3 "Bezier tool active"
assert_no_crash

# -- Click 3 control points (start, control, end) --
info "Click control points"
click $(( CANVAS_CX - 30 )) $(( CANVAS_CY + 10 ))
wait_for 0.2 "Point 1"
click $CANVAS_CX $(( CANVAS_CY - 30 ))
wait_for 0.2 "Point 2 (control)"
click $(( CANVAS_CX + 30 )) $(( CANVAS_CY + 10 ))
wait_for 0.2 "Point 3 (end)"
assert_no_crash

# -- Commit with Enter --
info "Commit bezier (Enter)"
key Return
wait_for 0.5 "Curve committed"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "bezier-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Bezier curve should be visible on canvas"

# -- Undo --
key ctrl+z
wait_for 0.4 "Undo bezier"
assert_no_crash

# -- Switch back to brush for cleanup --
key b
wait_for 0.2 "Brush"

assert_window_exists
info "=== Bezier Tool Test PASSED ==="
