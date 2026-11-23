#!/bin/bash
# =============================================================================
# effect-stainedglass.sh — QA test / regression guard
#
# EFFECTS > Stained Glass... Voronoi panes with dark leading between them.
# (Added 2026-08-14.) Crossing green + red strokes, apply, assert the region
# changed (panes + dark borders). BORDER 0 (2026-11-22): the panes alone, no leading.
#
# EFFECTS menu index 26 (0-based) -> dropdown item viewport y = 20 + 26*12 = 332.
# =============================================================================

info "=== Effect: Stained Glass Test ==="

canvas_focus b
wait_for 0.3 "Brush ready"
for n in 1 2 3 4; do key bracketright; done
wait_for 0.2 "Brush enlarged"

CHIP_Y=$(( VIEWPORT_H - STATUS_H - 6 ))
click $(( 16 + 11*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Green FG"
drag $(( CANVAS_CX - 80 )) $(( CANVAS_CY )) $(( CANVAS_CX + 80 )) $(( CANVAS_CY ))
click $(( 16 + 23*17 + 8 )) "$CHIP_Y" ; wait_for 0.2 "Red FG"
drag "$CANVAS_CX" $(( CANVAS_CY - 50 )) "$CANVAS_CX" $(( CANVAS_CY + 50 ))
key grave
wait_for 0.3 "Content drawn"
assert_no_crash

GX=$(( CANVAS_CX - 60 )); GY=$(( CANVAS_CY - 40 )); GW=120; GH=80
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "stainedglass-before"
BEFORE="$SNAP_RESULT"

open_effect 4 1 ; wait_for 0.5 "Stained Glass dialog open"
screenshot "stainedglass-dialog"
key Return ; wait_for 0.7 "Applied (OK), dialog closed"
assert_no_crash

park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "stainedglass-after"
AFTER="$SNAP_RESULT"
screenshot "stainedglass-canvas-after"

assert_regions_differ "$BEFORE" "$AFTER" \
    "Stained Glass must add panes with dark borders"
assert_no_crash

# --- BORDER 0 (Rick 2026-11-22: "can we make border have 0 as an option"): the
# panes alone, no leading (#0C0C10) at all. The BORDER slider is the dialog's
# second track, at viewport y 341 (the dialog: x 351..606, CELL SIZE at 303,
# 38 px a row - IMGDLG_track_y%); a click at its left end sets 0.
sg_lead() { magick "$1" -fill white +opaque '#0C0C10' -fill black -opaque '#0C0C10' -negate -format '%[fx:int(mean*w*h+0.5)]' info: 2>/dev/null; }
LEAD1=$(sg_lead "$AFTER")
(( ${LEAD1:-0} > 0 )) && pass "BORDER 2 (the default): dark leading between the panes ($LEAD1 px)" || fail "no leading at the default border ($LEAD1)"
key ctrl+z ; wait_for 0.6 "Undo the stained glass"
open_effect 4 1 ; wait_for 0.5 "Stained Glass dialog open (again)"
click 360 341 ; wait_for 0.4 "BORDER to 0 (the track's left end, x 359)"
screenshot "stainedglass-dialog-border0"
key Return ; wait_for 0.7 "Applied with BORDER 0"
assert_no_crash
park_mouse
snap_region "$GX" "$GY" "$GW" "$GH" "stainedglass-border0"
B0="$SNAP_RESULT"
LEAD0=$(sg_lead "$B0")
assert_regions_differ "$BEFORE" "$B0" "BORDER 0 still makes panes"
[[ "$LEAD0" == 0 ]] && pass "BORDER 0: the panes alone, no leading" || fail "BORDER 0: $LEAD0 px of leading (want 0: the slider stops at 1?)"
assert_window_exists
info "=== Effect: Stained Glass Test PASSED ==="
