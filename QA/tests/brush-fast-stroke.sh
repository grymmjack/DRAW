#!/bin/bash
# =============================================================================
# brush-fast-stroke.sh — QA test: a fast brush stroke follows the pointer
# (Rick 2026-11-17: "the pen can't seem to keep up if i draw fast? it makes
# lines not smooth"). DRAW used to read the pointer once a frame, so a stroke
# faster than the frame rate came out as straight chords between frames. Now
# every pointer event of a frame is a stroke point (MOUSE_SMP_*,
# MOUSE_brush_samples).
#   A circle of 72 pointer moves sent in one fast burst (~0.3 s) with DRAW held
#   to 6 fps: every painted pixel must lie on the circle (within 2.5 viewport
#   px). Chords between frames would cut up to R (1 - cos(half the arc a frame
#   covers)) inside it - many px at this speed.
# QA-OPTIONS: WORKSPACE=default FPS_LIMIT=6 ANTIALIAS=FALSE TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
info "=== Brush: a fast stroke follows the pointer ==="
R=36
CX=$CANVAS_CX; CY=$CANVAS_CY
M=$(( R + 8 ))
read -r SX SY < <(_qa_scale)

key b; wait_for 0.3 "brush"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX - M )) $(( CY - M )) $(( 2 * M )) $(( 2 * M )) "fast-before"; B="$SNAP_RESULT"

# the circle, as absolute screen points, sent as one xdotool burst
SEQ=()
for i in $(seq 0 72); do
    read -r px py <<< "$(awk -v i="$i" -v r="$R" -v cx="$CX" -v cy="$CY" 'BEGIN { a = i * 3.14159265 * 2 / 72; printf "%d %d", cx + r * cos(a) + 0.5, cy + r * sin(a) + 0.5 }')"
    read -r ax ay <<< "$(_abs "$px" "$py")"
    SEQ+=(move "$ax" "$ay" sleep 4)
done
mouse_down $(( CX + R )) "$CY"
raw_seq "${SEQ[@]}"
wait_for 0.5 "frames catch up"
mouse_up
wait_for 0.5 "stroke done"
park_mouse; wait_for 0.4 "park"
snap_region $(( CX - M )) $(( CY - M )) $(( 2 * M )) $(( 2 * M )) "fast-after"; A="$SNAP_RESULT"
screenshot "brush-fast-circle"

# painted pixels = those that changed; each one's distance from the circle (viewport px)
read -r N BAD WORST <<< "$(magick "$B" "$A" -compose difference -composite -colorspace gray -threshold 8% txt:- 2>/dev/null \
    | awk -v sx="$SX" -v m="$M" -v r="$R" -F'[,: ]+' '
        /^#/ { next }
        /#FFFFFF|white|gray\(255/ {
            x = $1 / sx; y = $2 / sx; d = sqrt((x - m) ^ 2 + (y - m) ^ 2) - r; if (d < 0) d = -d
            n++; if (d > 2.5) bad++; if (d > w) w = d
        }
        END { printf "%d %d %.1f\n", n, bad + 0, w + 0 }')"
info "painted $N px, $BAD off the circle, worst ${WORST}px"
if (( ${N:-0} < 40 )); then
    fail "the stroke barely painted ($N px changed) - did the drag land?"
elif (( ${BAD:-0} * 100 <= ${N:-1} * 2 )); then
    pass "a fast circle stays on the circle (worst ${WORST}px off, $BAD of $N px past 2.5px)"
else
    fail "a fast circle cut corners: $BAD of $N painted px more than 2.5px off it (worst ${WORST}px)"
fi
key ctrl+z; wait_for 0.3 "undo"
assert_no_crash
