#!/bin/bash
# =============================================================================
# clip-bake-sound.sh — QA test: Bake Clip to Pixels keeps the clip's sounds
# (TOOLS/CLIP CLIP_bake, phase 2 K10).
#
# The fixture's clip gets step.wav on cel 1 and start.wav each time it starts
# over: 4 sounds (83 83 417 417 ms). Duplicate Layer: two clip layers.
#   - bake the top one, Yes (Enter): 4 soundtrack clips on track 1 at those
#     times; the other clip layer still sounds (4 generated)
#   - bake the other, Yes: 4 more on track 2 (track 1 is taken)
#   - Ctrl+Z, Ctrl+Z: both clips back, no soundtrack clips
#   - bake, No (Esc): baked, silent - no soundtrack clips
#
# Dump: ANIMSC n ... then per clip: trk at in len end; ANIMSCG; CLIP lines.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: Bake keeps the sounds ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
mkdir -p "$CL_DIR/snd"
python3 - "$CL_DIR/snd" <<'PY'
import sys, wave, struct, math
for name, hz, ms in (("step.wav", 440, 200), ("start.wav", 660, 300)):
    w = wave.open(f"{sys.argv[1]}/{name}", "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(22050)
    n = 22050 * ms // 1000
    w.writeframes(b"".join(struct.pack("<h", int(8000 * math.sin(2 * math.pi * hz * i / 22050))) for i in range(n))); w.close()
PY
cb_add() { # COMMAND FILE
    cl_cmd "$1"; wait_for 0.8 "the file dialog"
    type_text "$2"; wait_for 0.4 "typed"; key Return; wait_for 1.0 "picked"
}
cb_sc() { # the soundtrack clips: "trk:at ..." (n first)
    local a i o; read -r -a a <<< "$(cl_line ANIMSC)"
    o="${a[1]}"
    for (( i = 10; i + 4 < ${#a[@]} + 1; i += 5 )); do o+=" ${a[$i]}:${a[$((i + 1))]}"; done
    echo "$o"
}
cb_gn() { cl_line ANIMSCG | cut -d' ' -f2; }
cb_nclips() { grep -c '^CLIP ' "$CL_DUMPF"; }
cb_bake() { # ANSWER (Return = Yes, Escape = No)
    cl_cmd "clip layer: bake clip to pixels"; wait_for 0.8 "the question"
    key "$1"; wait_for 1.0 "answered"; cl_read
}

CL_EXTRA="--option LAST_DIR_OPEN=$CL_DIR/snd"
cl_setup
if (( CL_OK )); then
    cb_add "clip layer: sound on this cel" step.wav
    cb_add "clip layer: sound each time the clip starts over" start.wav
    cl_cmd "duplicate layer"; cl_read
    [[ "$(cb_gn)" == 8 && "$(cb_nclips)" == 2 ]] || fail "setup: two clip layers, 8 sounds - got $(cb_nclips) clips, [$(cl_line ANIMSCG)]"

    cb_bake Return
    [[ "$(cb_sc)" == "4 1:83 1:83 1:417 1:417" && "$(cb_nclips)" == 1 && "$(cb_gn)" == 4 ]] \
        && pass "bake, Yes: 4 soundtrack clips on track 1 (83 83 417 417 ms); the other clip still sounds" \
        || fail "bake keep: soundtrack [$(cb_sc)] clips $(cb_nclips) generated $(cb_gn)"
    screenshot "clip-bake-sound"
    click 60 "$(cl_row_y 2)"; wait_for 0.5 "the other clip layer"
    cb_bake Return
    [[ "$(cb_sc)" == "8 1:83 1:83 1:417 1:417 2:83 2:83 2:417 2:417" && "$(cb_nclips)" == 0 && "$(cb_gn)" == 0 ]] \
        && pass "the other, Yes: 4 more on track 2 (track 1 is taken)" || fail "second bake: [$(cb_sc)] clips $(cb_nclips) generated $(cb_gn)"
    cl_key ctrl+z; cl_read
    [[ "$(cb_sc)" == "4 1:83 1:83 1:417 1:417" && "$(cb_nclips)" == 1 ]] && pass "Ctrl+Z: one undo step - that clip and its sounds back" || fail "undo 2: [$(cb_sc)] clips $(cb_nclips)"
    cl_key ctrl+z; cl_read
    [[ "$(cb_sc)" == "0" && "$(cb_nclips)" == 2 && "$(cb_gn)" == 8 ]] && pass "Ctrl+Z: both clips, no soundtrack clips" || fail "undo 1: [$(cb_sc)] clips $(cb_nclips) generated $(cb_gn)"

    click 60 "$(cl_row_y 1)"; wait_for 0.5 "a clip layer"
    cb_bake Escape
    [[ "$(cb_sc)" == "0" && "$(cb_nclips)" == 1 && "$(cb_gn)" == 4 ]] && pass "bake, No: baked and silent, no soundtrack clips" || fail "bake no: [$(cb_sc)] clips $(cb_nclips) generated $(cb_gn)"
fi
cl_done
info "=== Clip layers: Bake keeps the sounds: done ==="
