#!/bin/bash
# =============================================================================
# apron-multilayer-ops.sh — move-stamp, Copy to New Layer and multi-layer
# Clear / Move must respect a layer an earlier Move promoted to an apron-extended
# buffer (canvas (x,y) = buffer (x+apronW, y+apronH) - gotcha #14).
#
#  - Alt+release while dragging a float stamps a copy (MOVE_stamp): it wrote at
#    raw canvas coords into the (always promoted) captured layer -> no stamp.
#  - Copy to New Layer: the plain path copies the canvas region; the opacity-lock
#    path walked the promoted buffer as if it had the new layer's row stride ->
#    a skewed copy. A correct copy lands exactly on the original: no visible change.
#  - Multi-layer Clear (CMD_ml_clear) cleared a promoted co-selected layer at raw
#    canvas coords; multi-layer Move treated a promoted sibling as canvas-sized
#    (now demoted at capture, like any non-apron edit).
# Companions: apron-select-after-move.sh, apron-selection-ops.sh.
# =============================================================================

info "=== Apron-promoted layer: stamp, copy to new layer, multi-layer clear / move ==="

canvas_focus b
wait_for 0.3 "Brush ready"
key bracketright
key bracketright
key bracketright
wait_for 0.2 "Brush size"
key grave
wait_for 0.1 "Pointer hidden"

info "Draw content and move it past the right edge (promotes the apron)"
drag $(( CANVAS_CX - 40 )) $CANVAS_CY $(( CANVAS_CX + 40 )) $CANVAS_CY
wait_for 0.3 "Stroke"
key ctrl+a
wait_for 0.5 "Select all"
key v
wait_for 0.3 "Move tool"
drag $CANVAS_CX $CANVAS_CY $(( CANVAS_CX + 120 )) $CANVAS_CY
wait_for 0.5 "Moved right past the edge"
key b
wait_for 0.3 "Brush (commits move)"
key ctrl+d
wait_for 0.2 "Deselect"
key grave
wait_for 0.1 "Pointer hidden"
assert_no_crash

BOX=28
spot() { printf -v "${1}_X" '%s' $(( CANVAS_CX + $2 )); printf -v "${1}_Y" '%s' $(( CANVAS_CY + $3 )); }
spot S -130 -70; spot S1 -90 -70; spot S2 -50 -70           # stamp: source, stamp, final
spot A -130 -20; spot C -130 30;  spot C2 -90 30             # ml clear; ml move from C to C2
spot B  -50 -20                                              # layer-2 mark (stays)
snap() { local x="${1}_X" y="${1}_Y"; snap_region $(( ${!x} - BOX/2 )) $(( ${!y} - BOX/2 )) $BOX $BOX "$2"; }
mark() { local x="${1}_X" y="${1}_Y"; drag $(( ${!x} - 5 )) ${!y} $(( ${!x} + 5 )) ${!y}; wait_for 0.25 "mark $1"; }
rsel() { local x="${1}_X" y="${1}_Y"; key m; wait_for 0.25 "Rect marquee"; drag $(( ${!x} - $2 )) $(( ${!y} - $2 )) $(( ${!x} + $2 )) $(( ${!y} + $2 )); wait_for 0.35 "select $1"; }
LP_HEADER_H=16; LAYER_ENTRY_H=20
row_y() { echo $(( LP_Y + LP_HEADER_H + LAYER_ENTRY_H * ($1 - 1) + LAYER_ENTRY_H / 2 )); }   # 1 = top row

park_mouse
for s in S S1 S2 A C C2 B; do snap $s "ml-$s-blank"; printf -v "BLANK_$s" '%s' "$SNAP_RESULT"; done
info "Paint the layer-1 marks (promoted layer)"
for s in S A C; do mark $s; done
park_mouse
for s in S A C; do snap $s "ml-$s-marked"; printf -v "MARKED_$s" '%s' "$SNAP_RESULT"; done

# -- Move stamp: Alt+release mid-drag stamps a copy ---------------------------
info "Select the mark, drag it and release with Alt held (stamp), drag on, commit"
rsel S 10
key v; wait_for 0.3 "Move tool"
mouse_down $S_X $S_Y
hover $(( (S_X + S1_X) / 2 )) $S_Y; hover $S1_X $S1_Y; sleep 0.15
raw_key down alt; sleep 0.2
mouse_up; sleep 0.2
raw_key up alt; wait_for 0.4 "Alt+release = stamp"
drag $S1_X $S1_Y $S2_X $S2_Y; wait_for 0.4 "drag the float on"
key b; wait_for 0.3 "Brush (commits)"
key ctrl+d; wait_for 0.2 "Deselect"
key grave; wait_for 0.1 "Pointer hidden"
park_mouse
snap S1 "ml-S1-after"
assert_regions_differ "$BLANK_S1" "$SNAP_RESULT" "the Alt-release stamp landed where the float was"
snap S2 "ml-S2-after"
assert_regions_differ "$BLANK_S2" "$SNAP_RESULT" "the float committed where it was dropped"
assert_no_crash

