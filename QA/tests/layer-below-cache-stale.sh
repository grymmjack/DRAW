#!/bin/bash
# =============================================================================
# layer-below-cache-stale.sh — QA test: a fill or stroke on a lower layer stays
# on screen after a higher layer is selected.
#
# Rick 2026-11-10: "i am trying to draw or fill a background layer, and it
# fills it, but then when i choose a text layer above, it unfills it". The
# composite of the layers under the current one (COMPOSITE_BELOW_CACHE) was
# built while the text layer was current; painting the background with the
# background current never dropped it, so selecting the text layer again
# brought the old composite back. The pixels were on the layer all along
# (selecting the background again showed them).
# - a text layer over the background; select the background, fill: it shows;
#   select the text layer: the fill still shows (exactly: tolerance 0)
# - the same with a brush stroke on the background
# Builds before: both vanished on selecting the text layer.
#
# Dump: P layers (the panel's box: 16 px header, 20 px rows, top layer first).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt LAYER_THUMBNAILS=0
# =============================================================================
info "=== Layers: an edit below the current layer stays on screen ==="
LB_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
lb_snap() { park_mouse; wait_for 0.3 "settle"; snap_region $(( CANVAS_CX + 10 )) $(( CANVAS_CY + 15 )) 50 30 "$1"; }

canvas_focus b; wait_for 0.3 "Brush"
key t; wait_for 0.3 "Text tool"
click $(( CANVAS_CX - 30 )) $(( CANVAS_CY - 30 )); wait_for 0.3 "Caret"
type_text "ABC"; wait_for 0.4 "Typed"
key Escape; wait_for 0.5 "Text committed"
key b; wait_for 0.3 "Brush"
{ hover 300 250; wait_for 0.3 "render"; } >&2
read -r _ _ _ _ LX LY LW LH _ <<< "$(grep -m1 '^P layers ' "$LB_DUMP")"
RX=$(( LX + LW / 2 + 10 )); TXY=$(( LY + 16 + 10 )); BGY=$(( LY + 16 + 20 + 10 ))
info "layers panel at $LX,$LY ${LW}x$LH: text row y $TXY, background row y $BGY"

# -- fill --
lb_snap "lb-empty"; E="$SNAP_RESULT"
click "$RX" "$BGY"; wait_for 0.5 "Select the background"
key f; wait_for 0.3 "Fill tool"
click $(( CANVAS_CX + 35 )) $(( CANVAS_CY + 30 )); wait_for 0.8 "Fill the background"
lb_snap "lb-filled"; F="$SNAP_RESULT"
assert_regions_differ "$E" "$F" "the fill shows on the background"
click "$RX" "$TXY"; wait_for 0.8 "Select the text layer"
lb_snap "lb-filled-text-current"
assert_regions_same "$F" "$SNAP_RESULT" "the fill still shows with the text layer current" 0

# -- brush stroke --
key ctrl+z; wait_for 0.6 "Undo the fill"
click "$RX" "$BGY"; wait_for 0.5 "Select the background"
key b; wait_for 0.3 "Brush"
lb_snap "lb-before-stroke"; E="$SNAP_RESULT"
drag $(( CANVAS_CX + 15 )) $(( CANVAS_CY + 30 )) $(( CANVAS_CX + 55 )) $(( CANVAS_CY + 30 )); wait_for 0.5 "Stroke on the background"
lb_snap "lb-stroked"; S="$SNAP_RESULT"
assert_regions_differ "$E" "$S" "the stroke shows on the background"
click "$RX" "$TXY"; wait_for 0.8 "Select the text layer"
lb_snap "lb-stroked-text-current"
assert_regions_same "$S" "$SNAP_RESULT" "the stroke still shows with the text layer current" 0
screenshot "layer-below-cache"

assert_no_crash
assert_window_exists
