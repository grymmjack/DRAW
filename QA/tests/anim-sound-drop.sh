#!/bin/bash
# =============================================================================
# anim-sound-drop.sh — QA test: a SOUND row on every animation, sound files
# dropped on the X-sheet, empty tracks (Rick 2026-11-09: "i would like to be
# able to drag/drop a sound onto the x-sheet to create a sound track, i'd also
# like to be able to create a new soundtrack as silence, to be able to drag it
# on ... we could just have soundtrack on all animations and if it's empty, do
# nothing with it").
#
# The X-sheet always has a SOUND row; an empty one says "drop a sound file
# here, or right-click" and is silence (nothing played, saved or exported).
# A sound file dropped on a SOUND row goes on that track from the frame under
# the pointer; dropped anywhere else (here the canvas) it goes on a new track
# from the current frame. Right-click > Add Empty Track adds a silent row,
# Remove Track takes one away (the tracks under it move up). One undo step
# each.
#
# OS drops can't be made under Xvfb: with DOCK_DUMP set, DRAW reads a path
# from <DOCK_DUMP>.drop and queues it exactly as an OS drop (INPUT/DROP.BM
# DROP_qa_poll -> DROP_queue_dropped_file -> DROP_handle_dropped_file, which
# reads the pointer). The old build had no SOUND row without sound, no drop
# route for sound files (and no stand-in drop), no empty tracks.
#
# Silent: the WAVs are at -60 dB and ANIM_SOUND_VOLUME=0.
#
# Dump: ANIMSC n sel track focus mixed skipped clipN clipSpan dragging, then
# per clip track at in len end (ms); ANIMXSS the SOUND rows' y; ANIMXSF per
# frame f x w; ANIMSCM the menu (x y w, then action y per item).
# Fixture: a 128x16 sheet of 16x16 frames, 8 frames at 10 fps (frame k starts
# at (k - 1) * 100 ms), no sound; beat.wav 1 s, tone.wav 0.3 s.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: sound files dropped on the X-sheet, empty SOUND tracks ==="

SD_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
SD_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
SD_T="$(mktemp -d /tmp/draw-qa-snddrop-XXXXXX)"
mkdir -p "$SD_T/snd"
magick -size 128x16 xc:none -fill "#c04040" -draw "rectangle 3,4 8,9" -fill "#40c040" -draw "rectangle 20,4 25,9" "PNG32:$SD_T/plain.png"
python3 - "$SD_T/snd" <<'PY'
import struct, math, sys
sr = 22050
def wav(path, n):
    d = b''.join(struct.pack('<h', int(32 * math.sin(2 * math.pi * 330 * i / sr))) for i in range(n))   # -60 dB
    open(path, 'wb').write(b'RIFF' + struct.pack('<I', 36 + len(d)) + b'WAVEfmt ' + struct.pack('<IHHIIHH', 16, 1, 1, sr, sr * 2, 2, 16) + b'data' + struct.pack('<I', len(d)) + d)
wav(sys.argv[1] + '/beat.wav', sr)
wav(sys.argv[1] + '/tone.wav', int(sr * 0.3))
PY
SD_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,8,1,10,0,0).hex())")
python3 "$SD_PY" put "$SD_T/plain.png" "$SD_T/sheet.png" drAn "$SD_BLOB"

