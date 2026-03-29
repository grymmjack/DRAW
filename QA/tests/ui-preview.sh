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

# -- Get to known state: ensure preview is visible (F4 shows it) --
# Preview defaults hidden. Press F4 to show it first, wait, then test toggling.
info "Ensuring preview is visible (F4 to show)"
key F4
wait_for 0.8 "Preview window shown"

# -- Snap viewport with preview visible --
park_mouse
snap_region 0 0 $VP_W $VP_H "preview-visible"
VISIBLE="$SNAP_RESULT"
assert_no_crash

# -- Toggle preview window OFF: F4 --
info "Hiding preview window (F4)"
key F4
wait_for 0.8 "Preview window hidden"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "preview-hidden"
HIDDEN="$SNAP_RESULT"
assert_regions_differ "$VISIBLE" "$HIDDEN" "Preview toggle should change viewport"
screenshot "preview-hidden"

# -- Toggle preview window ON again: F4 --
info "Showing preview window again (F4)"
key F4
wait_for 0.8 "Preview window restored"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "preview-restored"
RESTORED="$SNAP_RESULT"
assert_regions_differ "$HIDDEN" "$RESTORED" "Second F4 should restore preview"

assert_window_exists
info "=== Preview Window Toggle Test PASSED ==="
