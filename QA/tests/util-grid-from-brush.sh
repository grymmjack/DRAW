#!/bin/bash
# =============================================================================
# util-grid-from-brush.sh — QA test: Ctrl+Shift+/ Match grid to brush size
# Action 907 (Make Grid Match Brush Size + enable snap + center alignment).
# Phase 6e migrated this from inline KEYBOARD_handle_grid_controls.
# =============================================================================

info "=== Match Grid to Brush Size Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Make brush size larger so grid change is visible --
key bracketright
key bracketright
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size 6+"

# -- Enable grid for visibility --
key apostrophe
wait_for 0.3 "Grid on"

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-default-size"
DEFAULT_GRID="$SNAP_RESULT"
assert_no_crash

# -- Ctrl+Shift+/ = set grid size from brush size, enable snap+center align --
# Note: keycode is `?` (63) which is Shift+/ on US layouts. The DRAW dispatcher
# binding uses keycode 63 + MOD_CTRL|MOD_SHIFT — xdotool's "ctrl+shift+slash"
# sends Ctrl held + Shift held + / pressed, which lands on keycode 63 in X.
info "Ctrl+Shift+/ (match grid to brush size)"
key ctrl+shift+slash
wait_for 0.5 "Grid resized to brush size"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-matched"
MATCHED="$SNAP_RESULT"
assert_regions_differ "$DEFAULT_GRID" "$MATCHED" "Ctrl+Shift+/ should resize grid to brush size"

# -- Cleanup: reset grid + disable --
key apostrophe
wait_for 0.3 "Grid off"

assert_window_exists
info "=== Match Grid to Brush Test PASSED ==="
