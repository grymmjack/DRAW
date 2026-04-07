#!/bin/bash
# =============================================================================
# util-refimg.sh — QA test: Reference Image Overlay
# Tests: Load ref image (via command palette), toggle Ctrl+R, verify overlay
# NOTE: Loading requires a file dialog which is hard to automate.
#       This test verifies toggle and crash safety.
# =============================================================================

info "=== Reference Image Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap canvas BEFORE any ref image operations --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "refimg-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Toggle ref image visibility with Ctrl+R (nothing loaded = no-op) --
info "Toggle ref image (Ctrl+R — no image loaded, should be no-op)"
key ctrl+r
wait_for 0.3 "Ref image toggle (no image)"
assert_no_crash

# -- Verify canvas unchanged --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "refimg-after-toggle"
AFTER_TOGGLE="$SNAP_RESULT"
assert_regions_same "$BEFORE" "$AFTER_TOGGLE" "Toggle with no ref image should not change canvas"

# -- Final check --
assert_no_crash
assert_window_exists
info "=== Reference Image Test PASSED ==="
