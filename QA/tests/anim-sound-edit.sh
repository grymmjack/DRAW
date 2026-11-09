#!/bin/bash
# =============================================================================
# anim-sound-edit.sh — QA test: sound clips on tracks (field kit T-28, Rick
# 2026-11-08: "Can we add the ability to move/cut/copy/paste the waveform ?
# have more than one audio track, etc. ? multiple file support?").
#
# The soundtrack is clips on up to 4 tracks (ANIM_SC_*, saved in drAn v7);
# the X-sheet has a SOUND row per track with each clip's waveform. A press on
# a clip picks it and gives the rows the keys; a drag moves it (snapped to a
# frame start; onto another row = that track), one undo step. Ctrl+C / X / V
# and Delete act on the picked clip, or on the selected frames' span of the
# track; Ctrl+V pastes at the current frame. Right-click = the SOUND menu
# (Split Here ...). Two clips play as one mix, and a BAS export writes the
# mix beside the .bas as a WAV.
#
# The old build read the v6 part only: one clip, one SOUND row, no editing.
#
# Silent: the WAVs are at -60 dB and ANIM_SOUND_VOLUME=0.
#
# Dump: ANIMSC n sel track focus mixed skipped clipN clipSpan dragging, then
# per clip track at in len end (ms); ANIMXSS the SOUND rows' y; ANIMXSF per
# frame f x w; ANIMSCM the menu (x y w, then action y per item); ANIMC.
# Fixture: a 128x16 sheet of 16x16 frames, 8 frames at 10 fps (frame k
# starts at (k - 1) * 100 ms); beat.wav (1 s, sound 0-0.28 s and 0.62-1 s)
# on track 1 from frame 1, tone.wav (0.3 s) on track 2 from frame 5.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: sound clips and tracks ==="

SE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
SE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
SE_T="$(mktemp -d /tmp/draw-qa-sndedit-XXXXXX)"
mkdir -p "$SE_T/snd" "$SE_T/home" "$SE_T/bas"
magick -size 128x16 xc:none -fill "#c04040" -draw "rectangle 3,4 8,9" -fill "#40c040" -draw "rectangle 20,4 25,9" "PNG32:$SE_T/plain.png"
python3 - "$SE_T/snd" <<'PY'
import struct, math, sys
sr = 22050
def wav(path, n, amp):
    d = b''.join(struct.pack('<h', int(amp(i / sr) * math.sin(2 * math.pi * 330 * i / sr))) for i in range(n))
    open(path, 'wb').write(b'RIFF' + struct.pack('<I', 36 + len(d)) + b'WAVEfmt ' + struct.pack('<IHHIIHH', 16, 1, 1, sr, sr * 2, 2, 16) + b'data' + struct.pack('<I', len(d)) + d)
wav(sys.argv[1] + '/beat.wav', sr, lambda t: 32.0 if (t < 0.28 or t >= 0.62) else 0.0)   # -60 dB
wav(sys.argv[1] + '/tone.wav', int(sr * 0.3), lambda t: 32.0)
PY
se_blob() { # drAn v7: 8 frames of 16x16 at 10 fps; beat.wav on track 1 at 0, tone.wav on track 2 at 400 ms
    python3 - "$SE_T/snd/beat.wav" "$SE_T/snd/tone.wav" <<'PY'
import struct, sys
b, t = sys.argv[1].encode(), sys.argv[2].encode()
s = struct.pack('<10h', 7, 16, 16, 0, 0, 8, 1, 10, 0, 0) + struct.pack('<4h', 0, 0, 0, 0)
s += struct.pack('<h', len(b)) + b + struct.pack('<i', 0)                        # v6: clip 1
s += struct.pack('<h', 2)
for trk, at, p in ((1, 0, b), (2, 400, t)):
    s += struct.pack('<hiiih', trk, at, 0, 0, len(p)) + p                        # v7: every clip
print(s.hex())
PY
}
python3 "$SE_PY" put "$SE_T/plain.png" "$SE_T/sheet.png" drAn "$(se_blob)"

