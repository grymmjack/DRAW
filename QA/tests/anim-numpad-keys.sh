#!/bin/bash
# =============================================================================
# anim-numpad-keys.sh — QA test: the frame keys (numpad + laptop keys).
#
# Animation 1.4 (PLANS/ANIMATION.md, Rick's sketch: "seek bar keys are on
# numpad"): on a sheet with frames, numpad 1 / 4 / 5 / 9 go to the first /
# previous / next / last frame, with Num Lock on or off, held or tapped.
# Laptop keys: Alt+Home / Alt+, / Alt+. / Alt+End. The main-row digits still
# set the paint opacity (numpad 4 must not), Alt+Home does not also flip,
# and a picture without frames keeps the numpad digits as opacity keys.
#
# State comes from the QA dump: ANIM (... current ...) and PAINT (opacity).
# Fixture: the 64x32 sheet of anim-frame-grid.sh - 16x16 frames, 7 frames,
# current 3, a red square at canvas (20,4)-(27,11).
#
# QA-OPTIONS: DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: frame keys (numpad, Alt) ==="

NK_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
NK_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
NK_DIR="/tmp/draw-qa-numpad-$$"
mkdir -p "$NK_DIR"
magick -size 64x32 xc:'#204060' -fill '#c04040' -draw 'rectangle 20,4 27,11' "$NK_DIR/plain.png"
NK_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$NK_PY" put "$NK_DIR/plain.png" "$NK_DIR/sheet.png" drAn "$NK_BLOB"

nk_field() { # KEY N -> field N of that dump line (after a couple of drawn frames)
    { hover 300 250; wait_for 0.2 "render"; hover 305 252; wait_for 0.3 "render"; } >&2
    grep -m1 "^$1 " "$NK_DUMP" 2>/dev/null | awk -v n="$2" '{print $(n+1)}'
}
nk_cur() { nk_field ANIM 3; }
nk_opacity() { nk_field PAINT 1; }
numlock_on() { xset -display "$DISPLAY" q 2>/dev/null | grep -q "Num Lock: *on"; }
set_numlock() { # on | off
    if [[ "$1" == on ]]; then numlock_on || xdotool key Num_Lock; else numlock_on && xdotool key Num_Lock; fi
    sleep 0.3
}
nk_press() { # KEYSYM hold|tap
    park_mouse
    if [[ "$1" == *+* ]]; then key "$1"      # a chord: the harness holds the modifier first
    elif [[ "$2" == hold ]]; then xdotool keydown "$1"; sleep 0.15; xdotool keyup "$1"
    else xdotool key "$1"; fi                # xdotool's instant tap, quicker than a frame
    wait_for 0.3 "$1 ($2)"
}
nk_expect() { # KEYSYM HOW WANT_FRAME LABEL
    nk_press "$1" "$2"
    local got; got=$(nk_cur)
    [[ "$got" == "$3" ]] && pass "$4: frame $3" || fail "$4: frame '$got', wanted $3"
}

info "Launching DRAW with a 64x32 sheet of 16x16 frames (current 3)"
draw_quit
draw_settle # a small file loads fast enough to race the old window (see draw_settle)
DRAW_EXTRA_ARGS="$NK_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key ctrl+0
wait_for 0.5 "Zoom 100%"
NK_C=$(nk_cur)
[[ "$NK_C" == 3 ]] && pass "the sheet opened on frame 3" || fail "the sheet opened on frame '$NK_C', wanted 3"

key 0                               # main-row 0: opacity 100%
wait_for 0.3 "Opacity 100%"
NK_O0=$(nk_opacity)
[[ "$NK_O0" == 100 ]] && pass "main-row 0 sets opacity 100%" || fail "main-row 0: opacity '$NK_O0', wanted 100"

