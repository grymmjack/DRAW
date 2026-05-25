#!/bin/bash
# =============================================================================
# chord-marquee-expand.sh — QA test: M+= / M+- selection expand/contract chord
# Phase 6e migrated these to actions 1410-1413 (M chord initiator,
# CTX_M_HELD context bit). Verifies chord dispatch + selection-active guard
# (CASE 1410-1413 now no-op when SELECTION_has_active% is FALSE).
# =============================================================================

# Helper: chord init+secondary with proper hold timing.
chord() {
    local init=$1 secondary=$2
    draw_focus
    dbg "chord $init+$secondary"
    xdotool keydown "$init"
    sleep 0.15
    xdotool keydown "$secondary"
    sleep 0.20
    xdotool keyup "$secondary"
    sleep 0.05
    xdotool keyup "$init"
    sleep 0.15
}

# Helper: chord with shift modifier on secondary (M+Shift+= = M++)
chord_shift() {
    local init=$1 secondary=$2
    draw_focus
    dbg "chord $init+shift+$secondary"
    xdotool keydown "$init"
    sleep 0.15
    xdotool keydown shift
    sleep 0.10
    xdotool keydown "$secondary"
    sleep 0.20
    xdotool keyup "$secondary"
    sleep 0.05
    xdotool keyup shift
    sleep 0.05
    xdotool keyup "$init"
    sleep 0.15
}

info "=== M+= / M+- Selection Expand/Contract Chord Test ==="
canvas_focus b
wait_for 0.3 "Brush tool ready"
key grave
wait_for 0.1 "Pointer arrow hidden"

# -- Switch to marquee + create a small selection --
key m
wait_for 0.3 "Marquee tool"
drag $(( CANVAS_CX - 15 )) $(( CANVAS_CY - 10 )) $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 10 ))
wait_for 0.4 "Marquee created"

park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 30 )) 80 60 "marquee-base"
BASE="$SNAP_RESULT"
assert_no_crash

# -- M+= expand 1px (action 1410) --
info "Chord M+= (expand 1px)"
chord m equal
wait_for 0.4 "M+= fired"
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 30 )) 80 60 "marquee-expanded"
EXPANDED="$SNAP_RESULT"
assert_regions_differ "$BASE" "$EXPANDED" "M+= should expand marquee by 1px"

# -- M+- contract 1px (action 1411) --
info "Chord M+- (contract 1px)"
chord m minus
wait_for 0.4 "M+- fired"
park_mouse
snap_region $(( CANVAS_CX - 40 )) $(( CANVAS_CY - 30 )) 80 60 "marquee-contracted"
CONTRACTED="$SNAP_RESULT"
assert_regions_differ "$EXPANDED" "$CONTRACTED" "M+- should contract marquee back"

# -- M+Shift+= expand large (action 1412 — CFG.NUDGE_N px) --
info "Chord M+Shift+= (expand large)"
chord_shift m equal
wait_for 0.4 "M+Shift+= fired"
park_mouse
snap_region $(( CANVAS_CX - 50 )) $(( CANVAS_CY - 40 )) 100 80 "marquee-expanded-large"
EXPANDED_LARGE="$SNAP_RESULT"
assert_regions_differ "$CONTRACTED" "$EXPANDED_LARGE" "M+Shift+= should expand marquee by NUDGE_N px"

# -- Cleanup --
key ctrl+d
wait_for 0.3 "Deselect"

assert_window_exists
info "=== M+= / M+- Chord Test PASSED ==="
