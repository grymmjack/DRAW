#!/bin/bash
# =============================================================================
# mouse-pressure.sh — QA test: mouse expression (Rick 2026-11-18, "a way to use
# pressure with the mouse ... so the folks who don't have [tablets] can simulate
# that"). Pen Control's MOUSE tab (QB64_GJ_LIB MOUSE_PRESSURE) gives mouse strokes
# a made-up pressure, so Size by Pressure thins them. Each case relaunches with its
# --option set and draws a straight 160 px stroke; the stroke's thickness is the
# number of changed pixels down one column of a before / after snapshot.
#   1 OFF: the full brush width (the baseline)
#   2 FIXED 25%: thinner than OFF
#   3 SPEED: a slow stroke comes out thicker than a fast one
#   4 WHEEL: scrolling down mid-stroke makes the rest of it thinner
#   5 TAPER IN / OUT: the stroke starts and ends thinner than its middle
#     (the taper-out is redrawn on release)
#   6 MyPaint (pointy_ink.myb, radius by pressure): FIXED 15% paints fewer pixels than OFF
# An old build (no mouse expression) draws every case at full width: 2-6 fail.
# QA-OPTIONS: WORKSPACE=default TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE ANTIALIAS=FALSE DEFAULT_BRUSH_SIZE=12 PEN_PRESSURE_SIZE=TRUE PEN_MIN_SIZE=10 PEN_PRESSURE_CURVE=100 PEN_PRESSURE_OPACITY=FALSE PEN_STAB=FALSE PEN_SPEED=FALSE PEN_PROC=FALSE
# =============================================================================
info "=== Mouse expression: made-up pressure for mouse strokes ==="

relaunch() { # --option args...
    draw_quit; draw_settle
    DRAW_EXTRA_ARGS="$*"
    draw_launch 15; wait_for 1.5 "DRAW up ($*)"
    canvas_focus b; wait_for 0.3 "brush"
    key grave; wait_for 0.1 "pointer arrow hidden"
}
X0=$(( CANVAS_CX - 80 )); X1=$(( CANVAS_CX + 80 ))
RX=$(( X0 - 20 )); RW=200 # the snapshot region: the stroke plus 20 px each side
# stroke Y MOVES MS - a straight drag X0 -> X1 in MOVES steps, MS ms apart
stroke() {
    local i x ax ay SEQ=()
    for (( i = 1; i <= $2; i++ )); do
        x=$(( X0 + (X1 - X0) * i / $2 ))
        read -r ax ay <<< "$(_abs "$x" "$1")"
        SEQ+=(move "$ax" "$ay" sleep "$3")
    done
    mouse_down $X0 "$1"
    raw_seq "${SEQ[@]}"
    wait_for 0.3 "frames catch up"
    mouse_up; wait_for 0.5 "stroke done"
}
snap_row() { park_mouse; wait_for 0.2 "park"; snap_region $RX $(( $1 - 24 )) $RW 48 "$2"; }
# width BEFORE AFTER F - changed pixels down the column F (0..1) along the stroke
width() {
    local w col
    w=$(magick identify -format "%w" "$1" 2>/dev/null)
    col=$(awk -v w="$w" -v f="$3" -v rx="$RX" -v x0="$X0" -v x1="$X1" -v rw="$RW" 'BEGIN { printf "%d", w * ((x0 - rx) + (x1 - x0) * f) / rw }')
    magick "$1" "$2" -compose difference -composite -colorspace gray -threshold 2% \
        -crop "1x+${col}+0" +repage -format "%[fx:round(mean*h)]" info: 2>/dev/null
}
pixels() { # BEFORE AFTER - every changed pixel
    magick "$1" "$2" -compose difference -composite -colorspace gray -threshold 2% -format "%[fx:round(mean*w*h)]" info: 2>/dev/null
}
Y=$CANVAS_CY

# --- 1: OFF ------------------------------------------------------------------------
relaunch --option PEN_MOUSE=0
snap_row $Y "off-before"; B=$SNAP_RESULT
stroke $Y 32 25
snap_row $Y "off-after"; A=$SNAP_RESULT
W_OFF=$(width "$B" "$A" 0.5)
(( ${W_OFF:-0} >= 6 )) && pass "OFF: the stroke is drawn at the full brush width ($W_OFF)" || fail "OFF: stroke width '$W_OFF' (no stroke?)"

# --- 2: FIXED 25% --------------------------------------------------------------------
relaunch --option PEN_MOUSE=1 --option PEN_MOUSE_LEVEL=25
snap_row $Y "fixed-before"; B=$SNAP_RESULT
stroke $Y 32 25
snap_row $Y "fixed-after"; A=$SNAP_RESULT
W_FIX=$(width "$B" "$A" 0.5)
(( ${W_FIX:-0} >= 1 && W_FIX * 10 <= W_OFF * 7 )) && pass "FIXED 25%: thinner than OFF ($W_FIX vs $W_OFF)" || fail "FIXED 25%: width $W_FIX vs OFF $W_OFF"
screenshot "mouse-pressure-fixed"

