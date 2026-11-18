#!/bin/bash
# =============================================================================
# brush-aa-quality.sh — QA test: antialiased brush strokes (Rick 2026-11-17:
# "our anti aliasing algorithm is pretty shitty").
#   With Antialias on, a mouse stroke draws through the per-pixel stroke mask
#   (strongest coverage wins - soft edges never build up into hard ones), at
#   the pointer's sub-pixel position, along a smoothed path; a thick Line-tool
#   line is one soft capsule; partial coverage blends in straight alpha (QB64's
#   _BLEND turned soft edges on a transparent layer dark).
#   Draws slow shallow lines and a circle at zoom 1 and at 300%, and a thick
#   line, in white over the empty layer, and works out each pixel's coverage
#   from the shots before and after. Old build: ~1/3 the soft pixels (z1 1236 /
#   zoom 4476 vs 3280 / 14616 now). Coverage maps: *-coverage.png in screenshots.
# QA-OPTIONS: WORKSPACE=default ANTIALIAS=TRUE DEFAULT_BRUSH_SIZE=6 DEFAULT_BRUSH_SHAPE=0 TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
info "=== Brush: antialiased stroke quality ==="
CX=$CANVAS_CX; CY=$CANVAS_CY

# slow_path X0 Y0 X1 Y1 — a slow drag, one viewport px per pointer move
slow_path() {
    local x0=$1 y0=$2 x1=$3 y1=$4 n i px py ax ay
    n=$(awk -v a="$x0" -v b="$y0" -v c="$x1" -v d="$y1" 'BEGIN { dx = c - a; dy = d - b; if (dx < 0) dx = -dx; if (dy < 0) dy = -dy; print (dx > dy ? dx : dy) }')
    local SEQ=()
    for i in $(seq 1 "$n"); do
        read -r px py <<< "$(awk -v i="$i" -v n="$n" -v a="$x0" -v b="$y0" -v c="$x1" -v d="$y1" 'BEGIN { printf "%d %d", a + (c - a) * i / n + 0.5, b + (d - b) * i / n + 0.5 }')"
        read -r ax ay <<< "$(_abs "$px" "$py")"
        SEQ+=(move "$ax" "$ay" sleep 6)
    done
    mouse_down "$x0" "$y0"
    raw_seq "${SEQ[@]}"
    wait_for 0.3 "frames catch up"
    mouse_up
    wait_for 0.3 "stroke done"
}
# slow_circle CX CY R
slow_circle() {
    local cx=$1 cy=$2 r=$3 i px py ax ay
    local SEQ=()
    for i in $(seq 0 180); do
        read -r px py <<< "$(awk -v i="$i" -v r="$r" -v cx="$cx" -v cy="$cy" 'BEGIN { a = i * 3.14159265 * 2 / 180; printf "%d %d", cx + r * cos(a) + 0.5, cy + r * sin(a) + 0.5 }')"
        read -r ax ay <<< "$(_abs "$px" "$py")"
        SEQ+=(move "$ax" "$ay" sleep 6)
    done
    mouse_down $(( cx + r )) "$cy"
    raw_seq "${SEQ[@]}"
    wait_for 0.3 "frames catch up"
    mouse_up
    wait_for 0.3 "stroke done"
}

key b; wait_for 0.3 "brush"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX - 100 )) $(( CY - 60 )) 190 90 "brush-aa-z1-before"; Z1B="$SNAP_RESULT"

# --- zoom 1 ---------------------------------------------------------------------
slow_path $(( CX - 90 )) $(( CY - 50 )) $(( CX + 10 )) $(( CY - 30 ))
slow_path $(( CX - 90 )) $(( CY - 20 )) $(( CX + 10 )) $(( CY + 15 ))
slow_circle $(( CX + 50 )) $(( CY - 20 )) 28
park_mouse; wait_for 0.4 "park"
snap_region $(( CX - 100 )) $(( CY - 60 )) 190 90 "brush-aa-z1"; Z1="$SNAP_RESULT"
screenshot "brush-aa-z1"
key ctrl+z; key ctrl+z; key ctrl+z; wait_for 0.4 "undo"

# --- a thick antialiased line (Line tool): a soft circle stamped at every pixel ------
snap_region $(( CX - 100 )) $(( CY + 35 )) 200 50 "line-aa-before"; LNB="$SNAP_RESULT"
key l; wait_for 0.3 "line"
drag $(( CX - 90 )) $(( CY + 45 )) $(( CX + 90 )) $(( CY + 72 ))
wait_for 0.4 "line done"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX - 100 )) $(( CY + 35 )) 200 50 "line-aa"; LN="$SNAP_RESULT"
key ctrl+z; wait_for 0.3 "undo"
key b; wait_for 0.3 "brush"

# --- zoomed in (Ctrl+= twice: 300%) ------------------------------------------------
key ctrl+equal; wait_for 0.3 "zoom"; key ctrl+equal; wait_for 0.5 "zoom"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX - 160 )) $(( CY - 80 )) 320 200 "brush-aa-zoom-before"; ZZB="$SNAP_RESULT"
slow_path $(( CX - 150 )) $(( CY - 60 )) $(( CX + 150 )) $(( CY - 20 ))
slow_circle "$CX" $(( CY + 50 )) 60
park_mouse; wait_for 0.4 "park"
snap_region $(( CX - 160 )) $(( CY - 80 )) 320 200 "brush-aa-zoom"; ZZ="$SNAP_RESULT"
screenshot "brush-aa-zoom"
key ctrl+z; key ctrl+z; key ctrl+z; wait_for 0.3 "undo"
key ctrl+0; wait_for 0.3 "zoom reset"

# --- soft edges: each pixel's coverage, from the shot before and after (white paint
# over the checkerboard: a = (after - before) / (1 - before)). A soft stroke has
# in-between coverages along its edges; a hard one is only 0 and 1.
for pair in "$Z1B $Z1 z1" "$ZZB $ZZ zoom" "$LNB $LN line"; do
    read -r b a nm <<< "$pair"
    cov="${a%.png}-coverage.png"
    magick "$a" "$b" -colorspace gray -fx "v >= 0.999 ? 0 : (u - v) / (1 - v)" "$cov" 2>/dev/null
    read -r FULL SOFT <<< "$(magick "$cov" -fx "u >= 0.97 ? 1 : 0" -format "%[fx:mean*w*h] " info: 2>/dev/null; magick "$cov" -fx "(u > 0.03 && u < 0.97) ? 1 : 0" -format "%[fx:mean*w*h]" info: 2>/dev/null)"
    FULL=${FULL%.*}; SOFT=${SOFT%.*}
    info "$nm: $FULL full px, $SOFT soft px (coverage map $(basename "$cov"))"
    if (( FULL < 200 )); then
        fail "$nm: the strokes barely painted ($FULL px)"
    elif (( SOFT * 100 < FULL * 15 )); then
        fail "$nm: hard edges - only $SOFT soft px for $FULL full px"
    else
        pass "$nm: antialiased edges ($SOFT soft px for $FULL full px)"
    fi
done
assert_no_crash
