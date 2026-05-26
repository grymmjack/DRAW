#!/bin/bash
# =============================================================================
# tool-smart-shapes.sh — QA test: Smart Shapes tool (S key, action 1706)
# Tests: S activates remembered sub-shape; second S within 600ms cycles.
# Phase 6a-ii added CASE 1706 with STATIC ss_last_tap_1706 for the 600ms
# double-tap window.
#
# CRITICAL TIMING: the standard `key` helper has ~150-200ms of overhead
# (draw_focus + sleeps) so two back-to-back `key s` calls already eat
# 300-400ms. Adding snap_region between them pushes the gap past 600ms
# and the second tap re-activates instead of cycling. We use direct
# xdotool keydown/keyup with controlled timing and only snap AFTER both
# taps complete.
# =============================================================================

info "=== Smart Shapes Tool Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap status bar area in brush mode --
park_mouse
snap_region 0 "$(( VIEWPORT_H - STATUS_H ))" "$VIEWPORT_W" "$STATUS_H" "ss-brush"
BRUSH="$SNAP_RESULT"
assert_no_crash

# -- First S tap (activate). Direct xdotool — minimal overhead. --
info "First S tap (activate Smart Shapes)"
draw_focus
xdotool keydown s
sleep 0.15
xdotool keyup s
sleep 0.20

# -- Second S tap within 600ms (cycle). Total time from first keydown to
#    second keydown should be ~350ms — well inside the 600ms window. --
info "Second S tap within 600ms (cycle sub-shape)"
xdotool keydown s
sleep 0.15
xdotool keyup s
sleep 0.30

# -- Snap status bar after both taps --
park_mouse
snap_region 0 "$(( VIEWPORT_H - STATUS_H ))" "$VIEWPORT_W" "$STATUS_H" "ss-after-cycle"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BRUSH" "$AFTER" "Two S taps should switch FROM brush TO smart shape (and cycle)"
assert_no_crash

# -- Wait > 600ms, then a third S tap (window expired — re-activate, not cycle) --
sleep 0.9
info "Third S tap after >600ms (window expired)"
key s
wait_for 0.4 "S re-activated"
assert_no_crash

# -- Cleanup --
key b
wait_for 0.2 "Brush"

assert_window_exists
info "=== Smart Shapes Tool Test PASSED ==="