# --- 3: SPEED: slow thick, fast thin ---------------------------------------------------
relaunch --option PEN_MOUSE=2 --option PEN_MOUSE_LIGHT=10 --option PEN_MOUSE_FAST_AT=400 --option PEN_MOUSE_SMOOTH=0
YS=$(( Y - 40 )); YF=$(( Y + 40 ))
snap_row $YS "slow-before"; BS=$SNAP_RESULT
stroke $YS 80 60   # ~2 px / 60 ms: barely moving
snap_row $YS "slow-after"; AS=$SNAP_RESULT
snap_row $YF "fast-before"; BF=$SNAP_RESULT
stroke $YF 8 12    # 20 px / 12 ms: a flick
snap_row $YF "fast-after"; AF=$SNAP_RESULT
W_SLOW=$(width "$BS" "$AS" 0.6); W_FAST=$(width "$BF" "$AF" 0.6)
(( ${W_SLOW:-0} > ${W_FAST:-0} + 1 )) && pass "SPEED: a slow stroke is thicker than a fast one ($W_SLOW vs $W_FAST)" || fail "SPEED: slow $W_SLOW vs fast $W_FAST"
screenshot "mouse-pressure-speed"

# --- 4: WHEEL: scroll down mid-stroke ----------------------------------------------------
relaunch --option PEN_MOUSE=3 --option PEN_MOUSE_LEVEL=100 --option PEN_MOUSE_WHEEL_STEP=20
snap_row $Y "wheel-before"; B=$SNAP_RESULT
XM=$CANVAS_CX
SEQ=()
for (( i = 1; i <= 16; i++ )); do read -r ax ay <<< "$(_abs $(( X0 + (XM - X0) * i / 16 )) $Y)"; SEQ+=(move "$ax" "$ay" sleep 25); done
mouse_down $X0 $Y
raw_seq "${SEQ[@]}"; wait_for 0.3 "first half"
for (( i = 1; i <= 4; i++ )); do scroll_down $XM $Y; done
wait_for 0.3 "wheel"
SEQ=()
for (( i = 1; i <= 16; i++ )); do read -r ax ay <<< "$(_abs $(( XM + (X1 - XM) * i / 16 )) $Y)"; SEQ+=(move "$ax" "$ay" sleep 25); done
raw_seq "${SEQ[@]}"; wait_for 0.3 "second half"
mouse_up; wait_for 0.5 "stroke done"
snap_row $Y "wheel-after"; A=$SNAP_RESULT
W_W1=$(width "$B" "$A" 0.25); W_W2=$(width "$B" "$A" 0.8)
(( ${W_W1:-0} > ${W_W2:-0} + 1 )) && pass "WHEEL: the stroke thins after scrolling down ($W_W1 -> $W_W2)" || fail "WHEEL: before the scroll $W_W1, after $W_W2"
screenshot "mouse-pressure-wheel"

# --- 5: TAPER IN / OUT ------------------------------------------------------------------
relaunch --option PEN_MOUSE=1 --option PEN_MOUSE_LEVEL=100 --option PEN_MOUSE_TAPER_IN=50 --option PEN_MOUSE_TAPER_OUT=50
snap_row $Y "taper-before"; B=$SNAP_RESULT
stroke $Y 32 25
snap_row $Y "taper-after"; A=$SNAP_RESULT
W_T0=$(width "$B" "$A" 0.05); W_TM=$(width "$B" "$A" 0.5); W_T1=$(width "$B" "$A" 0.95)
(( ${W_TM:-0} > ${W_T0:-0} + 1 )) && pass "TAPER IN: the stroke grows from a point ($W_T0 -> $W_TM)" || fail "TAPER IN: start $W_T0, middle $W_TM"
(( ${W_TM:-0} > ${W_T1:-0} + 1 )) && pass "TAPER OUT: the stroke ends in a point ($W_TM -> $W_T1)" || fail "TAPER OUT: middle $W_TM, end $W_T1"
screenshot "mouse-pressure-taper"
assert_no_crash

# --- 6: MyPaint ------------------------------------------------------------------------
mp_stroke() { # LABEL - select the MyPaint tool, draw, echo the changed-pixel count
    park_mouse; key question; wait_for 1.5 "command palette"; type_text "MyPaint Brush"; wait_for 1.0 "filtered"; key Return; wait_for 1.5 "the MyPaint tool"
    park_mouse; wait_for 1.0 "palette gone"
    snap_row $Y "mp-$1-before"; local b=$SNAP_RESULT
    stroke $Y 32 25
    snap_row $Y "mp-$1-after"
    MP_PIX=$(pixels "$b" "$SNAP_RESULT")
}
MPOPT="--option MYPAINT_PANEL=TRUE --option MYPAINT_PANEL_SCALE=0 --option MYPAINT_BRUSH=ASSETS/BRUSHES/MYPAINT/classic/pointy_ink.myb --option MYPAINT_SIZE=0 --option MYPAINT_SIZE_FROM_BRUSH=TRUE"
relaunch $MPOPT --option PEN_MOUSE=0
mp_stroke off; MP_OFF=$MP_PIX
relaunch $MPOPT --option PEN_MOUSE=1 --option PEN_MOUSE_LEVEL=15
mp_stroke fixed; MP_FIX=$MP_PIX
(( ${MP_OFF:-0} > 50 )) && pass "MyPaint OFF paints a stroke ($MP_OFF px)" || fail "MyPaint OFF: $MP_OFF px changed (no stroke?)"
(( ${MP_FIX:-0} >= 1 && MP_FIX * 10 <= MP_OFF * 8 )) && pass "MyPaint FIXED 15%: a lighter stroke ($MP_FIX vs $MP_OFF px)" || fail "MyPaint FIXED 15%: $MP_FIX px vs OFF $MP_OFF"
screenshot "mouse-pressure-mypaint"
DRAW_EXTRA_ARGS=""
assert_no_crash
info "=== mouse expression done ==="
