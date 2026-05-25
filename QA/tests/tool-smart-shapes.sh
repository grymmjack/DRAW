#!/bin/bash
# =============================================================================
# tool-smart-shapes.sh — QA test: Smart Shapes tool (S key, action 1706)
# Tests: S activates remembered sub-shape; double-tap cycles to next sub-shape.
# Phase 6a-ii added CASE 1706 with STATIC ss_last_tap_1706 for the
# 600ms double-tap window.
# =============================================================================

info "=== Smart Shapes Tool Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap status bar area (tool name changes there) --
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "ss-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- First tap = activate remembered Smart Shape sub-tool --
info "First S tap (activate Smart Shapes)"
key s
wait_for 0.4 "S activated"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "ss-activated"
ACTIVATED="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$ACTIVATED" "S should activate Smart Shapes tool (status bar updates)"
assert_no_crash

# -- Second tap within 600ms = cycle to next sub-shape --
info "Second S tap within 600ms (cycle sub-shape)"
key s
wait_for 0.4 "S cycled"
park_mouse
snap_region 0 $(( VIEWPORT_H - STATUS_H )) $VIEWPORT_W $STATUS_H "ss-cycled"
CYCLED="$SNAP_RESULT"
assert_regions_differ "$ACTIVATED" "$CYCLED" "Second S tap within 600ms should cycle sub-shape"
assert_no_crash

# -- Wait > 600ms, then S should activate (not cycle) --
sleep 0.9
info "Third S tap after 600ms (activate, not cycle)"
key s
wait_for 0.4 "S after delay"
assert_no_crash

# -- Switch back to brush for cleanup --
key b
wait_for 0.2 "Brush"

assert_window_exists
info "=== Smart Shapes Tool Test PASSED ==="
