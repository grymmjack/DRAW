#!/bin/bash
# =============================================================================
# anim-fullscreen.sh — QA test: the full-screen Preview (Animation 3.6,
# TOOLS/ANIM-FS ANIM_FS_show, Num . / ANIM > Full-Screen Preview).
#
# Num . opens the frames playing over the whole window (its own loop); SPACE
# pauses / plays, LEFT / RIGHT step, HOME / END first / last, a click or drag
# on the seek bar scrubs, the wheel zooms about the pointer, a double middle
# click is 100%, a middle drag pans, ESC closes on the frame shown. What it
# shows is checked on screen: the colour at the middle of the frame is that
# frame's colour.
#
# Dump: ANIMFS open step frame playing zoom% x y w h barX barY barW barH steps
# (only while open; logical px), ANIM (current frame after it closes).
# Fixture: a 64x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour (the frame's middle pixel is inside it); 4 frames at 4 fps,
# forward, current 2.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: full-screen Preview ==="

FS_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
FS_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
FS_DIR="/tmp/draw-qa-fullscreen-$$"
mkdir -p "$FS_DIR"
FS_DRAW=()
FS_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 3 + n ))
    FS_DRAW+=(-fill "#${FS_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 64x16 xc:none "${FS_DRAW[@]}" "PNG32:$FS_DIR/plain.png"
FS_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,2,4,0,0).hex())")
python3 "$FS_PY" put "$FS_DIR/plain.png" "$FS_DIR/sheet.png" drAn "$FS_BLOB"

fs_line() { grep -m1 "^$1 " "$FS_DUMP" 2>/dev/null; }
fs_read() { # FS_OPEN FS_K FS_F FS_PLAY FS_Z FS_X FS_Y FS_W FS_H FS_BX FS_BY FS_BW FS_BH FS_N (empty when closed), A_CUR
    sleep 0.25
    FS_OPEN=""; FS_K=""; FS_F=""; FS_PLAY=""; FS_Z=""
    read -r _ FS_OPEN FS_K FS_F FS_PLAY FS_Z FS_X FS_Y FS_W FS_H FS_BX FS_BY FS_BW FS_BH FS_N _ <<< "$(fs_line ANIMFS)"
    read -r _ _ A_COUNT A_CUR _ <<< "$(fs_line ANIM)"
}
fs_s() { echo "open '${FS_OPEN:-}' step ${FS_K:-?}/${FS_N:-?} frame ${FS_F:-?} playing ${FS_PLAY:-?} zoom ${FS_Z:-?}% at ${FS_X:-?},${FS_Y:-?} ${FS_W:-?}x${FS_H:-?}"; }
fs_colour() { # the colour (hex) on screen at the middle of the frame shown
    local x y
    x=$(( FS_X + (15 * FS_W) / 32 )); y=$(( FS_Y + (15 * FS_H) / 32 )) # frame pixel (7.5, 7.5)
    snap_region "$x" "$y" 1 1 "fs_px" >/dev/null
    magick "${SNAP_RESULT:-/nonexistent}" -format '%[hex:p{0,0}]' info: 2>/dev/null | cut -c1-6 | tr 'A-F' 'a-f'
}
fs_shows() { [[ "$(fs_colour)" == "${FS_COLORS[$(( $1 - 1 ))]}" ]]; } # FRAME -> its colour is on screen
fs_key() { key "$1"; sleep 0.35; }

info "Launching DRAW with a 64x16 sheet of 16x16 frames (4 at 4 fps, current 2)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$FS_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key KP_Decimal
wait_for 0.6 "Full-screen Preview"
fs_read
if [[ "$FS_OPEN" != -1 || "$FS_N" != 4 ]]; then
    fail "Num . did not open the full-screen Preview: $(fs_s)"
