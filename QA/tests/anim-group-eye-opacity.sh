#!/bin/bash
# =============================================================================
# anim-group-eye-opacity.sh — QA test: a group of TWO layers - its eye in the
# Layers panel hides it in the lightbox, and its opacity fades it (field kit
# R-5, 2026-11-09: "Works in X-SHEET but not in layer panel. Opacity doesn't
# work anywhere on the group layer.").
#
# Eye: the panel's group eye kept the "layers below the current one" cache
# (the group's header sits above its children), so the lightbox, which always
# composites, still showed them. anim-lightbox-group.sh has one layer in the
# group and takes a shortcut that never used the cache.
# Opacity: new groups are pass-through, and a pass-through group's opacity was
# never applied. It now composites in its own buffer while below 100%.
#
# Dump: ANIMLBP (per pane: frame dx dy dw dh), ANIM.
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3
# =============================================================================
info "=== Animation: a two-layer group's eye and opacity in the lightbox ==="

GE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
GE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
GE_DIR="/tmp/draw-qa-groupeye-$$"
mkdir -p "$GE_DIR"
magick -size 64x16 xc:none -fill '#c04040' -draw 'rectangle 1,1 14,14' -fill '#40c040' -draw 'rectangle 17,1 30,14' \
    -fill '#4040c0' -draw 'rectangle 33,1 46,14' -fill '#c0c040' -draw 'rectangle 49,1 62,14' "PNG32:$GE_DIR/plain.png"
GE_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,2,12,0,0).hex())")
python3 "$GE_PY" put "$GE_DIR/plain.png" "$GE_DIR/sheet.png" drAn "$GE_BLOB"

ge_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2; }
ge_pane() { # LABEL -> $SNAP_RESULT: the current frame's pane picture
    ge_settle
    local p k; p=($(grep -m1 '^ANIMLBP ' "$GE_DUMP")); PX=""
    read -r _ _ _ A_CUR _ <<< "$(grep -m1 '^ANIM ' "$GE_DUMP")"
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; }
    done
    [[ -z "$PX" ]] && { fail "$1: no pane for frame $A_CUR"; return 1; }
    snap_region "$PX" "$PY" "$PW" "$PH" "$1"
}
ge_eye() { click $(( LP_X + 18 )) $(( LP_Y + 16 + 10 )); wait_for 0.6 "group eye"; } # row 0 = the group
GE_OPX=$(( LP_X + LP_W - 14 )); GE_OPY=$(( LP_Y + 25 ))  # row 0's opacity bar

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$GE_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key b; wait_for 0.3 "Brush"
park_mouse; key ctrl+shift+g; wait_for 0.8 "Group from the layer"
click $(( LP_X + 60 )) $(( LP_Y + 16 + 20 + 10 )); wait_for 0.6 "the group's layer"  # row 1 = the layer in it
park_mouse; key ctrl+shift+n; wait_for 0.8 "a second layer in the group"
park_mouse; key KP_0; wait_for 0.8 "Lightbox"

ge_pane "groupeye-shown" && cp "$SNAP_RESULT" "$GE_DIR/shown.png"
ge_eye
ge_pane "groupeye-hidden" && cp "$SNAP_RESULT" "$GE_DIR/hidden.png"
ge_eye
ge_pane "groupeye-again" && cp "$SNAP_RESULT" "$GE_DIR/again.png"
if [[ -f "$GE_DIR/shown.png" && -f "$GE_DIR/hidden.png" && -f "$GE_DIR/again.png" ]]; then
    assert_regions_differ "$GE_DIR/shown.png" "$GE_DIR/hidden.png" "the panel's group eye off (2 layers in it, a child current): the drawing leaves the pane"
    assert_regions_same "$GE_DIR/shown.png" "$GE_DIR/again.png" "the group's eye on again: the pane shows it as before" 0
fi

# -- the group's opacity (a pass-through group) --
for n in 1 2 3 4 5 6; do scroll_down "$GE_OPX" "$GE_OPY"; done
wait_for 0.5 "group opacity down"
ge_pane "groupeye-faded" && cp "$SNAP_RESULT" "$GE_DIR/faded.png"
if [[ -f "$GE_DIR/shown.png" && -f "$GE_DIR/faded.png" ]]; then
    assert_regions_differ "$GE_DIR/shown.png" "$GE_DIR/faded.png" "the group's opacity turned down: its drawing fades in the pane"
fi
for n in 1 2 3 4 5 6; do scroll_up "$GE_OPX" "$GE_OPY"; done
wait_for 0.5 "group opacity up"
ge_pane "groupeye-full" && cp "$SNAP_RESULT" "$GE_DIR/full.png"
[[ -f "$GE_DIR/full.png" ]] && assert_regions_same "$GE_DIR/shown.png" "$GE_DIR/full.png" "the group's opacity back to 100%: as before" 0
screenshot "anim-group-eye-opacity"
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$GE_DIR"
assert_window_exists
