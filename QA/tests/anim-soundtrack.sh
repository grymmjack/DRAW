#!/bin/bash
# =============================================================================
# anim-soundtrack.sh — QA test: the soundtrack (Animation L.1, TOOLS/ANIM-SOUND).
#
# A sound file timed against the frames: frame k starts at the earlier frames'
# times (holds / FPS). Playback plays it from the current frame's time and a
# loop back to frame 1 starts it again there; stopping stops it; stepping
# frames while stopped plays that frame's slice (scrub). The X-sheet's SOUND
# row draws the waveform along the frames. Remove Soundtrack is one undo step;
# the soundtrack is saved with the frames (drAn v6) and is found beside the
# document when its path has moved.
#
# Silent on purpose: the WAV is at -60 dB and ANIM_SOUND_VOLUME=0 (also in
# QA/DRAW.qa.cfg), so nothing is heard while it runs.
#
# The BAS player export copies it beside the .bas as NAME-sound.EXT and plays
# it in step (compiled here; --frames writes sound.txt with each step's time).
#
# Dump: ANIMSND open on starts lastStartMs lenMs peaks name, ANIMXSS soundRowY.
# Fixture: a 96x16 sheet of 16x16 frames, 6 frames at 10 fps (frame k starts
# at (k - 1) * 100 ms); beat.wav 1 s, sound in 0-0.28 s and 0.62-1 s only.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: soundtrack ==="

ST_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
ST_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
ST_T="$(mktemp -d /tmp/draw-qa-sound-XXXXXX)"
mkdir -p "$ST_T/snd" "$ST_T/moved"
magick -size 96x16 xc:none -fill "#c04040" -draw "rectangle 3,4 8,9" -fill "#40c040" -draw "rectangle 20,4 25,9" "PNG32:$ST_T/plain.png"
python3 - "$ST_T/snd/beat.wav" <<'PY'
import struct, math, sys
sr = 22050
def a(t): return 32.0 if (t < 0.28 or t >= 0.62) else 0.0   # -60 dB; silent 0.28-0.62 s (resampling smears an edge into the next 1/100 s)
d = b''.join(struct.pack('<h', int(a(i / sr) * math.sin(2 * math.pi * 330 * i / sr))) for i in range(sr))
open(sys.argv[1], 'wb').write(b'RIFF' + struct.pack('<I', 36 + len(d)) + b'WAVEfmt ' + struct.pack('<IHHIIHH', 16, 1, 1, sr, sr * 2, 2, 16) + b'data' + struct.pack('<I', len(d)) + d)
PY
cp "$ST_T/snd/beat.wav" "$ST_T/moved/beat.wav"
st_blob() { # PATH -> drAn v6 hex: 6 frames of 16x16 at 10 fps, the soundtrack PATH
    python3 -c "import struct,sys;p=sys.argv[1].encode();print((struct.pack('<10h',6,16,16,0,0,6,1,10,0,0)+struct.pack('<4h',0,0,0,0)+struct.pack('<h',len(p))+p+struct.pack('<i',0)).hex())" "$1"
}
python3 "$ST_PY" put "$ST_T/plain.png" "$ST_T/sheet.png" drAn "$(st_blob "$ST_T/snd/beat.wav")"
python3 "$ST_PY" put "$ST_T/plain.png" "$ST_T/moved/sheet.png" drAn "$(st_blob "/nowhere/at/all/beat.wav")"

st_line() { grep -m1 "^$1 " "$ST_DUMP" 2>/dev/null; }
st_read() { # A_COUNT A_CUR A_PLAY, S_OPEN S_ON S_STARTS S_LAST S_LEN S_PK S_NAME, SS_Y, XF[] XTW XRH
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ _ _ _ _ _ _ _ _ _ _ _ _ A_PLAY _ <<< "$(st_line ANIM)"
    S_OPEN=""; read -r _ S_OPEN S_ON S_STARTS S_LAST S_LEN S_PK S_NAME _ <<< "$(st_line ANIMSND)"
    SS_Y=""; read -r _ SS_Y _ <<< "$(st_line ANIMXSS)"
    read -r _ _ _ _ _ _ _ _ XRH XTW _ <<< "$(st_line ANIMXS)"
    XF=($(st_line ANIMXSF))
}
st_s() { echo "frame ${A_CUR:-?}/${A_COUNT:-?} playing ${A_PLAY:-?}; sound open ${S_OPEN:-?} on ${S_ON:-?} starts ${S_STARTS:-?} last ${S_LAST:-?} ms len ${S_LEN:-?} ms peaks ${S_PK:-?} '${S_NAME:-}'; row '${SS_Y:-}'"; }
st_key() { park_mouse; key "$1"; wait_for 0.5 "$1"; }
st_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
st_xsheet() { local on; read -r _ _ on _ <<< "$(st_line ANIMXS)"; [[ "$on" == -1 ]] || st_key KP_8; }
st_open() { # FILE
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$1 --option ANIM_SOUND_VOLUME=0"
    draw_launch 15
    wait_for 1.5 "sheet loaded"
    assert_no_crash
    st_key ctrl+0
    st_read; st_xsheet; st_read
}

