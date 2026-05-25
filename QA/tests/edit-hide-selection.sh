#!/bin/bash
# =============================================================================
# edit-hide-selection.sh — QA test: Ctrl+H Hide Selection overlay
# Action 332 (Hide Selection — Photoshop-style overlay toggle that
# preserves the selection, only hiding the marching-ants display).
# Phase 6d batch 4 migrated Ctrl+H to dispatched=TRUE.
# =============================================================================

info "=== Hide Selection Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Create a marquee selection --
key m
wait_for 0.3 "Marquee tool"
drag $(( CANVAS_CX - 25 )) $(( CANVAS_CY - 20 )) $(( CANVAS_CX + 25 )) $(( CANVAS_CY + 20 ))
wait_for 0.4 "Marquee created (marching ants visible)"

park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 40 )) 100 80 "marquee-visible"
VISIBLE="$SNAP_RESULT"
assert_no_crash

# -- Ctrl+H = Hide Selection overlay (marching ants disappear, selection preserved) --
info "Ctrl+H (Hide Selection overlay)"
key ctrl+h
wait_for 0.5 "Selection hidden"
park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 40 )) 100 80 "marquee-hidden"
HIDDEN="$SNAP_RESULT"
assert_regions_differ "$VISIBLE" "$HIDDEN" "Ctrl+H should hide the marquee overlay"

# -- Ctrl+H again = show again --
info "Ctrl+H (Show Selection overlay)"
key ctrl+h
wait_for 0.5 "Selection shown"
park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 40 )) 100 80 "marquee-shown-again"
SHOWN_AGAIN="$SNAP_RESULT"
assert_regions_differ "$HIDDEN" "$SHOWN_AGAIN" "Ctrl+H again should show marquee overlay"

# -- Cleanup --
key ctrl+d
wait_for 0.3 "Deselect"

assert_window_exists
info "=== Hide Selection Test PASSED ==="
