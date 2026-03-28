#!/bin/bash
# =============================================================================
# image-adj-invert.sh — QA test: Image invert and desaturate (menu actions)
# Tests: Invert colors (action 2007), undo
# Note: These are menu-only operations, no direct hotkey
# =============================================================================

info "=== Image Adjust Invert Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size increased"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Draw some colored content --
drag $(( CANVAS_CX - 25 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 25 )) $(( CANVAS_CY + 10 ))
wait_for 0.3 "Reference content drawn"
assert_no_crash

# -- Snap before invert --
park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "invert-before"
BEFORE="$SNAP_RESULT"

# -- Open Image menu and click Invert --
# Navigate menu: Image menu is typically the 4th menu item
info "Opening Image menu for Invert"
key alt+i
wait_for 0.5 "Image menu opened"
assert_no_crash

# Find and click Invert in the menu
# Send 'i' to jump to Invert item, then Enter
key i
wait_for 0.2 "Navigated to Invert"
key Return
wait_for 0.8 "Invert applied"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "invert-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Invert should change canvas colors"
screenshot "after-invert"

# -- Undo invert --
info "Undoing invert (Ctrl+Z)"
key ctrl+z
wait_for 0.5 "Invert undone"
assert_no_crash

park_mouse
snap_region $(( CANVAS_CX - 80 )) $(( CANVAS_CY - 60 )) 160 120 "invert-undo"
UNDO="$SNAP_RESULT"
assert_regions_differ "$AFTER" "$UNDO" "Undo should restore original colors"

# -- Cleanup --
key ctrl+z
wait_for 0.3 "Cleanup"
assert_no_crash

assert_window_exists
info "=== Image Adjust Invert Test PASSED ==="
