#!/bin/bash
# =============================================================================
# anim-onion-painted-bg.sh — QA test: onion skin over a PAINTED background
# (reported 2026-11-11: stamping an AnimBrush frame by frame over a scene, the
# frame before showed no onion skin on the current frame).
#
# The ghosts go behind the current drawing (T-13): once only where the
# flattened frame was empty or one flat background colour. A painted scene has
# neither, so nothing ever showed. Now it is decided per layer: a layer that is
# the same in both frames (the background, Layer Same on Every Frame) neither
# ghosts nor hides a ghost.
#   - castle-night.draw (a dithered sky, stars / flags / torches / bat / ghost
#     on their own layers): frames 4 and 6 show over frame 5
#   - castle-night-base.png with the background Same on Every Frame (nothing
#     moves): no ghosts - a static scene stays clear
#
# Dump: ANIMLBO on before after opacity tint prevPx nextPx; ANIM; ANIMLB.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=1 ONION_BEFORE=1 ONION_AFTER=1 LIGHTBOX=0 XSHEET=0
# =============================================================================
info "=== Onion skin over a painted background ==="

OP_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
OP_DIR="/tmp/draw-qa-onionpainted-$$"
mkdir -p "$OP_DIR"
cp "$DRAW_ROOT/SAMPLES/ANIMBRUSH/scenes/castle-night.draw" "$DRAW_ROOT/SAMPLES/ANIMBRUSH/scenes/castle-night-base.png" "$OP_DIR/"

op_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
op_line() { grep -m1 "^$1 " "$OP_DUMP" 2>/dev/null; }
op_read() {
    op_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(op_line ANIM)"
    read -r _ O_ON O_B O_A O_OP O_TINT O_PREV O_NEXT _ <<< "$(op_line ANIMLBO)"
    read -r _ LB_SHOWN _ <<< "$(op_line ANIMLB)"
}
op_key() { park_mouse; key "$1"; wait_for 0.5 "$1"; }
op_open() { # FILE
    draw_quit; draw_settle
    DRAW_EXTRA_ARGS="$1"
    draw_launch 15; wait_for 1.5 "loaded"; assert_no_crash
    op_read
    [[ "${LB_SHOWN:-}" == -1 ]] || { op_key KP_0; op_read; }
    for (( n = 0; n < 8 && A_CUR != 5; n++ )); do op_key KP_5; op_read; done
}

op_open "$OP_DIR/castle-night.draw"
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 24 || "$A_CUR" != 5 ]]; then
    fail "castle: lightbox on frame 5 of 24: shown '${LB_SHOWN:-}', frames '$A_COUNT', current '$A_CUR'"
else
    [[ "$O_ON" == -1 ]] || fail "onion skin is off: $O_ON"
    (( ${O_PREV:-0} > 20 && ${O_NEXT:-0} > 20 )) && pass "castle: frames 4 and 6 show over frame 5's painted sky: $O_PREV / $O_NEXT pixels" \
        || fail "castle: $O_PREV / $O_NEXT ghost pixels over a painted background (the old build: 0 / 0)"
    screenshot "anim-onion-painted-bg"
fi

op_open "$OP_DIR/castle-night-base.png"
if [[ "$A_COUNT" != 24 ]]; then
    fail "base: $A_COUNT frames"
else
    op_key KP_1; op_read                         # frame 1: the background is drawn there
    park_mouse; key question; wait_for 1.0 "palette"; type_text "same on every"; wait_for 1.6 "filtered"; key Return; wait_for 1.0 "same"
    for (( n = 0; n < 8 && A_CUR != 5; n++ )); do op_key KP_5; op_read; done
    [[ "$A_CUR" == 5 && "${O_PREV:-x}" == 0 && "${O_NEXT:-x}" == 0 ]] && pass "a background Same on Every Frame: no ghosts (frame $A_CUR: $O_PREV / $O_NEXT)" \
        || fail "static background: frame $A_CUR shows $O_PREV / $O_NEXT ghost pixels (wanted 0 / 0)"
fi
assert_no_crash
rm -rf "$OP_DIR"
