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

# -- Snap viewport before --
park_mouse
snap_region 0 0 $VP_W $VP_H "editbar-before"
BEFORE="$SNAP_RESULT"
assert_no_crash

# -- Toggle edit bar: F5 --
info "Toggling edit bar (F5)"
key F5
wait_for 0.5 "Edit bar toggled"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "editbar-toggled"
TOGGLED="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$TOGGLED" "Edit bar toggle should change viewport"
screenshot "editbar-toggled"

# -- Toggle back: F5 --
info "Toggling edit bar back (F5)"
key F5
wait_for 0.5 "Edit bar restored"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "editbar-restored"
RESTORED="$SNAP_RESULT"
assert_regions_differ "$TOGGLED" "$RESTORED" "Second F5 should restore original state"

assert_window_exists
info "=== Edit Bar Toggle Test PASSED ==="