info "Launching DRAW with a sheet whose drAn names beat.wav"
st_open "$ST_T/sheet.png"
if [[ "$S_OPEN" != -1 ]]; then
    fail "the soundtrack did not open: $(st_s)"
else
    [[ "$S_LEN" -ge 990 && "$S_LEN" -le 1010 && "$S_PK" -ge 100 && "$S_NAME" == beat.wav && -n "$SS_Y" ]] \
        && pass "beat.wav open: 1 s, ${S_PK} waveform peaks, the X-sheet has a SOUND row" || fail "loaded: $(st_s)"
    # the waveform: frame 2 (0.1-0.2 s) has sound, frame 5 (0.4-0.5 s) none
    if [[ -n "$SS_Y" && "${XTW:-0}" -gt 2 ]]; then
        ST_LOUD=$(snap_region $(( XF[5] + 1 )) $(( SS_Y + 2 )) $(( XTW - 2 )) $(( XRH - 4 )) st-loud >/dev/null; echo "$SNAP_RESULT")
        ST_QUIET=$(snap_region $(( XF[14] + 1 )) $(( SS_Y + 2 )) $(( XTW - 2 )) $(( XRH - 4 )) st-quiet >/dev/null; echo "$SNAP_RESULT")
        ST_QUIET2=$(snap_region $(( XF[11] + 1 )) $(( SS_Y + 2 )) $(( XTW - 2 )) $(( XRH - 4 )) st-quiet2 >/dev/null; echo "$SNAP_RESULT")
        ST_AE=$(magick compare -metric AE -fuzz 2% "$ST_LOUD" "$ST_QUIET" null: 2>&1 | awk '{print int($1)}')
        [[ "${ST_AE:-0}" -ge 100 ]] && pass "the SOUND row: a waveform under frame 2, none under frame 5 ($ST_AE pixels differ)" \
            || fail "the SOUND row: frame 2 (sound) vs frame 5 (silence) differ by '${ST_AE}' pixels (wanted 100+)"
        assert_regions_same "$ST_QUIET" "$ST_QUIET2" "the SOUND row: frames 4 and 5 (0.3-0.5 s, silent) look the same" 10
    fi

    # -- playback --
    st_key KP_Enter; sleep 0.2; st_read
    [[ "$A_PLAY" == -1 && "$S_ON" == -1 && "$S_STARTS" -ge 1 ]] && pass "Num Enter: playing, the sound with it" || fail "play: $(st_s)"
    ST_S0=$S_STARTS
    sleep 1.4; st_read
    [[ "$S_STARTS" -gt "$ST_S0" ]] && pass "6 frames = 0.6 s: looping back to frame 1 starts it again (starts $ST_S0 -> $S_STARTS)" || fail "loop restart: $(st_s) (starts were $ST_S0)"
    st_key KP_Enter; st_read
    [[ "$A_PLAY" == 0 && "$S_ON" == 0 ]] && pass "Num Enter again: stopped, the sound too" || fail "stop: $(st_s)"

    # -- scrub: a step while stopped plays that frame's slice --
    st_key KP_1; st_read; ST_S0=$S_STARTS
    st_key KP_5; st_read
    [[ "$A_CUR" == 2 && "$S_STARTS" == $(( ST_S0 + 1 )) && "$S_LAST" == 100 && "$S_ON" == 0 ]] \
        && pass "Num 5 to frame 2: its slice played from 100 ms (and is over)" || fail "scrub: $(st_s) (starts were $ST_S0)"
    st_key KP_9; st_read
    [[ "$A_CUR" == 6 && "$S_LAST" == 500 ]] && pass "Num 9 to frame 6: from 500 ms" || fail "scrub to the last frame: $(st_s)"
    st_key KP_4; st_key KP_4; st_read; ST_S0=$S_STARTS
    # the loop wraps to frame 1 0.3 s later, so catch the first start as it lands
    park_mouse; key KP_Enter; ST_PLAY_LAST=""
    for _ in $(seq 1 40); do
        read -r _ _ _ ST_N ST_L _ <<< "$(st_line ANIMSND)"
        [[ "${ST_N:-0}" -gt "$ST_S0" ]] && { ST_PLAY_LAST=$ST_L; break; }
        sleep 0.02
    done
    st_key KP_Enter
    [[ "$A_CUR" == 4 && "$ST_PLAY_LAST" == 300 ]] && pass "Num Enter on frame 4: the sound starts at its time (300 ms)" || fail "play from frame 4: frame $A_CUR, first start '$ST_PLAY_LAST' ms (wanted 300)"

    # -- the full-screen preview (its own loop) plays it too --
    st_fs() { read -r _ FS_OPEN _ FS_F FS_PLAY _ _ _ _ _ _ _ _ _ _ FS_SN FS_SL FS_SO _ <<< "$(st_line ANIMFS)"; }
    st_read; ST_S0=$S_STARTS
    park_mouse; key KP_Decimal; sleep 0.8; st_fs
    [[ "$FS_OPEN" == -1 && "$FS_PLAY" == -1 && "$FS_SO" == -1 && "${FS_SN:-0}" -gt "$ST_S0" ]] \
        && pass "Num . full-screen preview: playing, the sound with it" || fail "full screen: open '$FS_OPEN' playing '$FS_PLAY' sound on '$FS_SO' starts '$FS_SN' (were $ST_S0)"
    key space; sleep 0.35; st_fs
    [[ "$FS_PLAY" == 0 && "$FS_SO" == 0 ]] && pass "SPACE pauses it: the sound stops" || fail "full screen pause: playing '$FS_PLAY' sound on '$FS_SO'"
    key Home; sleep 0.35; key Right; sleep 0.4; st_fs
    [[ "$FS_F" == 2 && "$FS_SL" == 100 && "$FS_SO" == 0 ]] && pass "Home, Right: frame 2's slice played from 100 ms (and is over)" || fail "full screen step: frame '$FS_F' last start '$FS_SL' on '$FS_SO'"
    key Escape; sleep 0.6

    # -- Remove Soundtrack, undo --
    st_palette "remove soundtrack"; st_read
    [[ "$S_NAME" == "-" && "$S_OPEN" == 0 && -n "$SS_Y" ]] && pass "Remove Soundtrack: none; the SOUND row stays, empty (every animation has one)" || fail "remove: $(st_s)"
    st_key ctrl+z; st_read
    [[ "$S_NAME" == beat.wav && "$S_OPEN" == -1 && -n "$SS_Y" ]] && pass "undo: beat.wav back on the SOUND row, open" || fail "undo remove: $(st_s)"

    # -- saved and back --
    st_key ctrl+s; wait_for 1.5 "saved"
    ST_V=$(python3 "$ST_PY" get "$ST_T/sheet.png" drAn 2>/dev/null | cut -c1-4)
    st_open "$ST_T/sheet.png"
    [[ "$ST_V" == 0600 && "$S_OPEN" == -1 && "$S_NAME" == beat.wav ]] && pass "Ctrl+S, reopen: drAn v6, the soundtrack back" || fail "reopen: drAn '$ST_V', $(st_s)"
