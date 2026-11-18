#!/bin/bash
# =============================================================================
# mypaint-fast-stroke.sh — QA test: a fast MyPaint stroke follows the pointer
# (Rick 2026-11-18: "it seems lower fidelity than real mypaint program?"). The
# MyPaint tool fed libmypaint one whole-pixel position a frame, so fast curves came
# out as straight chords; now every pointer event of the frame (MOUSE_SMP_*, kept at
# sub-pixel steps for this tool) is a stroke_to with its share of the frame's time.
#   The same circle as brush-fast-stroke.sh (72 pointer moves in ~0.3 s, DRAW held
#   to 6 fps) with kabura (opaque, no slow tracking): nearly every painted pixel must lie on the circle.
# QA-OPTIONS: WORKSPACE=default FPS_LIMIT=6 ANTIALIAS=FALSE TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE MYPAINT_PANEL=TRUE MYPAINT_PANEL_SCALE=0 MYPAINT_BRUSH=ASSETS/BRUSHES/MYPAINT/classic/kabura.myb MYPAINT_SIZE=0 DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
source "$DRAW_ROOT/QA/dock-lib.sh"
info "=== MyPaint: a fast stroke follows the pointer ==="
R=36
CX=$CANVAS_CX; CY=$CANVAS_CY
M=$(( R + 8 ))
read -r SX SY < <(_qa_scale)
dk_begin

dk_park; key question; wait_for 1.5 "command palette"; type_text "MyPaint Brush"; wait_for 1.0 "filtered"; key Return; wait_for 1.5 "the MyPaint tool"
dk_park; dk_settle
read -r _ T_TOOL _ <<< "$(grep -m1 '^MYP ' "$DK_DUMP")"
(( T_TOOL != 0 )) && pass "the MyPaint tool" || fail "not the MyPaint tool (MYP tool '$T_TOOL')"
park_mouse; wait_for 0.3 "park"
snap_region $(( CX - M )) $(( CY - M )) $(( 2 * M )) $(( 2 * M )) "mpfast-before"; B="$SNAP_RESULT"

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
snap_region $(( CX - M )) $(( CY - M )) $(( 2 * M )) $(( 2 * M )) "mpfast-after"; A="$SNAP_RESULT"
screenshot "mypaint-fast-circle"
dk_settle
read -r _ _ _ _ T_STROKES T_STEPS _ <<< "$(grep -m1 '^MYP ' "$DK_DUMP")"
info "stroke_to calls in the stroke: $T_STEPS"

# painted pixels = those that changed (any visible change: the pencil is soft); each one's
# distance from the circle (viewport px). kabura is ~5 px wide at pressure 0.5: its half width + 1, so 4 px (the old build: 32 px off, 9 events).
read -r N BAD WORST <<< "$(magick "$B" "$A" -compose difference -composite -colorspace gray -threshold 12% txt:- 2>/dev/null \
    | awk -v sx="$SX" -v m="$M" -v r="$R" -F'[,: ]+' '
        /^#/ { next }
        /#FFFFFF|white|gray\(255/ {
            x = $1 / sx; y = $2 / sx; d = sqrt((x - m) ^ 2 + (y - m) ^ 2) - r; if (d < 0) d = -d
            n++; if (d > 4) bad++; if (d > w) w = d
        }
        END { printf "%d %d %.1f\n", n, bad + 0, w + 0 }')"
info "painted $N px, $BAD off the circle, worst ${WORST}px"
if (( ${N:-0} < 40 )); then
    fail "the stroke barely painted ($N px changed) - did the drag land?"
elif (( ${BAD:-0} * 100 <= ${N:-1} * 2 )); then
    pass "a fast MyPaint circle stays on the circle (worst ${WORST}px off, $BAD of $N px past 4px)"
else
    fail "a fast MyPaint circle cut corners: $BAD of $N painted px more than 4px off it (worst ${WORST}px)"
fi
(( ${T_STEPS:-0} > 20 )) && pass "the stroke got the frame's pointer events ($T_STEPS stroke_to calls at 6 fps)" || fail "only ${T_STEPS:-0} stroke_to calls - one a frame?"
key ctrl+z; wait_for 0.3 "undo"
assert_no_crash
