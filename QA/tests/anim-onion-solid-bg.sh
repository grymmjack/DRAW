#!/bin/bash
# =============================================================================
# anim-onion-solid-bg.sh — QA test: onion skin on frames with a solid,
# two-colour background (field kit R-3, 2026-11-09: "Onion skin isn't working
# at all on SAMPLES/ANIMATION/bounce-ball.png -- it used to. Even the solid
# background frames would show some red/blue.").
#
# bounce-ball.png's frames are sky over a strip of ground: the corners are two
# sky and two ground, so the old "3 or 4 corners" background test found none,
# and the ghosts (which go only where the current frame is empty or its own
# background - T-13) had nowhere to show: 0 / 0 pixels. The background is now
# the colour covering most of the cell's edge (the sky), so the frames before /
# after show where the current frame is sky.
#
# Dump: ANIMLBO on before after opacity tint prevPx nextPx; ANIM.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=1 ONION_BEFORE=1 ONION_AFTER=1
# =============================================================================
info "=== Onion skin on a solid two-colour background (bounce-ball) ==="

OS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
OS_DIR="/tmp/draw-qa-onionsolid-$$"
mkdir -p "$OS_DIR"
cp "$DRAW_ROOT/SAMPLES/ANIMATION/bounce-ball.png" "$OS_DIR/bounce-ball.png"

os_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
os_line() { grep -m1 "^$1 " "$OS_DUMP" 2>/dev/null; }
os_read() {
    os_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(os_line ANIM)"
    read -r _ O_ON O_B O_A O_OP O_TINT O_PREV O_NEXT _ <<< "$(os_line ANIMLBO)"
    read -r _ LB_SHOWN _ <<< "$(os_line ANIMLB)"
}
os_key() { park_mouse; key "$1"; wait_for 0.5 "$1"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$OS_DIR/bounce-ball.png"
draw_launch 15
wait_for 1.5 "bounce-ball loaded"
assert_no_crash
os_read
[[ "${LB_SHOWN:-}" == -1 ]] || { os_key KP_0; os_read; }
for (( n = 0; n < 8 && A_CUR != 4; n++ )); do os_key KP_5; os_read; done
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 8 || "$A_CUR" != 4 ]]; then
    fail "lightbox on frame 4 of 8: shown '${LB_SHOWN:-}', frames '$A_COUNT', current '$A_CUR'"
else
    pass "bounce-ball: lightbox on frame 4 of 8"
    [[ "$O_ON" == -1 ]] || fail "onion skin is off: $O_ON"
    (( ${O_PREV:-0} > 5 && ${O_NEXT:-0} > 5 )) && pass "frames 3 and 5 show over frame 4's sky: $O_PREV / $O_NEXT pixels" \
        || fail "onion skin on the sky-over-ground frames: $O_PREV / $O_NEXT ghost pixels (the old build found no background: 0 / 0)"
fi
screenshot "anim-onion-solid-bg"
assert_no_crash
rm -rf "$OS_DIR"
