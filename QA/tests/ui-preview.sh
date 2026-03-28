#!/bin/bash
# =============================================================================
# ui-preview.sh — QA test: Preview window toggle with F4
# Tests: F4 (show preview window), F4 (hide preview window)
# =============================================================================

info "=== Preview Window Toggle Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap viewport before --
park_mouse
snap_region 0 0 $VP_W $VP_H "preview-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Toggle preview window: F4 --
info "Toggling preview window (F4)"
key F4
wait_for 0.5 "Preview window toggled"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "preview-toggled"
TOGGLED="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$TOGGLED" "Preview toggle should change viewport"
screenshot "preview-toggled"

# -- Toggle back: F4 --
info "Toggling preview window back (F4)"
key F4
wait_for 0.5 "Preview window restored"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "preview-restored"
RESTORED="$SNAP_RESULT"
assert_regions_differ "$TOGGLED" "$RESTORED" "Second F4 should restore original state"

assert_window_exists
info "=== Preview Window Toggle Test PASSED ==="
