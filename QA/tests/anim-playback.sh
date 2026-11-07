#!/bin/bash
# =============================================================================
# anim-playback.sh — QA test: animation playback (Animation 1.9).
#
# Num Enter / Alt+/ / ANIM > Play / the panel's PLAY play and stop the frames
# at the sheet's FPS (holds, loop modes - the stepping itself is unit-tested in
# QA/unit/anim-unit.bas). While playing, drawing on the canvas is blocked. The
# Preview window shows the current frame (ANIM > Preview Shows Frame), so it
# plays too.
#
# Dump: ANIM (… canvasW canvasH playing previewFrame at the end; dx dy = the
# canvas origin on screen), ANIMC (a CRC per frame cell), WIN preview x y w h.
# Fixture: a 64x32 sheet of 16x16 frames, 7 frames, current 3, 12 fps, each
# cell with its own mark.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: playback ==="

PB_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
PB_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
PB_DIR="/tmp/draw-qa-playback-$$"
mkdir -p "$PB_DIR"
PB_DRAW=()
PB_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0 e08020)
for n in 0 1 2 3 4 5 6; do # cell n+1: a mark of its own
    x=$(( (n % 4) * 16 + 2 )); y=$(( (n / 4) * 16 + 2 ))
    PB_DRAW+=(-fill "#${PB_COLORS[$n]}" -draw "rectangle $x,$y $(( x + 1 + n )),$(( y + 9 ))")
done
magick -size 64x32 xc:none "${PB_DRAW[@]}" "$PB_DIR/plain.png"
PB_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,7,3,12,0,0).hex())")
python3 "$PB_PY" put "$PB_DIR/plain.png" "$PB_DIR/sheet.png" drAn "$PB_BLOB"

pb_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
pb_line() { grep -m1 "^$1 " "$PB_DUMP" 2>/dev/null; }
pb_read() { # A_CUR A_DX A_DY A_PLAY A_PVF, A_T
    pb_settle
    read -r _ _ _ A_CUR _ _ _ _ _ _ _ _ _ A_DX A_DY _ _ A_PLAY A_PVF _ <<< "$(pb_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(pb_line ANIMC)"
}
pb_cur_now() { read -r _ _ _ c _ <<< "$(pb_line ANIM)"; echo "$c"; } # no settle: a quick sample
pb_key() { park_mouse; key "$1"; wait_for 0.4 "$1"; }
pb_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 0.6 "$1"
}
pb_moving() { # LABEL - the current frame changes over time (sampled 4 x 0.2 s)
    local a b c d; a=$(pb_cur_now); sleep 0.2; b=$(pb_cur_now); sleep 0.2; c=$(pb_cur_now); sleep 0.2; d=$(pb_cur_now)
    if [[ "$a" != "$b" || "$b" != "$c" || "$c" != "$d" ]]; then pass "$1 (frames $a $b $c $d)"; else fail "$1: frame stuck at $a"; fi
}
pb_still() { # LABEL
    local a b; a=$(pb_cur_now); sleep 0.5; b=$(pb_cur_now)
    [[ -n "$a" && "$a" == "$b" ]] && pass "$1 (frame $a)" || fail "$1: frame went $a -> $b"
}

info "Launching DRAW with a 64x32 sheet of 16x16 frames (7, current 3, 12 fps)"
draw_quit
draw_settle # a small file loads fast enough to race the old window (see draw_settle)
DRAW_EXTRA_ARGS="$PB_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key ctrl+0
wait_for 0.5 "Zoom 100%"
key b
wait_for 0.3 "Brush"

pb_read
read -r _ _ PV_X PV_Y PV_W PV_H _ <<< "$(pb_line 'WIN preview')"
[[ "$A_PLAY" == 0 && "$A_PVF" == -1 ]] && pass "not playing; the Preview shows the current frame" || fail "start: playing '$A_PLAY' previewFrame '$A_PVF'"

# -- the Preview follows the current frame --
if [[ -n "${PV_W:-}" ]]; then
    snap_region $(( PV_X + 4 )) $(( PV_Y + 16 )) $(( PV_W - 8 )) $(( PV_H - 22 )) "pv-frame3"; PV_F3="$SNAP_RESULT"
    pb_key KP_5
    snap_region $(( PV_X + 4 )) $(( PV_Y + 16 )) $(( PV_W - 8 )) $(( PV_H - 22 )) "pv-frame4"; PV_F4="$SNAP_RESULT"
    assert_regions_differ "$PV_F3" "$PV_F4" "the Preview shows frame 4 after Num 5"
    pb_key KP_4
else
    info "no Preview window in this workspace - Preview checks skipped"
fi

