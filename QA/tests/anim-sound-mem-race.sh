#!/bin/bash
# =============================================================================
# anim-sound-mem-race.sh — QA test: adding sounds to the X-sheet again and
# again never ends DRAW with "Memory has been freed" (Rick 2026-11-09: File >
# New Animation 32x32 8, a mod dropped on it, FPS down to 1, then right-click
# SOUND > Add Sound... - "Critical Error: Line: 174 (in ANIM-SOUND.BM) Memory
# has been freed").
#
# The cause is in QB64-PE: a sound that _MEMSOUND has read keeps a memory lock,
# and _SNDCLOSE has QB64-PE free that lock later on its own display thread,
# while DRAW's thread takes and frees locks too (_MEMSOUND, _MEMIMAGE,
# _FREEIMAGE) - the lock pool has no mutex, so one lock can be handed out
# twice, and reading through the other owner is a critical _MEM error (300-315)
# that ON ERROR can't trap. Every new set of clips closes the files' sounds
# and the last mix (both read by _MEMSOUND) and opens new ones, so each drop
# here is one more chance for it. The fix waits for those frees
# (ANIM_SND_let_go) and checks _MEMEXISTS before every read of sound memory.
#
# It is a race: the old build died in about half the runs of a 3-drop repro.
# This test makes 8 drops of new files (each one closes and reopens them all).
#
# Silent: the WAVs are at -60 dB and ANIM_SOUND_VOLUME=0.
# Fixture: a 256x32 sheet of 32x32 frames, 8 frames at 1 fps.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: adding sounds again and again (the sound memory race) ==="

MR_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
MR_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
MR_T="$(mktemp -d /tmp/draw-qa-memrace-XXXXXX)"
magick -size 256x32 xc:none "PNG32:$MR_T/plain.png"
python3 - "$MR_T" <<'PY'
import struct, math, sys
sr = 44100
def wav(path, n, ch):
    one = [struct.pack('<h', int(32 * math.sin(2 * math.pi * 220 * i / sr))) for i in range(sr)]   # -60 dB
    d = b''.join(one[i % sr] * ch for i in range(n))
    open(path, 'wb').write(b'RIFF' + struct.pack('<I', 36 + len(d)) + b'WAVEfmt ' + struct.pack('<IHHIIHH', 16, 1, ch, sr, sr * 2 * ch, 2 * ch, 16) + b'data' + struct.pack('<I', len(d)) + d)
wav(sys.argv[1] + '/long.wav', sr * 60, 2)           # a minute, stereo: a long mix
for k in range(1, 8):
    wav(sys.argv[1] + '/s%d.wav' % k, int(sr * (0.5 + k / 10)), 1)   # mono, each a new file
PY
MR_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,32,32,0,0,8,1,1,0,0).hex())")
python3 "$MR_PY" put "$MR_T/plain.png" "$MR_T/sheet.png" drAn "$MR_BLOB"

mr_line() { grep -m1 "^$1 " "$MR_DUMP" 2>/dev/null; }
mr_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    XS_Y=($(mr_line ANIMXSS)); XF=($(mr_line ANIMXSF)); read -r _ _ XS_ON X1 Y1 X2 Y2 _ XRH _ <<< "$(mr_line ANIMXS)"
    local sc=($(mr_line ANIMSC)); C_N=${sc[1]:-}
}
mr_fx() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
mr_ry() { echo $(( XS_Y[$1] + XRH / 2 )); }
mr_drop() { # FILE FRAME TRACK
    mr_read; hover "$(mr_fx "$2")" "$(mr_ry "$3")"; wait_for 0.3 "pointer at frame $2"
    echo "$1" > "$MR_DUMP.drop"
    wait_for 2.5 "drop $(basename "$1")"
    mr_read
}
mr_alive() { kill -0 "$DRAW_PID" 2>/dev/null; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$MR_T/sheet.png --option ANIM_SOUND_VOLUME=0"
draw_launch 15
wait_for 1.5 "sheet loaded"
assert_no_crash
rm -f "$MR_DUMP.drop"
park_mouse; key ctrl+0; wait_for 0.5 "fit"
mr_read
[[ "$XS_ON" == -1 ]] || { park_mouse; key KP_8; wait_for 0.6 "X-sheet"; mr_read; }

if [[ "$XS_ON" != -1 ]]; then
    fail "the X-sheet did not open (ANIMXS '$(mr_line ANIMXS)')"
else
    mr_drop "$MR_T/long.wav" 1 1
    MR_OK=1; MR_DIED=""
    for k in 1 2 3 4 5 6 7; do
        mr_alive || { MR_OK=0; MR_DIED="before drop $k"; break; }
        mr_drop "$MR_T/s$k.wav" $(( k + 1 )) 1
    done
    mr_alive || { MR_OK=0; MR_DIED=${MR_DIED:-"after the last drop"}; }
    if [[ "$MR_OK" == 1 && "$C_N" == 8 ]]; then
        pass "8 sounds added one by one (each reopening the files and making a new mix): DRAW still up, 8 clips"
    elif [[ "$MR_OK" == 1 ]]; then
        fail "DRAW still up, but $C_N clips (wanted 8): $(mr_line ANIMSC)"
    else
        fail "DRAW died $MR_DIED: $(grep -m1 -iE 'Runtime error' "$DRAW_CONSOLE_LOG" 2>/dev/null; grep -m1 -iE 'Memory|Line:' "$DRAW_CONSOLE_LOG" 2>/dev/null)"
    fi
    screenshot "anim-sound-mem-race"
fi
assert_no_crash

rm -f "$MR_DUMP.drop"
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$MR_T"
assert_window_exists
