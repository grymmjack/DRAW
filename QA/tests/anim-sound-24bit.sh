#!/bin/bash
# =============================================================================
# anim-sound-24bit.sh — QA test: 24-bit WAVs on the X-sheet, and SOUND rows
# as tall as the layer rows.
#
# Rick 2026-11-10 (a 24-bit WAV, "Classic Deep House Demo.wav", showed its
# name and no waveform): "i cannot see the sound waveform any more - can you
# please allow me to see that in relation to the layer row heights? like text
# can be what it is now (i love that) but also i'd love to see the soundwave."
#
# QB64-PE's _MEMSOUND gives no samples for 24-bit audio (it plays fine), so
# builds before had no waveform for such a file and left it out of a mix of
# clips (ANIMSC skipped). DRAW now reads the WAV itself (ANIM_SND_wav_load&).
# - both 24-bit files have waveform peaks; the mix of the two leaves none out
# - XSHEET_ROWS=SMALL: each SOUND row is a layer row tall (36 px), the clip's
#   name on its first text line, the waveform under it: loud frame 2 and
#   silent frame 7 differ there (old build: text-high rows, no waveform)
# - XSHEET_ROWS=TEXT (Ctrl+Shift+wheel down): SOUND rows a text row tall again,
#   the waveform still there (softer, the name over it)
#
# Silent: the WAVs are at -60 dB.
# Dump: ANIMSND (... peaks), ANIMSC (n sel track focus mixed skipped ...),
# ANIMXSS (the SOUND rows' y), ANIMXSF (per frame f x w), ANIMXS (... layH).
# Fixture: 8 frames of 16x16 at 10 fps; beat24.wav (1 s, sound 0-0.3 s) on
# track 1 at 0, tone24.wav (0.3 s) on track 2 at 200 ms (frames 3-5).
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 XSHEET_ROWS=SMALL XSHEET_ZOOM=0 XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0 ANIM_SOUND_VOLUME=0
# =============================================================================
info "=== Animation: 24-bit WAVs, SOUND rows the layer rows' height ==="

S2_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
S2_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
S2_T="$(mktemp -d /tmp/draw-qa-snd24-XXXXXX)"
magick -size 128x16 xc:none -fill "#c04040" -draw "rectangle 3,4 8,9" "PNG32:$S2_T/plain.png"
python3 - "$S2_T" <<'PY'
import struct, math, sys
sr = 44100
def wav24(path, n, amp): # stereo 24-bit PCM, with a LIST chunk before fmt (as recorders write)
    d = bytearray()
    for i in range(n):
        v = int(amp(i / sr) * math.sin(2 * math.pi * 330 * i / sr))
        b = struct.pack('<i', v)[:3]
        d += b + b
    lst = b'LIST' + struct.pack('<I', 4) + b'INFO'
    fmt = b'fmt ' + struct.pack('<IHHIIHH', 16, 1, 2, sr, sr * 6, 6, 24)
    body = b'WAVE' + lst + fmt + b'data' + struct.pack('<I', len(d)) + bytes(d)
    open(path, 'wb').write(b'RIFF' + struct.pack('<I', len(body)) + body)
wav24(sys.argv[1] + '/beat24.wav', sr, lambda t: 8388.0 if t < 0.3 else 0.0)   # -60 dB
wav24(sys.argv[1] + '/tone24.wav', int(sr * 0.3), lambda t: 8388.0)
PY
S2_BLOB=$(python3 - "$S2_T/beat24.wav" "$S2_T/tone24.wav" <<'PY'
import struct, sys
b, t = sys.argv[1].encode(), sys.argv[2].encode()
s = struct.pack('<10h', 7, 16, 16, 0, 0, 8, 1, 10, 0, 0) + struct.pack('<4h', 0, 0, 0, 0)
s += struct.pack('<h', len(b)) + b + struct.pack('<i', 0)                        # v6: clip 1
s += struct.pack('<h', 2)
for trk, at, p in ((1, 0, b), (2, 200, t)):
    s += struct.pack('<hiiih', trk, at, 0, 0, len(p)) + p                        # v7: every clip
print(s.hex())
PY
)
python3 "$S2_PY" put "$S2_T/plain.png" "$S2_T/sheet.png" drAn "$S2_BLOB"

