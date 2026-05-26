#!/bin/bash
# =============================================================================
# chord-zoom-presets.sh — QA test: Z+digit zoom presets (Phase 6e)
# Tests: Z+1=100%, Z+5=500%, Z+0=3200% via the chord initiator pattern.
# Verifies the central dispatcher's CTX_Z_HELD chord handling (actions
# 9100-9109 in COMMAND.BM, bindings in INPUT.BM Phase 6e block).
# =============================================================================

# Helper: press chord <init> + <secondary> with proper hold timing so DRAW's
# INPUT_update_context sees CTX_<init>_HELD set before INPUT_detect_events
# fires the edge for <secondary>.
chord() {
    local init=$1 secondary=$2
    draw_focus
    dbg "chord $init+$secondary"
    xdotool keydown "$init"
    sleep 0.15   # let CTX_<init>_HELD register (≥2 idle frames at 13fps)
    xdotool keydown "$secondary"
    sleep 0.20   # let edge detect + action fire
    xdotool keyup "$secondary"
    sleep 0.05
    xdotool keyup "$init"
    sleep 0.15   # let CTX_<init>_HELD clear before next chord
}

info "=== Z+digit Zoom Preset Chord Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Establish baseline zoom (Ctrl+0 = reset to 100%) --
key ctrl+0
wait_for 0.4 "Zoom reset to 100%"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "zoom-100-baseline"
ZOOM_100="$SNAP_RESULT"
assert_no_crash

# -- Z+5 = 500% zoom (action 9104) --
info "Chord Z+5 (zoom 500%)"
chord z 5
wait_for 0.5 "Z+5 fired"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "zoom-500"
ZOOM_500="$SNAP_RESULT"
assert_regions_differ "$ZOOM_100" "$ZOOM_500" "Z+5 should zoom to 500% (canvas pixels enlarge)"
assert_no_crash

# -- Z+1 = 100% (back to baseline; action 9100) --
info "Chord Z+1 (zoom 100%)"
chord z 1
wait_for 0.5 "Z+1 fired"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "zoom-back-100"
ZOOM_BACK_100="$SNAP_RESULT"
assert_regions_differ "$ZOOM_500" "$ZOOM_BACK_100" "Z+1 should zoom back to 100% (canvas pixels shrink)"
assert_no_crash

# -- Z+0 = 3200% (action 9109) --
info "Chord Z+0 (zoom 3200%)"
chord z 0
wait_for 0.5 "Z+0 fired"
park_mouse
snap_region $WORK_LEFT $WORK_TOP $WORK_W $WORK_H "zoom-3200"
ZOOM_3200="$SNAP_RESULT"
assert_regions_differ "$ZOOM_BACK_100" "$ZOOM_3200" "Z+0 should zoom to 3200%"
assert_no_crash

# -- Reset for cleanup --
key ctrl+0
wait_for 0.3 "Reset zoom"

assert_window_exists
info "=== Z+digit Zoom Preset Test PASSED ==="