# -- Num Enter plays, Alt+/ stops --
pb_key KP_Enter
pb_read
[[ "$A_PLAY" == -1 ]] && pass "Num Enter: playing" || fail "Num Enter: playing '$A_PLAY'"
pb_moving "the frames step while playing"
if [[ -n "${PV_W:-}" ]]; then
    # each snap takes ~1.3 s; 7 frames at 12 fps can land on the same frame
    # twice, so up to three snaps: the Preview plays if any two differ
    snap_region $(( PV_X + 4 )) $(( PV_Y + 16 )) $(( PV_W - 8 )) $(( PV_H - 22 )) "pv-play1"; PV_P1="$SNAP_RESULT"
    snap_region $(( PV_X + 4 )) $(( PV_Y + 16 )) $(( PV_W - 8 )) $(( PV_H - 22 )) "pv-play2"; PV_P2="$SNAP_RESULT"
    if cmp -s "$PV_P1" "$PV_P2"; then
        sleep 0.2
        snap_region $(( PV_X + 4 )) $(( PV_Y + 16 )) $(( PV_W - 8 )) $(( PV_H - 22 )) "pv-play3"; PV_P2="$SNAP_RESULT"
    fi
    assert_regions_differ "$PV_P1" "$PV_P2" "the Preview plays"
fi

# drawing is blocked while playing
PB_BEFORE="$A_T"
click $(( A_DX + 8 )) $(( A_DY + 13 ))
wait_for 0.4 "click on the canvas while playing"
pb_read
[[ "$A_T" == "$PB_BEFORE" && "$A_PLAY" == -1 ]] && pass "a click on the canvas while playing draws nothing" \
    || fail "while playing: frames [$PB_BEFORE] -> [$A_T], playing $A_PLAY"

pb_key alt+slash
pb_read
[[ "$A_PLAY" == 0 ]] && pass "Alt+/: stopped" || fail "Alt+/: playing '$A_PLAY'"
pb_still "stopped: the frame stays put"
click $(( A_DX + 8 )) $(( A_DY + 13 ))
wait_for 0.4 "click on the canvas, stopped"
pb_read
[[ "$A_T" != "$PB_BEFORE" ]] && pass "stopped: the same click draws" || fail "stopped: the click drew nothing either (frames [$A_T])"
pb_key ctrl+z

# -- Alt+/ plays too; Num Enter stops --
pb_key alt+slash
pb_read; [[ "$A_PLAY" == -1 ]] && pass "Alt+/: playing" || fail "Alt+/ to play: playing '$A_PLAY'"
pb_key KP_Enter
pb_read; [[ "$A_PLAY" == 0 ]] && pass "Num Enter: stopped" || fail "Num Enter to stop: playing '$A_PLAY'"

# -- the panel: PLAY / STOP, play once --
pb_cmd "animation panel"
pb_settle
read -r _ P_VIS _ P_X P_Y _ _ P_SC _ <<< "$(pb_line ANIMP)"
read -r _ L_NAV _ _ _ _ _ _ L_LOOP L_RH _ _ _ L_PAD L_PW _ <<< "$(pb_line ANIMPL)"
if [[ "$P_VIS" == -1 && -n "${L_PW:-}" ]]; then
    pb_chip() { # NATIVE_ROW K N - click chip K of an N-chip row
        local cw=$(( (L_PW - 2 * L_PAD - 2 * ($3 - 1)) / $3 ))
        click $(( P_X + (L_PAD + $2 * (cw + 2) + cw / 2) * P_SC / 100 )) $(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))
        wait_for 0.4 "chip $2 of $3"
    }
    pb_chip "$L_NAV" 2 5; pb_read
    [[ "$A_PLAY" == -1 ]] && pass "panel PLAY" || fail "panel PLAY: playing '$A_PLAY'"
    pb_chip "$L_NAV" 2 5; pb_read
    [[ "$A_PLAY" == 0 ]] && pass "panel STOP" || fail "panel STOP: playing '$A_PLAY'"
    pb_chip "$L_LOOP" 3 4  # ONCE
    pb_chip "$L_NAV" 2 5
    sleep 1.5
    pb_read
    [[ "$A_PLAY" == 0 && "$A_CUR" == 7 ]] && pass "play once stops by itself on the last frame" \
        || fail "play once: playing $A_PLAY on frame $A_CUR after 1.5 s (wanted 0 / 7)"
else
    fail "the Animation panel did not open (visible=$P_VIS)"
fi

# -- ANIM > Preview Shows Frame off: the Preview shows the canvas --
pb_cmd "preview shows frame"
pb_read
[[ "$A_PVF" == 0 ]] && pass "Preview Shows Frame off" || fail "Preview Shows Frame toggle: previewFrame '$A_PVF'"
if [[ -n "${PV_W:-}" ]]; then
    snap_region $(( PV_X + 4 )) $(( PV_Y + 16 )) $(( PV_W - 8 )) $(( PV_H - 22 )) "pv-canvas"; PV_CV="$SNAP_RESULT"
    assert_regions_differ "$PV_F3" "$PV_CV" "the Preview no longer shows just the frame"
fi
pb_cmd "preview shows frame"
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$PB_DIR"
assert_window_exists