sd_line() { grep -m1 "^$1 " "$SD_DUMP" 2>/dev/null; }
sd_read() { # A_CUR, C_* + CL[] (per clip "trk at in len"), XS_Y[] (the SOUND rows' y), XF[], XRH, X1..Y2, SCM[]
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ _ A_CUR _ <<< "$(sd_line ANIM)"
    local sc=($(sd_line ANIMSC)) i
    C_N=${sc[1]:-}; C_SEL=${sc[2]:-}; C_TRK=${sc[3]:-}
    CL=()
    for (( i = 0; i < ${C_N:-0}; i++ )); do CL+=("${sc[$((10 + i * 5))]} ${sc[$((11 + i * 5))]} ${sc[$((12 + i * 5))]} ${sc[$((13 + i * 5))]}"); done
    XS_Y=($(sd_line ANIMXSS)); XF=($(sd_line ANIMXSF)); SCM=($(sd_line ANIMSCM))
    read -r _ _ XS_ON X1 Y1 X2 Y2 _ XRH _ <<< "$(sd_line ANIMXS)"
}
sd_rows() { echo $(( ${#XS_Y[@]} > 0 ? ${#XS_Y[@]} - 1 : 0 )); }
sd_s() { local IFS='|'; echo "clips ${C_N:-?} [${CL[*]}] sel ${C_SEL:-?} track ${C_TRK:-?}; frame ${A_CUR:-?}; SOUND rows $(sd_rows) (y ${XS_Y[*]:1})"; }
sd_fx() { # FRAME -> the middle x of its span on the X-sheet
    local i
    for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do
        [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }
    done
    echo 0
}
sd_ry() { echo $(( XS_Y[$1] + XRH / 2 )); } # TRACK -> its row's middle y
sd_drop() { # FILE X Y - the pointer at (X, Y), then the stand-in OS drop of FILE
    hover "$2" "$3"; wait_for 0.3 "pointer at the drop point"
    echo "$1" > "$SD_DUMP.drop"
    wait_for 1.2 "drop $(basename "$1")"
    sd_read
}
sd_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
sd_menu() { # TRACK FRAME ACTION -> right-click the SOUND row there, pick ACTION; FALSE when it is not in the menu (or greyed)
    local x y i my=""
    sd_read; x=$(sd_fx "$2"); y=$(sd_ry "$1")
    click "$x" "$y" 3; wait_for 0.6 "SOUND menu"; sd_read
    for (( i = 4; i + 1 < ${#SCM[@]}; i += 2 )); do [[ "${SCM[$i]}" == "$3" ]] && my=${SCM[$((i + 1))]}; done
    if [[ -z "$my" ]]; then key Escape; wait_for 0.3 "close"; return 1; fi
    click $(( SCM[1] + 12 )) $(( my + 6 )); wait_for 0.6 "menu item $3"; sd_read
}

info "Launching DRAW with an 8-frame sheet that has no sound"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$SD_T/sheet.png --option ANIM_SOUND_VOLUME=0"
draw_launch 15
wait_for 1.5 "sheet loaded"
assert_no_crash
rm -f "$SD_DUMP.drop"
sd_key ctrl+0
sd_read
[[ "$XS_ON" == -1 ]] || sd_key KP_8
sd_read

if [[ "$XS_ON" != -1 ]]; then
    fail "the X-sheet did not open (ANIMXS '$(sd_line ANIMXS)')"
elif [[ "$(sd_rows)" != 1 || "$C_N" != 0 ]]; then
    fail "no sound: one empty SOUND row: $(sd_s)"
else
    pass "no sound yet: the X-sheet still has one (empty) SOUND row"
    W=$(( XF[3] > 4 ? XF[3] : 8 ))
    snap_region $(( $(sd_fx 3) - W / 2 + 1 )) $(( XS_Y[1] + 3 )) $(( W - 2 )) $(( XRH - 6 )) "row1-empty"; E3=$SNAP_RESULT

    # -- drop beat.wav on SOUND 1 at frame 3: track 1 from 200 ms --
    sd_drop "$SD_T/snd/beat.wav" "$(sd_fx 3)" "$(sd_ry 1)"
    [[ "$C_N" == 1 && "${CL[0]}" == "1 200 0 0" && "$(sd_rows)" == 1 ]] \
        && pass "drop beat.wav on SOUND 1 over frame 3: a clip on track 1 from 200 ms" || fail "drop on SOUND 1: $(sd_s)"
    snap_region $(( $(sd_fx 3) - W / 2 + 1 )) $(( XS_Y[1] + 3 )) $(( W - 2 )) $(( XRH - 6 )) "row1-beat"; B3=$SNAP_RESULT
    assert_regions_differ "$E3" "$B3" "SOUND 1 under frame 3: the clip's waveform where the row was empty"
    sd_key ctrl+z; sd_read
    [[ "$C_N" == 0 && "$(sd_rows)" == 1 ]] && pass "undo: the clip gone, the empty SOUND row stays" || fail "undo the drop: $(sd_s)"
    sd_key ctrl+y; sd_read
    [[ "$C_N" == 1 && "${CL[0]}" == "1 200 0 0" ]] || fail "redo the drop: $(sd_s)"

    # -- right-click > Add Empty Track: a second, silent row --
    if sd_menu 1 5 2560; then
        [[ "$(sd_rows)" == 2 && "$C_N" == 1 ]] && pass "right-click > Add Empty Track: SOUND 2, empty" || fail "Add Empty Track: $(sd_s)"
    else
        fail "right-click on SOUND 1: no Add Empty Track (${SCM[*]})"
    fi

    # -- drop tone.wav on the empty SOUND 2 at frame 5: track 2 from 400 ms --
    sd_drop "$SD_T/snd/tone.wav" "$(sd_fx 5)" "$(sd_ry 2)"
    [[ "$C_N" == 2 && "${CL[1]}" == "2 400 0 0" && "$(sd_rows)" == 2 ]] \
        && pass "drop tone.wav on the empty SOUND 2 over frame 5: track 2 from 400 ms" || fail "drop on SOUND 2: $(sd_s)"

    # -- dropped off the X-sheet (the canvas): a new track from the current frame --
    F0=${A_CUR:-1}
    CY=$(( Y1 > 120 ? Y1 / 2 : Y2 + (480 - Y2) / 2 ))
    sd_drop "$SD_T/snd/tone.wav" $(( (X1 + X2) / 2 )) "$CY"
    [[ "$C_N" == 3 && "${CL[2]}" == "3 $(( (F0 - 1) * 100 )) 0 0" && "$(sd_rows)" == 3 ]] \
        && pass "drop tone.wav on the canvas at frame $F0: a new track 3 from $(( (F0 - 1) * 100 )) ms" || fail "drop off the X-sheet (y $CY, frame $A_CUR): $(sd_s)"
    sd_key ctrl+z; sd_read
    [[ "$C_N" == 2 && "$(sd_rows)" == 2 ]] || fail "undo the canvas drop: $(sd_s)"

    # -- Remove Track on SOUND 1: beat.wav goes, tone.wav moves up to track 1 --
    if sd_menu 1 2 2561; then
        [[ "$C_N" == 1 && "${CL[0]}" == "1 400 0 0" && "$(sd_rows)" == 1 ]] \
            && pass "right-click SOUND 1 > Remove Track: its clip gone, tone.wav up on track 1" || fail "Remove Track: $(sd_s)"
        sd_key ctrl+z; sd_read
        [[ "$C_N" == 2 && "${CL[0]}" == "1 200 0 0" && "${CL[1]}" == "2 400 0 0" ]] && pass "undo: both tracks back" || fail "undo Remove Track: $(sd_s)"
    else
        fail "right-click on SOUND 1: no Remove Track (${SCM[*]})"
    fi
    screenshot "anim-sound-drop"
fi
assert_no_crash

rm -f "$SD_DUMP.drop"
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$SD_T"
assert_window_exists
