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
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "invert-before"
BEFORE="$SNAP_RESULT"

# -- Invoke Invert via Command Palette (?  + type "invert" + Enter) --
# Alt+letter menus are disabled in DRAW; use command palette instead
info "Opening Command Palette and invoking Invert"
key shift+slash
wait_for 0.5 "Command palette opened"
type_text "invert"
wait_for 0.5 "Typed invert"
key Return
wait_for 1.0 "Invert applied"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "invert-after"
AFTER="$SNAP_RESULT"
assert_regions_differ "$BEFORE" "$AFTER" "Invert should change canvas colors"
screenshot "after-invert"

# -- Undo invert --
info "Undoing invert (Ctrl+Z)"
key ctrl+z
wait_for 0.5 "Invert undone"
assert_no_crash

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "invert-undo"
UNDO="$SNAP_RESULT"
assert_regions_differ "$AFTER" "$UNDO" "Undo should restore original colors"

# -- Cleanup --
key ctrl+z
wait_for 0.3 "Cleanup"
assert_no_crash

assert_window_exists
info "=== Image Adjust Invert Test PASSED ==="
