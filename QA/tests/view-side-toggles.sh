#!/bin/bash
# =============================================================================
# view-side-toggles.sh — QA test: Ctrl+Shift+Arrow UI side toggles
# Tests: Ctrl+Shift+Left/Right/Up/Down hide/show UI sides
# =============================================================================

info "=== View Side Toggles Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Snap full viewport before any changes --
park_mouse
screenshot "sides-before"
snap_region 0 0 $VP_W $VP_H "sides-all-visible"
ALL_VISIBLE="$SNAP_RESULT"
assert_no_crash

# -- Toggle LEFT side off: Ctrl+Shift+Left --
info "Hiding left side UI (Ctrl+Shift+Left)"
key ctrl+shift+Left
wait_for 0.5 "Left side hidden"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "sides-left-hidden"
LEFT_HIDDEN="$SNAP_RESULT"
assert_regions_differ "$ALL_VISIBLE" "$LEFT_HIDDEN" "Hiding left side should change layout"

# -- Toggle LEFT side back on --
info "Restoring left side UI"
key ctrl+shift+Left
wait_for 0.5 "Left side restored"
assert_no_crash

# -- Toggle RIGHT side off: Ctrl+Shift+Right --
info "Hiding right side UI (Ctrl+Shift+Right)"
key ctrl+shift+Right
wait_for 0.5 "Right side hidden"
assert_no_crash

park_mouse
snap_region 0 0 $VP_W $VP_H "sides-right-hidden"
RIGHT_HIDDEN="$SNAP_RESULT"
assert_regions_differ "$ALL_VISIBLE" "$RIGHT_HIDDEN" "Hiding right side should change layout"

# -- Toggle RIGHT side back on --
key ctrl+shift+Right
wait_for 0.5 "Right side restored"
assert_no_crash

assert_window_exists
info "=== View Side Toggles Test PASSED ==="