s2_line() { grep -m1 "^$1 " "$S2_DUMP" 2>/dev/null; }
s2_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ S_OPEN _ _ _ S_LEN S_PK _ <<< "$(s2_line ANIMSND)"
    read -r _ C_N _ _ _ C_MIX C_SKIP _ <<< "$(s2_line ANIMSC)"
    XS_Y=($(s2_line ANIMXSS)); XF=($(s2_line ANIMXSF))
    read -r _ XON _ _ XY1 _ _ _ XRH _ _ _ _ _ _ _ _ XLH _ <<< "$(s2_line ANIMXS)"
}
s2_fx() { # FRAME -> "x w" of its span on the X-sheet
    local i
    for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do
        [[ "${XF[$i]}" == "$1" ]] && { echo "${XF[i + 1]} ${XF[i + 2]}"; return; }
    done
    echo "0 0"
}
s2_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$S2_T/sheet.png"
draw_launch 15
wait_for 2.0 "Sheet + 24-bit sounds loaded"
assert_no_crash
s2_key KP_0
s2_read; [[ "$XON" == -1 ]] || s2_key KP_8
s2_read
if [[ "$XON" != -1 || "${C_N:-}" != 2 ]]; then
    fail "X-sheet with 2 clips: on '$XON', clips '${C_N:-}'"
else
    # -- the 24-bit files' samples: a waveform, and both in the mix --
    (( ${S_PK:-0} >= 120 )) && pass "both 24-bit WAVs have waveforms ($S_PK peaks, 1.3 s of sound)" \
        || fail "24-bit WAVs: ${S_PK:-?} waveform peaks, wanted ~131 (no samples from _MEMSOUND before)"
    [[ "$C_MIX" == -1 && "$C_SKIP" == 0 ]] && pass "the two clips play as one mix, none left out" \
        || fail "the mix: mixed '$C_MIX', clips left out '$C_SKIP' (wanted -1, 0)"

    # -- SMALL rows: the SOUND rows a layer row tall --
    SH=$(( ${XS_Y[2]:-0} - ${XS_Y[1]:-0} ))
    [[ "$SH" == "$XLH" && "$XLH" -gt "$XRH" ]] && pass "XSHEET_ROWS=SMALL: SOUND rows $SH px, the layer rows' height (text rows $XRH)" \
        || fail "SOUND row height $SH px, wanted the layer rows' $XLH (text rows $XRH)"

    # -- the waveform under the name: loud frame 2 vs silent frame 7, track 1 --
    read -r F2X F2W <<< "$(s2_fx 2)"; read -r F7X F7W <<< "$(s2_fx 7)"
    WY=$(( XS_Y[1] + XRH + 1 )); WH=$(( XLH - XRH - 4 ))
    if (( F2W > 4 && F7W > 4 && WH > 2 )); then
        snap_region $(( F2X + 1 )) "$WY" $(( F2W - 2 )) "$WH" "snd24-loud"; A="$SNAP_RESULT"
        snap_region $(( F7X + 1 )) "$WY" $(( F2W - 2 )) "$WH" "snd24-quiet"; B="$SNAP_RESULT"
        assert_regions_differ "$A" "$B" "track 1's waveform: loud frame 2 differs from silent frame 7 under the name"
    else
        fail "frame spans: 2 '$F2X $F2W', 7 '$F7X $F7W', waveform height $WH"
    fi
    screenshot "snd24-small"

    # -- back to TEXT rows: SOUND rows a text row tall --
    s2_read
    GX=$(( F2X + F2W / 2 )); GY=$(( XY1 + 1 + XRH + XLH / 2 )) # the first layer row
    with_mods ctrl+shift scroll_down "$GX" "$GY"; wait_for 0.4 "Ctrl+Shift+wheel down"
    with_mods ctrl+shift scroll_down "$GX" "$GY"; wait_for 0.6 "Ctrl+Shift+wheel down"
    s2_read
    SH=$(( ${XS_Y[2]:-0} - ${XS_Y[1]:-0} ))
    [[ "$SH" == "$XRH" && "$XLH" == "$XRH" ]] && pass "XSHEET_ROWS=TEXT: SOUND rows a text row ($SH px) again" \
        || fail "TEXT rows: SOUND row $SH px, layer rows $XLH, text rows $XRH"
    # the waveform still shows there, softer, under the name (past it: frame 3)
    read -r F3X F3W <<< "$(s2_fx 3)"; read -r F7X F7W <<< "$(s2_fx 7)"
    if (( F3W > 4 && F7W > 4 )); then
        snap_region $(( F3X + 1 )) $(( XS_Y[1] + 3 )) $(( F3W - 2 )) $(( XRH - 6 )) "snd24-text-loud"; A="$SNAP_RESULT"
        snap_region $(( F7X + 1 )) $(( XS_Y[1] + 3 )) $(( F3W - 2 )) $(( XRH - 6 )) "snd24-text-quiet"; B="$SNAP_RESULT"
        assert_regions_differ "$A" "$B" "TEXT rows: the waveform still shows (loud frame 3 differs from silent frame 7)"
    else
        fail "frame spans at TEXT rows: 3 '$F3X $F3W', 7 '$F7X $F7W'"
    fi
    screenshot "snd24-text"
fi
assert_no_crash
rm -rf "$S2_T"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
assert_window_exists
