#!/bin/bash
# =============================================================================
# ui-editbar.sh — QA test: Edit bar toggle with F5
# Tests: F5 (show edit bar), F5 (hide edit bar)
# =============================================================================

info "=== Edit Bar Toggle Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Get to known state: ensure editbar is visible (F5 shows it) --
# Editbar defaults hidden. Press F5 to show it first, wait, then test toggling.
info "Ensuring editbar is visible (F5 to show)"
key F5
wait_for 0.8 "Edit bar shown"

# -- Snap viewport with editbar visible --
park_mouse
snap_region 0 0 $VP_W $VP_H "editbar-visible"
VISIBLE="$SNAP_RESULT"
assert_no_crash

# -- Toggle edit bar OFF: F5 --
info "Hiding edit bar (F5)"
key F5
wait_for 0.8 "Edit bar hidden"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "editbar-hidden"
HIDDEN="$SNAP_RESULT"
assert_regions_differ "$VISIBLE" "$HIDDEN" "Edit bar toggle should change viewport"
screenshot "editbar-hidden"

# -- Toggle edit bar ON again: F5 --
info "Showing edit bar again (F5)"
key F5
wait_for 0.8 "Edit bar restored"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "editbar-restored"
RESTORED="$SNAP_RESULT"
assert_regions_differ "$HIDDEN" "$RESTORED" "Second F5 should restore editbar"

assert_window_exists
info "=== Edit Bar Toggle Test PASSED ==="