se_line() { grep -m1 "^$1 " "$SE_DUMP" 2>/dev/null; }
se_read() { # A_CUR A_SEL, C_* + CL[] (per clip "trk at in len"), XS_Y[], XF[], XRH, SND_*
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(se_line ANIM)"
    read -r _ S_OPEN S_ON _ _ S_LEN _ S_NAME _ <<< "$(se_line ANIMSND)"
    local sc=($(se_line ANIMSC)) i
    C_N=${sc[1]:-}; C_SEL=${sc[2]:-}; C_TRK=${sc[3]:-}; C_FOC=${sc[4]:-}; C_MIX=${sc[5]:-}; C_BN=${sc[7]:-}; C_BSPAN=${sc[8]:-}
    CL=()
    for (( i = 0; i < ${C_N:-0}; i++ )); do CL+=("${sc[$((10 + i * 5))]} ${sc[$((11 + i * 5))]} ${sc[$((12 + i * 5))]} ${sc[$((13 + i * 5))]}"); done
    XS_Y=($(se_line ANIMXSS)); XF=($(se_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ XRH _ <<< "$(se_line ANIMXS)"
    SCM=($(se_line ANIMSCM))
    read -r _ CRC _ <<< "$(se_line ANIMC)"; CRC_ALL="$(se_line ANIMC)"
}
se_clips() { local IFS='|'; echo "${CL[*]}"; }
se_s() { echo "clips ${C_N:-?} [$(se_clips)] sel ${C_SEL:-?} track ${C_TRK:-?} keys ${C_FOC:-?} mixed ${C_MIX:-?} clipboard ${C_BN:-?}/${C_BSPAN:-?}; frame ${A_CUR:-?}; rows '${XS_Y[*]:1}'"; }
se_fx() { # FRAME -> the middle x of its span on the X-sheet
    local i
    for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do
        [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }
    done
    echo 0
}
se_fw() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo "${XF[$((i + 2))]}"; return; }; done; echo 0; }
se_ry() { echo $(( XS_Y[$1] + XRH / 2 )); } # TRACK -> its row's middle y
se_click() { # TRACK FRAME [shift]
    se_read
    if [[ "${3:-}" == shift ]]; then with_mods shift click "$(se_fx "$2")" "$(se_ry "$1")"; else click "$(se_fx "$2")" "$(se_ry "$1")"; fi
    wait_for 0.4 "click track $1 frame $2"; se_read
}
se_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
se_drag() { # FROM_TRACK FROM_FRAME TO_X TO_Y
    local x y
    se_read; x=$(se_fx "$2"); y=$(se_ry "$1")
    mouse_down "$x" "$y"
    hover $(( (x + $3) / 2 )) $(( (y + $4) / 2 )); sleep 0.2
    hover "$3" "$4"; sleep 0.3
    mouse_up; wait_for 0.6 "drag"; se_read
}
se_open() { # FILE
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$1 --option ANIM_SOUND_VOLUME=0"
    draw_launch 15
    wait_for 1.5 "sheet loaded"
    assert_no_crash
    se_key ctrl+0
    se_read
    local on; read -r _ _ on _ <<< "$(se_line ANIMXS)"; [[ "$on" == -1 ]] || se_key KP_8
    se_read
}