# -- Num Lock on: KP_4 / KP_5 are digits as well --
set_numlock on
nk_expect KP_4 hold 2 "Num Lock on, numpad 4 held"
nk_expect KP_4 tap 1 "Num Lock on, numpad 4 tapped"
nk_expect KP_4 tap 7 "numpad 4 from frame 1 wraps to the last"
nk_expect KP_5 hold 1 "numpad 5 from the last wraps to frame 1"
nk_expect KP_5 tap 2 "Num Lock on, numpad 5 tapped"
nk_expect KP_9 hold 7 "Num Lock on, numpad 9"
nk_expect KP_1 tap 1 "Num Lock on, numpad 1"
NK_O=$(nk_opacity)
[[ "$NK_O" == 100 ]] && pass "the numpad digits left the opacity alone (100%)" \
    || fail "a numpad digit changed the opacity to '$NK_O'%"

# -- Num Lock off: the same keys send End / Left / Begin / PgUp --
set_numlock off
nk_expect KP_Prior hold 7 "Num Lock off, numpad 9 (PgUp)"
nk_expect KP_Left hold 6 "Num Lock off, numpad 4 (Left)"
nk_expect KP_Begin tap 7 "Num Lock off, numpad 5 tapped"
nk_expect KP_End hold 1 "Num Lock off, numpad 1 (End)"
set_numlock on

# -- main-row digits still set opacity, and do not move the frame --
key 4
wait_for 0.3 "Main-row 4"
NK_O=$(nk_opacity); NK_C=$(nk_cur)
[[ "$NK_O" == 40 ]] && pass "main-row 4 still sets opacity 40%" || fail "main-row 4: opacity '$NK_O', wanted 40"
[[ "$NK_C" == 1 ]] && pass "main-row 4 did not change the frame" || fail "main-row 4 moved to frame '$NK_C'"
key 0
wait_for 0.3 "Opacity 100%"

# -- laptop keys --
# the red square's inside (canvas 22-26, 8-10): Alt+Home must not also flip it
NK_DX=$(nk_field ANIM 13); NK_DY=$(nk_field ANIM 14); NK_Z=$(nk_field VIEW 1)
NK_SX=$(( NK_DX + 22 * NK_Z / 100 )); NK_SY=$(( NK_DY + 8 * NK_Z / 100 ))
park_mouse
snap_region "$NK_SX" "$NK_SY" 4 3 "nk-square-before"; NK_SQ="$SNAP_RESULT"
nk_press alt+period tap
NK_C=$(nk_cur); [[ "$NK_C" == 2 ]] && pass "Alt+. : next frame (2)" || fail "Alt+. : frame '$NK_C', wanted 2"
nk_press alt+End tap
NK_C=$(nk_cur); [[ "$NK_C" == 7 ]] && pass "Alt+End : last frame (7)" || fail "Alt+End : frame '$NK_C', wanted 7"
nk_press alt+comma tap
NK_C=$(nk_cur); [[ "$NK_C" == 6 ]] && pass "Alt+, : previous frame (6)" || fail "Alt+, : frame '$NK_C', wanted 6"
nk_press alt+Home tap
NK_C=$(nk_cur); [[ "$NK_C" == 1 ]] && pass "Alt+Home : first frame (1)" || fail "Alt+Home : frame '$NK_C', wanted 1"
park_mouse
snap_region "$NK_SX" "$NK_SY" 4 3 "nk-square-after"
assert_regions_same "$NK_SQ" "$SNAP_RESULT" "Alt+Home / Alt+End did not flip the canvas" 3

# -- a picture without frames: numpad digits stay opacity keys --
info "Relaunching with the same picture, no frames"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$NK_DIR/plain.png"
draw_launch 15
wait_for 1.5 "Picture loaded"
set_numlock on
nk_press KP_4 hold
NK_O=$(nk_opacity)
[[ "$NK_O" == 40 ]] && pass "no frames: numpad 4 still sets opacity 40%" || fail "no frames: numpad 4 gave opacity '$NK_O', wanted 40"

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$NK_DIR"
assert_window_exists
