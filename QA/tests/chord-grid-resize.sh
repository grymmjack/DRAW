#!/bin/bash
# =============================================================================
# chord-grid-resize.sh — QA test: G+arrows grid resize chord
# Phase 6e migrated to actions 9010-9013 (G+Right/Left/Down/Up).
# =============================================================================

chord() {
    local init=$1 secondary=$2
    draw_focus
    xdotool keydown "$init"
    sleep 0.15
    xdotool keydown "$secondary"
    sleep 0.20
    xdotool keyup "$secondary"
    sleep 0.05
    xdotool keyup "$init"
    sleep 0.15
}

info "=== G+arrows Grid Resize Chord Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Enable grid for visibility --
key apostrophe
wait_for 0.3 "Grid on"

park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-default"
DEFAULT="$SNAP_RESULT"
assert_no_crash

# -- G+Right ×4 = increase grid width (action 9010) --
info "Chord G+Right ×4 (increase width)"
chord g Right
chord g Right
chord g Right
chord g Right
wait_for 0.3 "Width increased"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-wider"
WIDER="$SNAP_RESULT"
assert_regions_differ "$DEFAULT" "$WIDER" "G+Right should widen grid"

# -- G+Left ×4 = decrease grid width back (action 9011) --
info "Chord G+Left ×4 (decrease width)"
chord g Left
chord g Left
chord g Left
chord g Left
wait_for 0.3 "Width decreased"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-back-default-w"
BACK_DEFAULT_W="$SNAP_RESULT"
assert_regions_differ "$WIDER" "$BACK_DEFAULT_W" "G+Left should narrow grid back"

# -- G+Down ×4 = increase grid height (action 9012) --
info "Chord G+Down ×4 (increase height)"
chord g Down
chord g Down
chord g Down
chord g Down
wait_for 0.3 "Height increased"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-taller"
TALLER="$SNAP_RESULT"
assert_regions_differ "$BACK_DEFAULT_W" "$TALLER" "G+Down should grow grid height"

# -- G+Up ×4 = decrease grid height back (action 9013) --
info "Chord G+Up ×4 (decrease height)"
chord g Up
chord g Up
chord g Up
chord g Up
wait_for 0.3 "Height decreased"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "grid-back-default-h"
BACK_DEFAULT_H="$SNAP_RESULT"
assert_regions_differ "$TALLER" "$BACK_DEFAULT_H" "G+Up should shrink grid height back"

# -- Disable grid for cleanup --
key apostrophe
wait_for 0.3 "Grid off"

assert_window_exists
info "=== G+arrows Chord Test PASSED ==="
