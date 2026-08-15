#!/bin/bash
# =============================================================================
# effect-rust.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Rust... a fractal-noise oxide overlay masked to the shape's
# alpha; corroded pixels blend toward a dark-brown -> orange -> light-oxide ramp.
# (Added 2026-08-14, Eye Candy SHAPE.) RGB-only, stays inside the shape.
#
# SHAPE is EFFECTS category index 7; Rust is child 11 -> open_effect 7 11.
# Thick green blob on a transparent layer; apply; assert the blob interior
# changed (green -> rusty blotches).
# =============================================================================

info "=== Effect: Rust Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6 7 8 9 10 11 12; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 40 )) "$CANVAS_CY" $(( CANVAS_CX + 40 )) "$CANVAS_CY"
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Blob interior — rust blotches recolour it.
GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 12 )); GW=80; GH=24
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "rust-before"
BEFORE="$SNAP_RESULT"

open_effect 7 11 ; wait_for 0.5 "Rust dialog open"
screenshot "rust-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "rust-after"
AFTER="$SNAP_RESULT"
screenshot "rust-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Rust must corrode the shape interior with oxide blotches"
assert_no_crash
assert_window_exists
info "=== Effect: Rust Test PASSED ==="