fi

info "The BAS player plays it (batch export, compiled, run)"
ST_QB="${QB64PE:-$HOME/git/qb64pe/qb64pe}"
mkdir -p "$ST_T/home" "$ST_T/bas" "$ST_T/fr"
st_export() { # IN OUT.bas -> ST_OUT
    ST_OUT=$( cd "$DRAW_ROOT" && HOME="$ST_T/home" XDG_CONFIG_HOME="$ST_T/home/.config" XDG_DATA_HOME="$ST_T/home/.local/share" \
      XDG_CACHE_HOME="$ST_T/home/.cache" timeout --foreground -k 5 60 "$DRAW_BIN" "$1" --export-anim "$2" </dev/null 2>>"$ST_T/err.txt" )
}
st_export "$ST_T/sheet.png" "$ST_T/bas/walk.bas"
if cmp -s "$ST_T/snd/beat.wav" "$ST_T/bas/walk-sound.wav" && grep -q '_SNDOPEN("walk-sound.wav")' "$ST_T/bas/walk.bas" 2>/dev/null; then
    pass "walk.bas: beat.wav copied beside it as walk-sound.wav (the same bytes), the player opens it"
else
    fail "BAS export: walk-sound.wav $( [[ -e "$ST_T/bas/walk-sound.wav" ]] && echo differs || echo missing ), '$(tr '\n' '|' <<< "$ST_OUT")'"
