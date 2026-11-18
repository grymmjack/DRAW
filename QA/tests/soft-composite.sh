#!/bin/bash
# =============================================================================
# soft-composite.sh — QA test: a soft (antialiased) stroke looks the same whatever path
# composites it, and merging keeps it (2026-11-18, the B1 class: QB64's _BLEND greys a
# half-transparent pixel landing on an empty one).
# The layer composite runs when the Preview is open (or a blend mode / group needs it);
# without, the layers draw straight onto the canvas. A soft stroke on a layer above an
# empty one came out darker with the composite, and darker again once merged down.
#   1. two airbrush clouds (Spray + Antialias - soft: many colours; an AA line drew hard
#      pixels here) on two new layers over the empty Background, overlapping (soft over
#      soft: the case QB64's blend gets wrong), Preview closed:
#      the plain path (straight onto the opaque checkerboard - always right)
#   2. Preview open (the composite path): the same pixels
#   3. Merge Layer Down twice (the lines together, then onto the Background): the same
#   4. Preview closed again: the same pixels
# QA-OPTIONS: WORKSPACE=default TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=TRUE PREVIEW_VISIBLE=0
# =============================================================================
info "=== A soft stroke through the layer composite and a merge ==="
pcmd() { park_mouse; key question; wait_for 1.0 "command palette"; type_text "$1"; wait_for 0.6 "filtered"; key Return; wait_for 1.0 "$1"; park_mouse; wait_for 0.4 "settle"; }
ae() { magick compare -metric AE -fuzz 1.5% "$1" "$2" null: 2>&1 | awk '$1 ~ /^[0-9.e+]+$/ {print int($1); exit} {print 99999; exit}'; }
RX=$(( CANVAS_CX - 70 )); RY=$(( CANVAS_CY - 45 ))
park_mouse; wait_for 0.4 "settle"
snap_region "$RX" "$RY" 140 90 "sc-blank"; BLANK="$SNAP_RESULT"

cloud() { # X Y: hold the airbrush still there a moment
    local ax ay; read -r ax ay <<< "$(_abs "$1" "$2")"
    draw_focus; raw_move "$ax" "$ay"; sleep 0.1
    raw_button down 1; sleep 0.8; raw_button up 1; wait_for 0.4 "released"
}
pcmd "New Layer"
canvas_focus k; wait_for 0.3 "spray tool"
for _ in 1 2 3 4 5; do key bracketright; done
key grave; wait_for 0.2 "pointer hidden"
cloud $(( CANVAS_CX - 12 )) "$CANVAS_CY"
pcmd "New Layer"
canvas_focus k; wait_for 0.3 "spray tool"
cloud $(( CANVAS_CX + 12 )) "$CANVAS_CY"
park_mouse; wait_for 0.5 "settle"
snap_region "$RX" "$RY" 140 90 "sc-plain"; PLAIN="$SNAP_RESULT"
D=$(ae "$BLANK" "$PLAIN"); (( D > 60 )) && pass "the clouds are drawn ($D px)" || fail "nothing drawn ($D px)"
NC=$(magick "$PLAIN" -format '%k' info:)
(( NC > 20 )) && pass "the clouds are soft ($NC colours)" || fail "the clouds have $NC colours - no soft pixels to test"

key F4; wait_for 1.0 "Preview open: the composite path"
park_mouse; wait_for 0.5 "settle"
snap_region "$RX" "$RY" 140 90 "sc-composite"; COMP="$SNAP_RESULT"
D=$(ae "$PLAIN" "$COMP"); (( D <= 3 )) && pass "with the composite (Preview open) the soft line looks the same ($D px off)" || fail "the composite changes the soft line: $D px differ"
screenshot "soft-composite-preview"

pcmd "Merge Layer Down"
snap_region "$RX" "$RY" 140 90 "sc-merged1"
D=$(ae "$PLAIN" "$SNAP_RESULT"); (( D <= 3 )) && pass "the two lines merged: the same pixels ($D px off)" || fail "merging the soft lines changed them: $D px differ"
pcmd "Merge Layer Down"
snap_region "$RX" "$RY" 140 90 "sc-merged"; MERGED="$SNAP_RESULT"
D=$(ae "$PLAIN" "$MERGED"); (( D <= 3 )) && pass "merged onto the Background: the same pixels ($D px off)" || fail "the merge changed the soft line: $D px differ"

key F4; wait_for 1.0 "Preview closed"
park_mouse; wait_for 0.5 "settle"
snap_region "$RX" "$RY" 140 90 "sc-merged-plain"
D=$(ae "$PLAIN" "$SNAP_RESULT"); (( D <= 3 )) && pass "merged, Preview closed: the same pixels ($D px off)" || fail "merged + plain: $D px differ"
assert_no_crash
