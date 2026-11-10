#!/bin/bash
# =============================================================================
# layer-thumbnails.sh — QA test: thumbnails in the Layers panel (Rick
# 2026-11-09, field kit R-13: "layer thumbnails with sizes in the layer pane
# ... if we could have the thumbnails have tiny, small, and med sizes?").
#
# LAYER_THUMBNAILS = OFF / TINY (16 px) / SMALL (32 px) / MEDIUM (48 px), set
# in Settings > Panels. A row holds the thumbnail (SMALL: 36 px rows) with the
# layer's picture fitted on a checkerboard, before the name. The old build
# ignored the option: 20 px rows, no picture.
#
# Fixture: a 32x32 solid red sheet. Row 0 = the top layer.
# QA-OPTIONS: WORKSPACE=default LAYER_THUMBNAILS=SMALL
# =============================================================================
info "=== Layers panel thumbnails (SMALL) ==="

LT_DIR="/tmp/draw-qa-layerthumbs-$$"
mkdir -p "$LT_DIR"
magick -size 32x32 xc:'#e02020' "PNG32:$LT_DIR/red.png"

LT_ROW=36           # SMALL: 32 px thumbnail + 4
LT_TOP=$(( LP_Y + 16 ))
lt_red() { # PNG -> the % of its pixels that are red
    magick "$1" -fuzz 12% -fill white -opaque '#e02020' -fill black +opaque white -colorspace gray -format '%[fx:round(mean*100)]' info: 2>/dev/null
}
lt_row() { # ROW LABEL -> $SNAP_RESULT: the thumbnail box of that row
    { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2
    snap_region $(( LP_X + 3 + 21 )) $(( LT_TOP + $1 * LT_ROW + 2 )) 32 32 "$2"
}

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LT_DIR/red.png"
draw_launch 15
wait_for 1.5 "red.png loaded"
assert_no_crash

lt_row 0 "thumb-row0"
N=$(lt_red "$SNAP_RESULT")
(( ${N:-0} >= 70 )) && pass "row 0 shows the red layer's thumbnail ($N% red)" || fail "row 0 thumbnail: ${N:-?}% red, wanted >= 70%"

park_mouse; key ctrl+shift+n; wait_for 0.8 "a new empty layer on top"
lt_row 0 "thumb-new-row0"
N0=$(lt_red "$SNAP_RESULT")
lt_row 1 "thumb-new-row1"
N1=$(lt_red "$SNAP_RESULT")
(( ${N0:-999} < 5 && ${N1:-0} >= 70 )) \
    && pass "a new empty layer: row 0 shows no red ($N0%), the red layer moved one 36 px row down ($N1%)" \
    || fail "after a new layer: row 0 ${N0:-?}% red (want < 5%), row 1 ${N1:-?}% (want >= 70%)"

screenshot "layer-thumbnails"
assert_no_crash
rm -rf "$LT_DIR"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
