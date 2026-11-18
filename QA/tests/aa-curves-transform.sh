#!/bin/bash
# =============================================================================
# aa-curves-transform.sh — QA test: antialiased curves and smooth transforms
# (Rick 2026-11-17: "for circle, and bezier, and so on, not so great ...
# steppy"; "if anti aliasing is on, when we do transformations, can it use
# bicubic or something to preserve the smoothness?").
#   (Starts with Antialias off; the palette's Toggle Anti-Aliasing turns it on
#   between the hard drawing and the transform.)
#   1. A thick Ellipse-tool circle with Antialias on is one smooth ring
#      (PAINT_aa_ellipse: capsules between the exact points) - its coverage map
#      is saved for review; it must have soft edge pixels.
#   3. A thick Bezier with a smooth anchor: capsules between the curve's exact
#      points, not its whole-pixel ones - soft edge pixels.
#   2. Hard-edged shapes (drawn with Antialias off), selected and scaled by a
#      non-whole factor with Edit > Transform > Scale after Antialias is turned
#      on: the result is resampled smoothly (bicubic) - soft pixels appear where
#      the nearest-pixel resample had none.
# Coverage = (after - before) / (1 - before): white paint over the checkerboard.
# QA-OPTIONS: WORKSPACE=default ANTIALIAS=FALSE DEFAULT_BRUSH_SIZE=6 DEFAULT_BRUSH_SHAPE=0 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
info "=== Antialiased curves + smooth transform ==="
CX=$CANVAS_CX; CY=$CANVAS_CY

coverage() { # BEFORE AFTER NAME -> FULL SOFT (and a coverage map beside AFTER)
    local cov="${2%.png}-coverage.png"
    magick "$2" "$1" -colorspace gray -fx "v >= 0.999 ? 0 : (u - v) / (1 - v)" "$cov" 2>/dev/null
    FULL=$(magick "$cov" -fx "u >= 0.97 ? 1 : 0" -format "%[fx:mean*w*h]" info: 2>/dev/null); FULL=${FULL%.*}
    SOFT=$(magick "$cov" -fx "(u > 0.03 && u < 0.97) ? 1 : 0" -format "%[fx:mean*w*h]" info: 2>/dev/null); SOFT=${SOFT%.*}
    info "$3: $FULL full px, $SOFT soft px ($(basename "$cov"))"
}
palette_run() { key question; wait_for 0.4 "palette"; type_text "$1"; wait_for 0.3 "filter"; key Return; wait_for 0.8 "$1"; }

# --- 2. smooth transform -------------------------------------------------------------
park_mouse; wait_for 0.3 "park"
key b; wait_for 0.3 "brush"
drag $(( CX + 10 )) $(( CY - 40 )) $(( CX + 50 )) $(( CY - 40 ))
wait_for 0.3 "top"
drag $(( CX + 10 )) $(( CY - 40 )) $(( CX + 10 )) $(( CY - 5 ))
wait_for 0.3 "left"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX ))  $(( CY - 55 )) 110 100 "xf-hard"; XH="$SNAP_RESULT"
key m; wait_for 0.3 "marquee"
drag $(( CX + 2 )) $(( CY - 48 )) $(( CX + 58 )) $(( CY + 3 ))
wait_for 0.4 "marquee made"
palette_run "toggle anti-aliasing" # Antialias ON
screenshot "aa-xf-toggled"
palette_run "transform scale"
park_mouse; wait_for 0.3 "park"
screenshot "aa-xf-handles"
drag $(( CX + 58 )) $(( CY + 3 )) $(( CX + 81 )) $(( CY + 19 ))
wait_for 1.5 "scaled + smooth resample"
key Return; wait_for 1.0 "applied"
key Escape; wait_for 0.3 "deselect"
park_mouse; wait_for 0.4 "park"
snap_region $(( CX ))  $(( CY - 55 )) 110 100 "xf-scaled"; XS="$SNAP_RESULT"
screenshot "aa-xf-scaled"
# in-between px: lighter than the checkerboard (gray 112) but not paint white
HARD_SOFT=$(magick "$XH" -colorspace gray -fx "(u > 0.47 && u < 0.97) ? 1 : 0" -format "%[fx:mean*w*h]" info: 2>/dev/null); HARD_SOFT=${HARD_SOFT%.*}
XS_SOFT=$(magick "$XS" -colorspace gray -fx "(u > 0.47 && u < 0.97) ? 1 : 0" -format "%[fx:mean*w*h]" info: 2>/dev/null); XS_SOFT=${XS_SOFT%.*}
info "light-but-not-white px: hard shape $HARD_SOFT, scaled $XS_SOFT"
assert_regions_differ "$XH" "$XS" "the transform changed the shape"
if (( XS_SOFT > HARD_SOFT + 40 )); then
    pass "the scaled shape has smooth edges ($XS_SOFT in-between px, was $HARD_SOFT)"
else
    fail "the scaled shape is still hard-edged ($XS_SOFT in-between px, was $HARD_SOFT)"
fi
key b; wait_for 0.2 "brush"; park_mouse; wait_for 0.3 "park"
# --- 1. thick antialiased circle ----------------------------------------------------
snap_region $(( CX - 120 )) $(( CY - 70 )) 100 100 "aa-circle-before"; CB="$SNAP_RESULT"
key c; wait_for 0.3 "ellipse"
drag $(( CX - 110 )) $(( CY - 60 )) $(( CX - 30 )) $(( CY + 20 ))
wait_for 0.5 "ellipse done"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX - 120 )) $(( CY - 70 )) 100 100 "aa-circle"; CA="$SNAP_RESULT"
coverage "$CB" "$CA" "circle"
if (( ${FULL:-0} < 200 )); then fail "circle: barely painted ($FULL px)"
elif (( SOFT * 100 < FULL * 15 )); then fail "circle: hard edges - $SOFT soft px for $FULL full px"
else pass "circle: smooth ring ($SOFT soft px for $FULL full px)"; fi
key ctrl+z; wait_for 0.3 "undo"

# --- 3. a thick antialiased Bezier (a smooth anchor in the middle) ---------------------
snap_region $(( CX - 130 )) $(( CY + 25 )) 200 70 "aa-bez-before"; BB="$SNAP_RESULT"
key q; wait_for 0.3 "bezier"
click $(( CX - 120 )) $(( CY + 80 )); wait_for 0.2 "anchor 1"
drag $(( CX - 30 )) $(( CY + 40 )) $(( CX + 15 )) $(( CY + 30 )); wait_for 0.2 "smooth anchor 2"
click $(( CX + 55 )) $(( CY + 75 )); wait_for 0.2 "anchor 3"
key Return; wait_for 0.6 "committed"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX - 130 )) $(( CY + 25 )) 200 70 "aa-bez"; BA="$SNAP_RESULT"
screenshot "aa-bezier"
coverage "$BB" "$BA" "bezier"
if (( ${FULL:-0} < 200 )); then fail "bezier: barely painted ($FULL px)"
elif (( SOFT * 100 < FULL * 15 )); then fail "bezier: hard edges - $SOFT soft px for $FULL full px"
else pass "bezier: smooth curve ($SOFT soft px for $FULL full px)"; fi
key ctrl+z; wait_for 0.3 "undo"
key b; wait_for 0.2 "brush"

assert_no_crash
