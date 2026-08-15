#!/bin/bash
# =============================================================================
# effect-glass.sh — QA test / regression guard
#
# EFFECTS > SHAPE > Glass... a glassy sheen: translucent lightening + two diagonal specular streaks.
# alpha; 
# (Added 2026-08-14, Eye Candy SHAPE.) RGB-only, apply_to_layer.
#
# SHAPE is EFFECTS category index 7; Glass is child 17 -> open_effect 7 17.
# Thick green blob on a transparent layer; apply; assert the blob interior
# changed (green -> glassy blotches).
# =============================================================================

info "=== Effect: Glass Test ==="

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

# Blob interior — glass blotches recolour it.
GX=$(( CANVAS_CX - 40 )); GY=$(( CANVAS_CY - 12 )); GW=80; GH=24
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "glass-before"
BEFORE="$SNAP_RESULT"

open_effect 7 17 ; wait_for 0.5 "Glass dialog open"
screenshot "glass-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "glass-after"
AFTER="$SNAP_RESULT"
screenshot "glass-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Glass must add a glassy sheen to the shape interior"
assert_no_crash
assert_window_exists
info "=== Effect: Glass Test PASSED ==="
