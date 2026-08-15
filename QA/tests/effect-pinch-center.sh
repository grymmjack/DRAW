#!/bin/bash
# =============================================================================
# effect-pinch-center.sh — QA test / regression guard
#
# CLICK-TO-SET-CENTER for Pinch / Bulge (added 2026-08-15). The effect used to
# always warp around the image centre. Now a click inside the loupe preview pane
# places the warp centre at that canvas point (shared IMGADJ_center_pick_pane /
# IMGADJ_center_* helpers; the engine takes a centre param, -1 = image centre).
#
# The effect dialog centres on the SCREEN, but the canvas centre is offset from
# the screen centre by the left toolbar — so the loupe under the dialog shows a
# canvas region that is NOT the canvas centre. We therefore flood the WHOLE canvas
# with horizontal stripes (features everywhere), open Pinch, CLICK a spot in the
# preview pane (off the central split-bar grab), and apply. Zoom is 1 in the QA
# config, so the warp lands at the same viewport point we clicked; we sample there
# and assert the stripes were displaced. effect-pinch.sh covers the default centre.
#
# Pinch = open_effect 3 2. Dialog 256x254 centred in a 958x514 viewport: preview
# pane ≈ viewport x[352..605], y[146..290]; split bar ≈ x=479. (430,210) is inside
# the pane, on stripes, and well clear of the split grab zone.
# =============================================================================

info "=== Effect: Pinch Click-to-Centre Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
# Flood the whole canvas with horizontal stripes (thin brush) so wherever the
# loupe looks there are features to displace.
CW=${CANVAS_W:-320}
for dy in $(seq -90 10 90); do
    drag $(( CANVAS_CX - CW/2 )) $(( CANVAS_CY + dy )) $(( CANVAS_CX + CW/2 )) $(( CANVAS_CY + dy ))
done
key grave
wait_for 0.3 "Stripes drawn"
assert_no_crash

# Sample around where we will click in the preview pane (zoom 1 → warp lands here).
GX=400; GY=180; GW=60; GH=60
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "pinch-center-before"
BEFORE="$SNAP_RESULT"

open_effect 3 2 ; wait_for 0.5 "Pinch dialog open"
screenshot "pinch-center-dialog"
# Click in the preview pane, off the split bar, to move the warp centre there.
click 430 210 ; wait_for 0.4 "Centre picked in preview"
screenshot "pinch-center-picked"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "pinch-center-after"
AFTER="$SNAP_RESULT"
screenshot "pinch-center-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Pinch with a picked centre must displace the stripes near the picked point"
assert_no_crash
assert_window_exists
info "=== Effect: Pinch Click-to-Centre Test PASSED ==="
