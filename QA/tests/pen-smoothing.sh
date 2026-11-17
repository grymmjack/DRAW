#!/bin/bash
# =============================================================================
# pen-smoothing.sh — QA test: Pen Control position smoothing (Rick 2026-11-17,
# "add stabilization like lazy nezumi"). Smoothing works for the mouse too,
# so Xvfb's pointer drives it; pressure processing / speed scaling need a pen
# and are covered by QA/unit/stab-unit.bas.
#   1 a zig-zag drag draws differently with Moving Average smoothing on
#   2 EMA 90 + Catch Up: a fast drag's stroke reaches where the pointer let go
#   3 EMA 90, Catch Up off: the same drag stops short of it
#   4 the guide line (drawing point -> pointer) shows while the stroke lags,
#     and is gone after the release
# Each case relaunches with its --option set (CFG is read at every stroke).
# QA-OPTIONS: WORKSPACE=default TOOLTIPS_DISABLED=TRUE HELP_CARD_ENABLED=FALSE
# =============================================================================
info "=== Pen Control: position smoothing ==="

relaunch() { # --option args...
    draw_quit; draw_settle
    DRAW_EXTRA_ARGS="$*"
    draw_launch 15; wait_for 1.5 "DRAW up ($*)"
    canvas_focus b; wait_for 0.3 "brush"
    key grave; wait_for 0.1 "pointer arrow hidden"
}
zigzag() { # X0 Y0 - a 120 px wide zig-zag, +-8 px
    local i x y
    mouse_down "$1" "$2"
    for (( i = 1; i <= 24; i++ )); do
        x=$(( $1 + i * 5 )); y=$(( $2 + ( (i % 2) * 2 - 1 ) * 8 ))
        hover "$x" "$y"; sleep 0.02
    done
    mouse_up; wait_for 0.4 "stroke done"
}
fast_line() { # X0 X1 Y - a quick drag, released at once at X1
    local i x
    mouse_down "$1" "$3"
    for (( i = 1; i <= 6; i++ )); do x=$(( $1 + ($2 - $1) * i / 6 )); hover "$x" "$3"; sleep 0.01; done
    mouse_up; wait_for 0.5 "stroke done"
}

ZX=$(( CANVAS_CX - 60 )); ZY=$(( CANVAS_CY - 30 ))
LX0=$(( CANVAS_CX - 70 )); LX1=$(( CANVAS_CX + 70 )); LY=$(( CANVAS_CY + 30 ))

# --- 1: smoothing changes a jittery stroke ---------------------------------------
relaunch
park_mouse; zigzag $ZX $ZY
park_mouse; snap_region $(( ZX - 4 )) $(( ZY - 12 )) 128 24 "zigzag-raw"; RAW=$SNAP_RESULT
relaunch --option PEN_STAB=TRUE --option PEN_STAB_MODE=2 --option PEN_STAB_AMOUNT=60
park_mouse; zigzag $ZX $ZY
park_mouse; snap_region $(( ZX - 4 )) $(( ZY - 12 )) 128 24 "zigzag-smooth"; SMO=$SNAP_RESULT
assert_regions_differ "$RAW" "$SMO" "a zig-zag drag draws differently with Moving Average smoothing"
assert_no_crash

# --- 2: EMA + Catch Up reaches the end -------------------------------------------
relaunch --option PEN_STAB=TRUE --option PEN_STAB_MODE=3 --option PEN_STAB_AMOUNT=90 --option PEN_STAB_CATCHUP=TRUE
park_mouse; snap_region $(( LX1 - 4 )) $(( LY - 4 )) 8 8 "end-before"; EB=$SNAP_RESULT
fast_line $LX0 $LX1 $LY
park_mouse; snap_region $(( LX1 - 4 )) $(( LY - 4 )) 8 8 "end-catchup"; EC=$SNAP_RESULT
assert_regions_differ "$EB" "$EC" "EMA + Catch Up: the stroke reaches where the pointer let go"
screenshot "pen-smoothing-catchup"

# --- 3: Catch Up off stops short ---------------------------------------------------
relaunch --option PEN_STAB=TRUE --option PEN_STAB_MODE=3 --option PEN_STAB_AMOUNT=90 --option PEN_STAB_CATCHUP=FALSE
park_mouse; snap_region $(( LX1 - 4 )) $(( LY - 4 )) 8 8 "end-before2"; EB2=$SNAP_RESULT
fast_line $LX0 $LX1 $LY
park_mouse; snap_region $(( LX1 - 4 )) $(( LY - 4 )) 8 8 "end-nocatch"; EN=$SNAP_RESULT
assert_regions_same "$EB2" "$EN" "EMA without Catch Up: the stroke stops short of the release point" 2
screenshot "pen-smoothing-nocatch"

# --- 4: the guide line while the stroke lags ---------------------------------------
GY=$(( CANVAS_CY + 60 )); GX0=$(( CANVAS_CX - 70 )); GX1=$(( CANVAS_CX + 70 )); GM=$CANVAS_CX
park_mouse; snap_region $(( GM - 3 )) $(( GY - 3 )) 6 6 "guide-before"; GB=$SNAP_RESULT
mouse_down $GX0 $GY
for (( i = 1; i <= 6; i++ )); do hover $(( GX0 + (GX1 - GX0) * i / 6 )) $GY; sleep 0.01; done
sleep 0.05
snap_region $(( GM - 3 )) $(( GY - 3 )) 6 6 "guide-held"; GH=$SNAP_RESULT
mouse_up; wait_for 0.5 "released"
park_mouse; snap_region $(( GM - 3 )) $(( GY - 3 )) 6 6 "guide-after"; GA=$SNAP_RESULT
assert_regions_differ "$GB" "$GH" "the guide line crosses the gap while the stroke lags"
assert_regions_same "$GB" "$GA" "the guide is gone after the release (and the stroke stopped short)" 2
DRAW_EXTRA_ARGS=""
assert_no_crash
info "=== Pen Control smoothing done ==="
