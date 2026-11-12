#!/bin/bash
# =============================================================================
# clip-cues-play.sh — QA test: a clip's sound cues play (TOOLS/CLIP
# CLIP_cues_gen, TOOLS/ANIM-SOUND; phase 2 K8).
#
# The fixture's clip (frames 2-6, 4 cels: .12341 at 12 fps, frame f at
# (f-1)*1000/12 ms) gets step.wav on cel 1 and on cel 3, start.wav each time
# it starts over:
#   - generated clips (ANIMSCG): step 83 / start 83 / step 250 / step 417 /
#     start 417 ms; the soundtrack is a mix (ANIMSC)
#   - Num Enter plays it (ANIMSND starts)
#   - Mode Once: no restart, cel 1 once - step 83 / start 83 / step 250
#   - Ctrl+S, then the batch BAS export: NAME-sound.wav is the mix - silent
#     before 83 ms, sound right after it
#   - Duplicate Layer: 10; the duplicate hidden (its eye): 5; shown: 10
#
# Dump: ANIMSCG n (slot ms file)..., ANIMSC, ANIMSND, LAYER, CLIPQ.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: sound cues play ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
mkdir -p "$CL_DIR/snd"
python3 - "$CL_DIR/snd" <<'PY'
import sys, wave, struct, math
for name, hz, ms in (("step.wav", 440, 200), ("start.wav", 660, 300)):
    w = wave.open(f"{sys.argv[1]}/{name}", "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(22050)
    n = 22050 * ms // 1000
    w.writeframes(b"".join(struct.pack("<h", int(8000 * math.sin(2 * math.pi * hz * i / 22050))) for i in range(n))); w.close()
PY
cp_gen() { cl_line ANIMSCG | cut -d' ' -f2-; }          # n slot ms file ...
cp_times() { local a; read -r -a a <<< "$(cp_gen)"; local i o=""; for (( i = 1; i + 2 < ${#a[@]} + 1; i += 3 )); do o+="${a[$((i + 1))]}:${a[$((i + 2))]} "; done; echo "${o% }"; }
cp_add() { # COMMAND FILE
    cl_cmd "$1"; wait_for 0.8 "the file dialog"
    type_text "$2"; wait_for 0.4 "typed"; key Return; wait_for 1.0 "picked"
    cl_read
}

CL_EXTRA="--option LAST_DIR_OPEN=$CL_DIR/snd"
cl_setup
if (( CL_OK )); then
    cp_add "clip layer: sound on this cel" step.wav               # frame 2: cel 1
    cl_strip 4; cl_read
    cp_add "clip layer: sound on this cel" step.wav               # frame 4: cel 3
    cp_add "clip layer: sound each time the clip starts over" start.wav
    [[ "$(grep -c '^CLIPQ ' "$CL_DUMPF")" == 3 ]] || fail "three cues: $(grep '^CLIPQ ' "$CL_DUMPF" | tr '\n' '|')"
    W5="83:step.wav 83:start.wav 250:step.wav 417:step.wav 417:start.wav"
    [[ "$(cp_times)" == "$W5" ]] && pass "the cues as soundtrack clips: $W5" || fail "generated [$(cp_gen)] want [$W5]"
    read -r _ _ _ _ _ SC_MIX _ <<< "$(cl_line ANIMSC)"
    read -r _ SND_H _ SND_STARTS _ <<< "$(cl_line ANIMSND)"
    [[ "$SC_MIX" == -1 && "$SND_H" == -1 ]] && pass "they make the mix DRAW plays" || fail "no mix: $(cl_line ANIMSC) | $(cl_line ANIMSND)"

    cl_strip 1; cl_read
    cl_key KP_Enter; wait_for 1.0 "playing"; cl_read
    read -r _ _ _ SND_STARTS2 _ <<< "$(cl_line ANIMSND)"
    (( ${SND_STARTS2:-0} > ${SND_STARTS:-0} )) && pass "Num Enter: the sound starts with the frames" || fail "play: starts ${SND_STARTS:-?} -> ${SND_STARTS2:-?} | $(cl_line ANIMSND)"
    cl_key KP_Enter; wait_for 0.5 "stopped"

    # -- Mode Once --
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "the clip layer"
    cl_cmd "clip layer: mode once"; cl_read
    W3="83:step.wav 83:start.wav 250:step.wav"
    [[ "$C_MODE" == ONCE && "$(cp_times)" == "$W3" ]] && pass "Mode Once: no restart - $W3" || fail "once: $(cl_s) [$(cp_gen)] want [$W3]"
    cl_key ctrl+z; cl_read
    [[ "$(cp_times)" == "$W5" ]] && pass "Ctrl+Z: Loop again, five" || fail "undo once: [$(cp_gen)]"
    screenshot "clip-cues-play"

    # -- the BAS export's soundtrack --
    wake_draw
    key ctrl+s; wait_for 2.0 "saved"
    cl_batch "$CL_DIR/clip.draw" --export-anim "$CL_DIR/o/walk.bas"
    if [[ -s "$CL_DIR/o/walk-sound.wav" ]]; then
        ON=$(python3 - "$CL_DIR/o/walk-sound.wav" <<'PY'
import sys, wave, struct
w = wave.open(sys.argv[1]); r = w.getframerate(); ch = w.getnchannels(); n = w.getnframes()
d = struct.unpack(f"<{n * ch}h", w.readframes(n))
first = next((i // ch for i, v in enumerate(d) if abs(v) > 200), -1)
print(int(first * 1000 / r) if first >= 0 else -1, int(n * 1000 / r))
PY
)
        read -r ON_MS LEN_MS <<< "$ON"
        (( ON_MS >= 80 && ON_MS <= 90 && LEN_MS >= 700 )) && pass "the BAS export's walk-sound.wav: silent until ${ON_MS} ms (frame 2), ${LEN_MS} ms long" \
            || fail "walk-sound.wav: first sound at ${ON_MS} ms, ${LEN_MS} ms long"
    else
        fail "no walk-sound.wav: $(command ls "$CL_DIR/o" | tr '\n' ' ') | $(tail -3 "$CL_DIR/batch.txt" | tr '\n' ' ')"
    fi
    # -- two layers, one hidden --
    cl_cmd "duplicate layer"; cl_read
    read -r GN _ <<< "$(cp_gen)"
    [[ "$GN" == 10 ]] && pass "Duplicate Layer: both clip layers sound (10)" || fail "after duplicate: [$(cp_gen)]"
    click 7 "$(cl_row_y 1)"; wait_for 0.6 "the eye"; cl_read
    read -r GN _ <<< "$(cp_gen)"
    [[ "$GN" == 5 ]] && pass "the duplicate hidden: only the other sounds (5)" || fail "hidden: [$(cp_gen)] | $(grep '^LAYER ' "$CL_DUMPF" | tr '\n' '|')"
    click 7 "$(cl_row_y 1)"; wait_for 0.6 "the eye"; cl_read
    read -r GN _ <<< "$(cp_gen)"
    [[ "$GN" == 10 ]] && pass "shown again: 10" || fail "shown: [$(cp_gen)]"

fi
cl_done
info "=== Clip layers: sound cues play: done ==="
