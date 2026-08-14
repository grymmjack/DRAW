#!/bin/bash
# =============================================================================
# effect-growshrink.sh — QA test / regression guard
#
# EFFECTS > Grow / Shrink... morphologically fattens (GROW) or thins (SHRINK) a
# shape by its alpha. (Added 2026-08-14.) Draws a green stroke on a TRANSPARENT
# layer, applies GROW, and asserts a band around the stroke gained pixels (the
# green expands into the previously-transparent area).
#
# EFFECTS menu index 10 (0-based) -> dropdown item viewport y = 20 + 10*12 = 140.
# =============================================================================

info "=== Effect: Grow / Shrink Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
# Alpha morphology needs transparency -> use a fresh transparent layer.
key ctrl+shift+n ; wait_for 0.4 "New transparent layer"
for n in 1 2 3 4 5 6; do key bracketright; done
wait_for 0.2 "Brush enlarged"

# Green stroke (chip 11 = 76,255,77) on the transparent layer.
CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 70 )) $(( CANVAS_CY )) $(( CANVAS_CX + 70 )) $(( CANVAS_CY ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

# Band taller than the stroke so the GROW (added above/below) shows.
GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 16 )); GW=120; GH=32
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "growshrink-before"
BEFORE="$SNAP_RESULT"

# Open Grow / Shrink via EFFECTS menu; push AMOUNT up (GROW is default), commit.
click 395 6   ; wait_for 0.4 "EFFECTS menu open"
click 420 140 ; wait_for 0.7 "Grow/Shrink dialog open"
screenshot "growshrink-dialog"
drag 400 317 540 317 ; wait_for 0.2 "Amount up"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "growshrink-after"
AFTER="$SNAP_RESULT"
screenshot "growshrink-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Grow must fatten the green stroke into the transparent band"
assert_no_crash
assert_window_exists
info "=== Effect: Grow / Shrink Test PASSED ==="
