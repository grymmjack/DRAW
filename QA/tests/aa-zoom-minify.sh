#!/bin/bash
# =============================================================================
# aa-zoom-minify.sh — QA test: zoomed-out canvas is area-averaged with
# Antialias on (Rick 2026-11-17: "can we make zoom use bicubic too in anti
# alias mode? like i zoom out and detail is lost").
#   1px lines drawn at 100%, then Zoom Out: with Antialias on the shrunk lines
#   stay as soft gray (RENDER_minify_put averages the canvas pixels each screen
#   pixel covers); with it off, nearest-pixel shrinking drops whole rows /
#   columns - no in-between grays.
# QA-OPTIONS: WORKSPACE=default ANTIALIAS=TRUE DEFAULT_BRUSH_SIZE=1 DEFAULT_BRUSH_SHAPE=1 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
info "=== Antialiased zoom-out (area average) ==="
CX=$CANVAS_CX; CY=$CANVAS_CY
palette_run() { key question; wait_for 0.4 "palette"; type_text "$1"; wait_for 0.3 "filter"; key Return; wait_for 0.8 "$1"; }
# in-between px in a capture: neither checker gray-ish dark nor paint white
mid_px() { magick "$1" -colorspace gray -fx "(u > 0.52 && u < 0.93) ? 1 : 0" -format "%[fx:mean*w*h]" info: 2>/dev/null | cut -d. -f1; }

park_mouse; wait_for 0.3 "park"
key b; wait_for 0.3 "brush"
# a fan of 1px lines (odd spacing so a 2:1 shrink can not land on all of them)
for i in 0 3 7 10 14 17 21 24; do
    drag $(( CX - 60 + i * 3 )) $(( CY - 40 )) $(( CX - 40 + i * 3 )) $(( CY + 40 ))
    wait_for 0.15 "line $i"
done
park_mouse; wait_for 0.3 "park"
screenshot "aa-zoom-100"

palette_run "zoom out"
park_mouse; wait_for 0.6 "zoomed out"
snap_region $(( CX - 60 )) $(( CY - 40 )) 120 80 "zoom-aa-on"; ON="$SNAP_RESULT"
screenshot "aa-zoom-out-aa-on"
MON=$(mid_px "$ON")

palette_run "toggle anti-aliasing"   # Antialias OFF
park_mouse; wait_for 0.6 "redraw"
snap_region $(( CX - 60 )) $(( CY - 40 )) 120 80 "zoom-aa-off"; OFF="$SNAP_RESULT"
screenshot "aa-zoom-out-aa-off"
MOFF=$(mid_px "$OFF")
info "in-between px when zoomed out: Antialias on $MON, off $MOFF"
assert_regions_differ "$ON" "$OFF" "Antialias changes the zoomed-out view"
if (( ${MON:-0} > ${MOFF:-0} + 100 )); then
    pass "zoomed out with Antialias: lines kept as soft grays ($MON in-between px, $MOFF without)"
else
    fail "zoomed out with Antialias: no averaging ($MON in-between px, $MOFF without)"
fi
palette_run "toggle anti-aliasing"   # back ON
palette_run "zoom in"

assert_no_crash