info "Launching DRAW with two clips on two tracks"
se_open "$SE_T/sheet.png"
if [[ "$C_N" != 2 || ${#XS_Y[@]} -lt 3 ]]; then
    fail "two clips, two SOUND rows: $(se_s)"
else
    [[ "${CL[0]}" == "1 0 0 0" && "${CL[1]}" == "2 400 0 0" && "$C_MIX" == -1 && "$S_OPEN" == -1 && "$S_LEN" -ge 990 && "$S_LEN" -le 1010 ]] \
        && pass "loaded: beat.wav on track 1 from 0 ms, tone.wav on track 2 from 400 ms, mixed into one 1 s sound, 2 SOUND rows" \
        || fail "loaded: $(se_s); sound open $S_OPEN len $S_LEN"

    # -- track 2's row: the tone's waveform under frames 5-7 only --
    W=$(se_fw 2); RY=${XS_Y[2]}
    snap_region $(( $(se_fx 2) - W / 2 + 2 )) $(( RY + 3 )) $(( W - 4 )) $(( XRH - 6 )) "row2-f2"; R2=$SNAP_RESULT
    snap_region $(( $(se_fx 3) - W / 2 + 2 )) $(( RY + 3 )) $(( W - 4 )) $(( XRH - 6 )) "row2-f3"; R3=$SNAP_RESULT
    snap_region $(( $(se_fx 6) - W / 2 + 2 )) $(( RY + 3 )) $(( W - 4 )) $(( XRH - 6 )) "row2-f6"; R6=$SNAP_RESULT
    assert_regions_same "$R2" "$R3" "SOUND 2 under frames 2 and 3: nothing (the same)"
    assert_regions_differ "$R2" "$R6" "SOUND 2 under frame 6: tone.wav's clip and waveform"

    # -- drag the tone two frames left: from 200 ms; one undo step --
    se_drag 2 6 $(( $(se_fx 6) - 2 * W )) "$(se_ry 2)"
    [[ "${CL[1]}" == "2 200 0 0" && "$C_SEL" == 2 ]] && pass "drag tone.wav 2 frames left: from frame 3 (200 ms)" || fail "drag left: $(se_s)"
    se_key ctrl+z; se_read
    [[ "${CL[1]}" == "2 400 0 0" ]] && pass "undo: back at 400 ms" || fail "undo the move: $(se_s)"
    # -- up onto track 1's row --
    se_drag 2 6 "$(se_fx 6)" "$(se_ry 1)"
    [[ "${CL[1]}" == "1 400 0 0" ]] && pass "drag it up onto SOUND 1: track 1, still from 400 ms" || fail "drag to track 1: $(se_s)"
    se_key ctrl+z; se_read
    [[ "${CL[1]}" == "2 400 0 0" ]] || fail "undo the track move: $(se_s)"

    # -- copy a clip, paste it on track 2 at frame 8 --
    se_click 1 1
    [[ "$C_SEL" == 1 && "$C_FOC" == -1 && "$C_TRK" == 1 ]] && pass "click beat.wav on SOUND 1: picked, the rows have the keys" || fail "pick clip 1: $(se_s)"
    se_key ctrl+c; se_read
    [[ "$C_BN" == 1 && "$C_BSPAN" == 1000 ]] && pass "Ctrl+C: the clip copied (1 s)" || fail "copy the clip: $(se_s)"
    se_click 2 8
    [[ "$C_SEL" == 0 && "$C_TRK" == 2 && "$A_CUR" == 8 ]] || fail "click SOUND 2 at frame 8: $(se_s)"
    se_key ctrl+v; se_read
    [[ "$C_N" == 3 && "${CL[2]}" == "2 700 0 0" && "$C_SEL" == 3 ]] && pass "Ctrl+V on SOUND 2 at frame 8: a copy from 700 ms" || fail "paste: $(se_s)"
    se_key ctrl+z; se_read
    [[ "$C_N" == 2 ]] && pass "undo: the paste gone" || fail "undo the paste: $(se_s)"

    # -- frames 2-3 of track 1: cut out of beat.wav, the rest stays put --
    se_click 1 2; se_click 1 3 shift
    se_key ctrl+x; se_read
    [[ "$C_N" == 3 && "${CL[0]}" == "1 0 0 100" && "${CL[2]}" == "1 300 300 0" && "$C_BSPAN" == 200 ]] \
        && pass "frames 2-3 selected, Ctrl+X: beat.wav cut to 0-100 ms + 300 ms on (from 300 ms into the file), 200 ms copied" \
        || fail "cut frames 2-3: $(se_s)"
    se_key ctrl+z; se_read
    [[ "$C_N" == 2 && "${CL[0]}" == "1 0 0 0" ]] && pass "undo: beat.wav whole again" || fail "undo the cut: $(se_s)"

    # -- Delete takes the clip, not the frame's drawing --
    se_click 2 6; C0="$CRC_ALL"
    se_key Delete; se_read
    [[ "$C_N" == 1 && "${CL[0]}" == "1 0 0 0" && "$CRC_ALL" == "$C0" ]] && pass "tone.wav picked, Delete: the clip goes, the drawings stay" || fail "Delete: $(se_s) (cells changed: $([[ "$CRC_ALL" == "$C0" ]] && echo no || echo yes))"
    se_key ctrl+z; se_read
    [[ "$C_N" == 2 ]] || fail "undo the delete: $(se_s)"
    se_key Escape; se_read
    [[ "$C_FOC" == 0 ]] && pass "Esc: the rows give the keys back" || fail "Esc: $(se_s)"

    # -- right-click: the SOUND menu, Split Here --
    se_read; X=$(se_fx 4); Y=$(se_ry 1)
    click "$X" "$Y" 3; wait_for 0.6 "SOUND menu"; se_read
    SY=""
    for (( i = 4; i + 1 < ${#SCM[@]}; i += 2 )); do [[ "${SCM[$i]}" == 2558 ]] && SY=${SCM[$((i + 1))]}; done
    if [[ -z "$SY" ]]; then
        fail "right-click on SOUND 1: no menu / no Split Here (${SCM[*]})"
    else
        pass "right-click on SOUND 1 at frame 4: the SOUND menu"
        click $(( SCM[1] + 12 )) $(( SY + 6 )); wait_for 0.6 "Split Here"; se_read
        [[ "$C_N" == 3 && "${CL[0]}" == "1 0 0 300" && "${CL[2]}" == "1 300 300 0" ]] && pass "Split Here: beat.wav in two at frame 4 (300 ms)" || fail "split: $(se_s)"
        se_key ctrl+z; se_read
    fi

    # -- saved as v7, and back --
    se_key ctrl+s; wait_for 1.5 "saved"
    SE_V=$(python3 "$SE_PY" get "$SE_T/sheet.png" drAn 2>/dev/null | cut -c1-4)
    se_open "$SE_T/sheet.png"
    [[ "$SE_V" == 0700 && "$C_N" == 2 && "${CL[0]}" == "1 0 0 0" && "${CL[1]}" == "2 400 0 0" ]] \
        && pass "Ctrl+S, reopen: drAn v7, both clips back" || fail "reopen: drAn '$SE_V', $(se_s)"
    screenshot "anim-sound-edit"
fi
assert_no_crash

info "The BAS player gets the mix as a WAV"
SE_OUT=$( cd "$DRAW_ROOT" && HOME="$SE_T/home" XDG_CONFIG_HOME="$SE_T/home/.config" XDG_DATA_HOME="$SE_T/home/.local/share" \
  XDG_CACHE_HOME="$SE_T/home/.cache" timeout --foreground -k 5 60 "$DRAW_BIN" "$SE_T/sheet.png" --export-anim "$SE_T/bas/mix.bas" </dev/null 2>>"$SE_T/err.txt" )
SE_W=$(python3 - "$SE_T/bas/mix-sound.wav" <<'PY' 2>/dev/null
import wave, struct, sys
w = wave.open(sys.argv[1]); ch, sr, n = w.getnchannels(), w.getframerate(), w.getnframes()
d = struct.unpack('<%dh' % (n * ch), w.readframes(n))
def peak(a, b): return max(abs(v) for v in d[int(a * sr) * ch:int(b * sr) * ch])
# beat 0-0.28 + 0.62-1 s, tone 0.4-0.7 s: 0.30-0.38 s silent (+-1 of resampler ringing), 0.45-0.55 s the
# tone alone, 0.63-0.69 s both (added up: louder than either), 0.75-0.95 s beat alone
print(ch, round(n / sr, 2), peak(0.05, 0.25) > 16, peak(0.30, 0.38) < 4, peak(0.45, 0.55) > 16, peak(0.63, 0.69) > 1.5 * peak(0.75, 0.95))
PY
)
[[ "$SE_W" == "2 1.0 True True True True" ]] && grep -q '_SNDOPEN("mix-sound.wav")' "$SE_T/bas/mix.bas" 2>/dev/null \
    && pass "mix.bas: the mix beside it as mix-sound.wav (stereo, 1 s; beat.wav and tone.wav where they are, silence between, added up where they overlap)" \
    || fail "BAS export of the mix: wav '$SE_W', '$(tr '\n' '|' <<< "$SE_OUT")'"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$SE_T"
assert_window_exists