# -- Copy to New Layer (plain, then with opacity lock): exact overlay ---------
# canvas only: the edit bar's Paste icon changes state once the clipboard fills
CV_W=$(( 2 * (CANVAS_CX - CANVAS_OFFSET_X) )); CV_H=$(( 2 * (CANVAS_CY - CANVAS_OFFSET_Y) ))
snap_canvas() { snap_region $CANVAS_OFFSET_X $CANVAS_OFFSET_Y $CV_W $CV_H "$1"; }
park_mouse
snap_canvas "ml-canvas-before"; WORK0="$SNAP_RESULT"
info "Copy to New Layer (no selection) - the copy overlays the original exactly"
key ctrl+alt+c; wait_for 0.5 "Copy to New Layer"
park_mouse
snap_canvas "ml-canvas-copied"
assert_regions_same "$WORK0" "$SNAP_RESULT" "Copy to New Layer reproduced the promoted layer in place" 30
key ctrl+shift+Delete; wait_for 0.4 "Delete the copy layer"
info "Opacity lock on, Copy to New Layer again"
click $(( LP_X + 18 )) "$(row_y 1)"; wait_for 0.3 "Lock opacity (layer 1)"
key ctrl+alt+c; wait_for 0.5 "Copy to New Layer (opacity lock)"
park_mouse
snap_canvas "ml-canvas-copied-locked"
assert_regions_same "$WORK0" "$SNAP_RESULT" \
    "Copy to New Layer under opacity lock reproduced the promoted layer in place (not row-skewed)" 30
key ctrl+shift+Delete; wait_for 0.4 "Delete the copy layer"
click $(( LP_X + 18 )) "$(row_y 1)"; wait_for 0.3 "Unlock opacity (layer 1)"
assert_no_crash

# -- Layer 2 + multi-select both ----------------------------------------------
# A canvas press with any tool but Move clears the multi-selection (by design), so
# each section selects on the canvas FIRST, then Ctrl+clicks layer 1 into the set.
info "New layer 2 with its own mark"
key ctrl+shift+n; wait_for 0.4 "Layer 2"
key b; wait_for 0.2 "Brush"; key grave; wait_for 0.1 "Pointer hidden"
mark B
park_mouse; snap B "ml-B-marked"; MARKED_B="$SNAP_RESULT"
add_layer1() { ctrl_click $(( LP_X + LP_W / 2 )) "$(row_y 2)"; wait_for 0.4 "Layer 1 added to the selection"; }

# -- Multi-layer Clear: layer 1 (promoted, co-selected) is cleared in the box --
info "Rectangle select over the layer-1 mark, Delete (both layers)"
rsel A 10
add_layer1; screenshot "ml-multiselected"
key Delete; wait_for 0.5 "Clear on both layers"
key ctrl+d; wait_for 0.2 "Deselect"
park_mouse
snap A "ml-A-after"
assert_regions_same "$BLANK_A" "$SNAP_RESULT" "multi-layer Clear cleared the promoted co-selected layer where selected" 30
snap B "ml-B-after-clear"
assert_regions_same "$MARKED_B" "$SNAP_RESULT" "layer 2's mark outside the selection survived" 30

# -- Multi-layer Move: the promoted sibling's mark moves with the selection ----
info "Rectangle select over the layer-1 mark, move both layers right"
click $(( LP_X + LP_W / 2 )) "$(row_y 1)"; wait_for 0.3 "Layer 2 only"
rsel C 10
add_layer1
key v; wait_for 0.3 "Move tool"
drag $C_X $C_Y $C2_X $C2_Y; wait_for 0.5 "Moved"
key b; wait_for 0.3 "Brush (commits)"
key ctrl+d; wait_for 0.2 "Deselect"
key grave; wait_for 0.1 "Pointer hidden"
park_mouse
snap C "ml-C-after"
assert_regions_same "$BLANK_C" "$SNAP_RESULT" "multi-layer Move lifted the promoted sibling's mark from where it was" 30
snap C2 "ml-C2-after"
assert_regions_same "$MARKED_C" "$SNAP_RESULT" "multi-layer Move dropped the promoted sibling's mark where it was moved" 60

screenshot "apron-multilayer-ops"
assert_no_crash
assert_window_exists
info "=== apron multi-layer test COMPLETE ==="