fi
if [[ -x "$ST_QB" && -s "$ST_T/bas/walk.bas" ]]; then
    if ( cd "$ST_T/bas" && "$ST_QB" -x -w walk.bas -o walk.run >"$ST_T/qb.log" 2>&1 ); then
        ( cd / && timeout --foreground -k 3 30 "$ST_T/bas/walk.run" --frames "$ST_T/fr" </dev/null >/dev/null 2>&1 ) # from elsewhere: the sound beside the program
        ST_TXT=$(tr -d '\r' < "$ST_T/fr/sound.txt" 2>/dev/null | tr '\n' ' ' | sed 's/ $//')
        [[ "$ST_TXT" =~ ^walk-sound\.wav\ -1\ (99[0-9]|100[0-9])\ 1\ 1\ 0\ 2\ 2\ 100\ 3\ 3\ 200\ 4\ 4\ 300\ 5\ 5\ 400\ 6\ 6\ 500$ ]] \
            && pass "it compiles; started from another folder it opens walk-sound.wav (1 s) and times frames 1-6 at 0 100 200 300 400 500 ms, as DRAW does" \
            || fail "the player's sound.txt: '$ST_TXT'"
        # live, on the harness's own X server: plays (with the sound) and quits on Esc
        if [[ -n "${QA_IN_XVFB:-}" ]] && command -v xdotool >/dev/null; then
            ( cd "$ST_T/bas" && exec ./walk.run </dev/null >/dev/null 2>&1 ) & ST_P=$!
            sleep 2.5
            ST_W=$(xdotool search --pid "$ST_P" 2>/dev/null | tail -1)
            [[ -n "$ST_W" ]] && { xdotool key --window "$ST_W" space; sleep 0.3; xdotool key --window "$ST_W" Right; sleep 0.3; xdotool key --window "$ST_W" space; sleep 0.5; xdotool key --window "$ST_W" Escape; } 2>/dev/null
            for i in $(seq 1 15); do kill -0 "$ST_P" 2>/dev/null || break; sleep 0.2; done
            if kill -0 "$ST_P" 2>/dev/null; then
                kill "$ST_P" 2>/dev/null; fail "the player with a soundtrack did not quit on Esc"
            else
                wait "$ST_P"; ST_RC=$?
                [[ "$ST_RC" == 0 && -n "$ST_W" ]] && pass "live: plays, pause + step (a scrub) + play, Esc quits with exit 0" || fail "live player: window '$ST_W', exit $ST_RC"
            fi
        fi
    else
        fail "walk.bas does not compile: $(tail -3 "$ST_T/qb.log" | tr '\n' ' ')"
    fi
fi
# the soundtrack missing: the player is still written, without sound
python3 "$ST_PY" put "$ST_T/plain.png" "$ST_T/lost.png" drAn "$(st_blob "/nowhere/at/all/beat.wav")"
st_export "$ST_T/lost.png" "$ST_T/bas/lost.bas"
[[ -s "$ST_T/bas/lost.bas" && ! -e "$ST_T/bas/lost-sound.wav" ]] && ! grep -q '_SNDOPEN' "$ST_T/bas/lost.bas" && grep -q 'soundtrack not found' <<< "$ST_OUT" \
    && pass "a soundtrack that is not found: lost.bas still written, without sound, and the export says so" || fail "missing soundtrack: '$(tr '\n' '|' <<< "$ST_OUT")'"

info "The sound's path is gone, but it is beside the document"
st_open "$ST_T/moved/sheet.png"
[[ "$S_OPEN" == -1 && "$S_NAME" == beat.wav && -n "$SS_Y" ]] && pass "moved/sheet.png: beat.wav found beside it" || fail "beside the document: $(st_s)"
rm -f "$ST_T/moved/beat.wav"
st_open "$ST_T/moved/sheet.png"
[[ "$S_OPEN" == 0 && "$S_NAME" == beat.wav && -n "$SS_Y" ]] && pass "and with it gone: kept, not open, the SOUND row says so" || fail "not found: $(st_s)"
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$ST_T"
assert_window_exists
