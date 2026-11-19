#!/bin/bash
# =============================================================================
# sel-trace-visible.sh — QA test: the lasso / polygon selection trace shows on white
# (Rick 2026-11-18: "i can't see them - good on white background i'm drawing" / "it is
# polyline and poly lasso select that act this way the shape ones look fine"). The trace
# was white (and the rubber band yellow) only; each segment has a black shadow now.
#   1. a white canvas, Freehand Select dragged and HELD: the path shows dark pixels
#   2. Polygon Select with two vertices placed: the placed edge shows dark pixels
# QA-OPTIONS: WORKSPACE=default TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE SELECTION_FEATHER=0 SELECTION_MODE=REPLACE ANTIALIAS=FALSE
# =============================================================================
info "=== Lasso / polygon trace on white ==="
palette_run() { park_mouse; key question; wait_for 0.8 "palette"; type_text "$1"; wait_for 0.5 "filter"; key Return; wait_for 1.0 "$1"; }
dark() { magick "$1" -colorspace gray -threshold 30% -negate -format '%[fx:int(mean*w*h+0.5)]' info: 2>/dev/null; }

canvas_focus f
wait_for 0.3 "fill tool"
click $(( CANVAS_CX - 60 )) $(( CANVAS_CY - 50 )); wait_for 0.5 "filled"
park_mouse; wait_for 0.3 "settle"
RX=$(( CANVAS_CX - 50 )); RY=$(( CANVAS_CY - 30 ))
snap_region "$RX" "$RY" 100 60 "trace-white"; W="$SNAP_RESULT"
N0=$(dark "$W"); info "dark px on the white fill: $N0"

# --- 1. freehand, held ------------------------------------------------------------------
palette_run "Freehand Select"
SEQ=()
for i in $(seq 0 24); do
    read -r px py <<< "$(awk -v i="$i" -v cx="$CANVAS_CX" -v cy="$CANVAS_CY" 'BEGIN { a = i * 3.14159265 / 16; printf "%d %d", cx - 35 + i * 3, cy + 18 * sin(a) }')"
    read -r ax ay <<< "$(_abs "$px" "$py")"
    SEQ+=(move "$ax" "$ay" sleep 30)
done
mouse_down $(( CANVAS_CX - 35 )) "$CANVAS_CY"
raw_seq "${SEQ[@]}"
wait_for 0.6 "trace drawn"
snap_region "$RX" "$RY" 100 60 "trace-free"; F="$SNAP_RESULT"
screenshot "sel-trace-freehand"
mouse_up; wait_for 0.5 "released"
N1=$(dark "$F"); info "dark px with the freehand trace held: $N1"
(( N1 > N0 + 30 )) && pass "the freehand trace shows on white ($N1 dark px)" || fail "the freehand trace is not visible on white ($N1 dark px, $N0 without)"
key ctrl+d; wait_for 0.4 "deselect"

# --- 2. polygon, two vertices -------------------------------------------------------------
palette_run "Polygon Select"
click $(( CANVAS_CX - 35 )) $(( CANVAS_CY - 15 )); wait_for 0.4 "vertex 1"
click $(( CANVAS_CX + 35 )) $(( CANVAS_CY - 15 )); wait_for 0.4 "vertex 2"
hover $(( CANVAS_CX + 20 )) $(( CANVAS_CY + 20 )); wait_for 0.5 "rubber band"
snap_region "$RX" "$RY" 100 60 "trace-poly"; P="$SNAP_RESULT"
screenshot "sel-trace-polygon"
N2=$(dark "$P"); info "dark px with two polygon vertices: $N2"
(( N2 > N0 + 30 )) && pass "the polygon trace shows on white ($N2 dark px)" || fail "the polygon trace is not visible on white ($N2 dark px, $N0 without)"
key Escape; wait_for 0.4 "cancel"
assert_no_crash