else
    pass "Num .: the full-screen Preview, 4 steps, from frame ${FS_F} ($(fs_s))"
    [[ "$FS_PLAY" == -1 ]] && pass "it starts playing" || fail "not playing on open: $(fs_s)"
    FS_K0=$FS_K; sleep 0.3; fs_read # (not a whole loop: 4 frames at 4 fps come round every 1 s)
    [[ "$FS_K" != "$FS_K0" ]] && pass "and plays on (step $FS_K0 -> $FS_K)" || fail "still on step $FS_K0 after 0.55 s at 4 fps"

    # -- SPACE pauses; what shows is the frame's own colour; steps --
    fs_key space; fs_read; FS_KP=$FS_K
    sleep 0.6; fs_read
    [[ "$FS_PLAY" == 0 && "$FS_K" == "$FS_KP" ]] && pass "SPACE pauses: step $FS_K stays" || fail "SPACE: $(fs_s) (was step $FS_KP)"
    fs_shows "$FS_F" && pass "frame $FS_F's colour is on screen (#$(fs_colour))" || fail "on screen #$(fs_colour), wanted frame $FS_F's #${FS_COLORS[$(( FS_F - 1 ))]}"
    fs_key Home; fs_read
    [[ "$FS_K" == 1 && "$FS_F" == 1 ]] && fs_shows 1 && pass "HOME: frame 1, shown" || fail "HOME: $(fs_s), on screen #$(fs_colour)"
    fs_key Right; fs_read
    [[ "$FS_K" == 2 && "$FS_F" == 2 ]] && fs_shows 2 && pass "RIGHT: frame 2, shown" || fail "RIGHT: $(fs_s), on screen #$(fs_colour)"
    fs_key Left; fs_key Left; fs_read
    [[ "$FS_K" == 4 ]] && fs_shows 4 && pass "LEFT twice from 2: wraps to frame 4" || fail "LEFT LEFT: $(fs_s)"
    fs_key End; fs_key Home; fs_key End; fs_read
    [[ "$FS_K" == 4 && "$FS_PLAY" == 0 ]] && pass "END: the last frame" || fail "END: $(fs_s)"

    # -- the seek bar --
    click $(( FS_BX + FS_BW / 8 )) $(( FS_BY + FS_BH / 2 )); fs_read
    [[ "$FS_K" == 1 ]] && fs_shows 1 && pass "a click at 1/8 of the seek bar: frame 1" || fail "seek click 1/8: $(fs_s)"
    mouse_down $(( FS_BX + FS_BW / 8 )) $(( FS_BY + FS_BH / 2 ))
    hover $(( FS_BX + FS_BW * 3 / 8 )) $(( FS_BY + FS_BH / 2 )); sleep 0.3; fs_read; FS_KM=$FS_K
    hover $(( FS_BX + FS_BW * 7 / 8 )) $(( FS_BY + FS_BH / 2 )); sleep 0.3
    mouse_up; fs_read
    [[ "$FS_KM" == 2 && "$FS_K" == 4 && "$FS_PLAY" == 0 ]] && fs_shows 4 && pass "dragging along the seek bar scrubs: 1 -> 2 -> 4, paused" || fail "seek drag: mid step '$FS_KM', $(fs_s)"

    # -- zoom: wheel about the pointer, double middle click 100%, middle drag pans --
    FS_Z0=$FS_Z; FS_W0=$FS_W
    scroll_down $(( FS_X + FS_W / 2 )) $(( FS_Y + FS_H / 2 )); sleep 0.1
    scroll_down $(( FS_X + FS_W / 2 )) $(( FS_Y + FS_H / 2 )); fs_read
    [[ "$FS_Z" -lt "$FS_Z0" && "$FS_W" -lt "$FS_W0" ]] && fs_shows 4 && pass "wheel down: zoomed out ($FS_Z0% -> $FS_Z%), still frame 4 on screen" || fail "wheel down: $(fs_s) (was $FS_Z0%)"
    FS_Z1=$FS_Z
    scroll_up $(( FS_X + FS_W / 2 )) $(( FS_Y + FS_H / 2 )); fs_read
    [[ "$FS_Z" -gt "$FS_Z1" ]] && pass "wheel up: zoomed in ($FS_Z1% -> $FS_Z%)" || fail "wheel up: $(fs_s)"
    FS_MX=$(( FS_X + FS_W / 2 )); FS_MY=$(( FS_Y + FS_H / 2 ))
    middle_click "$FS_MX" "$FS_MY"; middle_click "$FS_MX" "$FS_MY"; fs_read
    [[ "$FS_Z" == 100 && "$FS_W" == 16 ]] && fs_shows 4 && pass "double middle click: 100% (16 px on screen), frame 4 shown" || fail "double middle click: $(fs_s)"
    FS_X0=$FS_X; FS_Y0=$FS_Y
    mouse_down $(( FS_X + 4 )) $(( FS_Y + 4 )) 2
    hover $(( FS_X + 44 )) $(( FS_Y + 24 )); sleep 0.3
    mouse_up 2; fs_read
    [[ $(( FS_X - FS_X0 )) -ge 38 && $(( FS_X - FS_X0 )) -le 42 && $(( FS_Y - FS_Y0 )) -ge 18 && $(( FS_Y - FS_Y0 )) -le 22 ]] && fs_shows 4 \
        && pass "middle drag pans: the frame moved $(( FS_X - FS_X0 )),$(( FS_Y - FS_Y0 )) with the pointer (40,20)" || fail "middle drag: $FS_X0,$FS_Y0 -> $FS_X,$FS_Y"

    # -- SPACE plays again; ESC closes on the frame shown --
    fs_key space; sleep 0.5; fs_key space; fs_read; FS_LAST=$FS_F
    [[ "$FS_PLAY" == 0 ]] || fail "SPACE SPACE: $(fs_s)"
    park_mouse; fs_key Escape; sleep 0.4; fs_read
    [[ -z "$FS_OPEN" && "$A_CUR" == "$FS_LAST" ]] && pass "ESC closes; the current frame is the one shown ($FS_LAST)" || fail "ESC: ANIMFS '$(fs_line ANIMFS)', current $A_CUR (wanted $FS_LAST)"

    # -- the closing ESC is the preview's, not DRAW's (ESC deselects) --
    key ctrl+a; sleep 0.5
    read -r _ FS_SEL _ <<< "$(fs_line ANIMSEL)"
    key KP_Decimal; wait_for 0.6 "open"; fs_key Escape; sleep 0.5; fs_read
    read -r _ FS_SEL2 _ <<< "$(fs_line ANIMSEL)"
    [[ "$FS_SEL" == -1 && "$FS_SEL2" == -1 && -z "$FS_OPEN" ]] && pass "Select All, open, ESC: closed, and the selection is still there" || fail "ESC leaked to DRAW: selection '$FS_SEL' -> '$FS_SEL2', ANIMFS '$(fs_line ANIMFS)'"
    key ctrl+d; sleep 0.3

    # -- Num . opens it again and closes it --
    key KP_Decimal; wait_for 0.6 "open again"; fs_read
    [[ "$FS_OPEN" == -1 && "$FS_PLAY" == -1 ]] && pass "Num . again: open and playing" || fail "reopen: $(fs_s)"
    key KP_Decimal; sleep 0.5; fs_read
    [[ -z "$FS_OPEN" ]] && pass "and Num . closes it" || fail "Num . did not close it: $(fs_s)"
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$FS_DIR"
assert_window_exists
