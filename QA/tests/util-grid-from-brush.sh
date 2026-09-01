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

# -- Verify via the STATUS BAR "G:NxN" readout, not the canvas: the grid overlay
#    is not visibly rendered over the transparent QA canvas at 100%, so a canvas
#    diff can't see a size change. The status bar shows the live grid size. --
SB_Y=$(( VIEWPORT_H - STATUS_H ))
park_mouse
snap_region 100 "$SB_Y" 260 "$STATUS_H" "grid-default-size"
DEFAULT_GRID="$SNAP_RESULT"
assert_no_crash

# -- Invoke action 907 "Make Grid Match Brush Size" via the command palette.
#    Its Ctrl+Shift+/ keychord binds _KEYHIT keycode 63 (`?`), which is unreliable
#    for Ctrl combos on Linux/SDL2 (project gotcha #6) and does not dispatch under
#    xdotool/Xvfb — every spelling (ctrl+shift+slash / ctrl+shift+question /
#    ctrl+question) is dropped. The palette exercises the same action reliably, so
#    the test guards the FEATURE; the keychord path can't be driven offscreen. --
info "Make Grid Match Brush Size (action 907, via command palette)"
key shift+slash
wait_for 0.5 "Command palette open"
type_text "Make Grid Match Brush"
wait_for 0.5 "Filtered"
key Return
wait_for 0.6 "Grid resized to brush size"
park_mouse
snap_region 100 "$SB_Y" 260 "$STATUS_H" "grid-matched"
MATCHED="$SNAP_RESULT"
assert_regions_differ "$DEFAULT_GRID" "$MATCHED" \
    "Make Grid Match Brush Size should change the grid size (status bar G:NxN)"

# -- Cleanup: disable grid --
key apostrophe
wait_for 0.3 "Grid off"

assert_window_exists
info "=== Match Grid to Brush Test PASSED ==="
