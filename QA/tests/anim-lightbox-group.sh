#!/bin/bash
# =============================================================================
# anim-lightbox-group.sh — QA test: a group's eye in the layer panel shows in
# the lightbox panes.
#
# Rick, 2026-11-08 (field kit T-22): "group eyeball / opacity in the layer
# panel doesn't update the lightbox" (a layer's eye did). The lightbox cuts its
# panes from the composite; with one drawn layer inside a pass-through group,
# the render took its one-visible-layer shortcut, which looked at the layer's
# own eye only and ignored the group's.
#
# Dump: ANIMLBP (per pane: frame dx dy dw dh), ANIM.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3
# =============================================================================
info "=== Animation: a group's eye in the lightbox ==="

LG_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LG_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LG_DIR="/tmp/draw-qa-lbgroup-$$"
mkdir -p "$LG_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 1,1 14,14' -fill '#40c040' -draw 'rectangle 17,1 30,14' \
    -fill '#4040c0' -draw 'rectangle 33,1 46,14' -fill '#c0c040' -draw 'rectangle 49,1 62,14' "PNG32:$LG_DIR/plain.png"
LG_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,2,12,0,0).hex())")
python3 "$LG_PY" put "$LG_DIR/plain.png" "$LG_DIR/sheet.png" drAn "$LG_BLOB"

lg_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2; }
lg_pane() { # LABEL -> $SNAP_RESULT: the current frame's pane picture
    lg_settle
    local p k; p=($(grep -m1 '^ANIMLBP ' "$LG_DUMP")); PX=""
    read -r _ _ _ A_CUR _ <<< "$(grep -m1 '^ANIM ' "$LG_DUMP")"
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; }
    done
    [[ -z "$PX" ]] && { fail "$1: no pane for frame $A_CUR"; return 1; }
    snap_region "$PX" "$PY" "$PW" "$PH" "$1"
}
lg_eye() { click $(( LP_X + 18 )) $(( LP_Y + 16 + 10 )); wait_for 0.6 "group eye"; } # row 0 = the group

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LG_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key b; wait_for 0.3 "Brush"
park_mouse; key ctrl+shift+g; wait_for 0.8 "Group from the layer"
park_mouse; key KP_0; wait_for 0.8 "Lightbox"

lg_pane "lbgroup-shown" && cp "$SNAP_RESULT" "$LG_DIR/shown.png"
lg_eye
lg_pane "lbgroup-hidden" && cp "$SNAP_RESULT" "$LG_DIR/hidden.png"
lg_eye
lg_pane "lbgroup-again" && cp "$SNAP_RESULT" "$LG_DIR/again.png"
if [[ -f "$LG_DIR/shown.png" && -f "$LG_DIR/hidden.png" && -f "$LG_DIR/again.png" ]]; then
    assert_regions_differ "$LG_DIR/shown.png" "$LG_DIR/hidden.png" "the group's eye off: its frame drawing leaves the pane"
    assert_regions_same "$LG_DIR/shown.png" "$LG_DIR/again.png" "the group's eye on again: the pane shows it as before" 0
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LG_DIR"
assert_window_exists
