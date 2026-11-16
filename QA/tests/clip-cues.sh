#!/bin/bash
# =============================================================================
# clip-cues.sh — QA test: a clip's sound cues, the data (TOOLS/CLIP, phase 2
# K7): ANIM > Clip Layer > Sound on This Cel / When the Clip Starts / Each Time
# the Clip Starts Over / Remove the Clip's Sounds.
#
#   - frame 2 shows cel 1: Sound on This Cel (step.wav) = a cue on cel 1;
#     frame 4 (cel 3) the same file = a cue on cel 3; again on cel 3: refused
#   - Sound When the Clip Starts (start.wav): a ONCE cue; Ctrl+Z / Ctrl+Y
#   - frame 1 (no cel there): Sound on This Cel refused, no file dialog
#   - Update from AnimBrush: the new source has the same cues
#   - Ctrl+S, reload: the cues are back (drCl version 2)
#   - Remove the Clip's Sounds: none; Ctrl+Z: all three
#
# Dump: CLIP / CLIPC (clip-lib.sh), CLIPQ src kind cel name (each cue).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: sound cues (data) ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
mkdir -p "$CL_DIR/snd"
python3 - "$CL_DIR/snd" <<'PY'
import sys, wave, struct, math
for name, hz, ms in (("step.wav", 440, 200), ("start.wav", 660, 300)):
    w = wave.open(f"{sys.argv[1]}/{name}", "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(22050)
    n = 22050 * ms // 1000
    w.writeframes(b"".join(struct.pack("<h", int(8000 * math.sin(2 * math.pi * hz * i / 22050))) for i in range(n))); w.close()
PY
cq_cues() { grep '^CLIPQ ' "$CL_DUMPF" | cut -d' ' -f2- | tr '\n' '|' | sed 's/|$//'; }
cq_of() { grep "^CLIPQ $1 " "$CL_DUMPF" | cut -d' ' -f3- | tr '\n' '|' | sed 's/|$//'; }
cq_add() { # COMMAND FILE - the command, then the file dialog: the file's name, Enter
    cl_cmd "$1"; wait_for 0.8 "the file dialog"
    type_text "$2"; wait_for 0.4 "typed"; key Return; wait_for 1.0 "picked"
    cl_read
}

CL_EXTRA="--option LAST_DIR_OPEN=$CL_DIR/snd"
cl_setup
if (( CL_OK )); then
    [[ -z "$(cq_cues)" ]] && pass "a new clip has no sounds" || fail "cues at the start [$(cq_cues)]"

    cq_add "clip layer: sound on this cel" step.wav
    [[ "$(cq_cues)" == "1 0 1 step.wav" ]] && pass "frame 2 (cel 1): Sound on This Cel - a cue on cel 1" || fail "cue on cel 1: [$(cq_cues)] $(cl_s)"
    cl_strip 4; cl_read
    cq_add "clip layer: sound on this cel" step.wav
    [[ "$(cq_cues)" == "1 0 1 step.wav|1 0 3 step.wav" ]] && pass "frame 4 (cel 3): a second cue, on cel 3" || fail "cue on cel 3: [$(cq_cues)]"
    cq_add "clip layer: sound on this cel" step.wav
    [[ "$(cq_cues)" == "1 0 1 step.wav|1 0 3 step.wav" ]] && pass "the same sound on cel 3 again: refused" || fail "duplicate cue: [$(cq_cues)]"

    cq_add "clip layer: sound when the clip starts" start.wav
    W3="1 0 1 step.wav|1 0 3 step.wav|1 1 0 start.wav"
    [[ "$(cq_cues)" == "$W3" ]] && pass "Sound When the Clip Starts: a ONCE cue" || fail "once cue: [$(cq_cues)]"
    cl_key ctrl+z; cl_read
    [[ "$(cq_cues)" == "1 0 1 step.wav|1 0 3 step.wav" ]] && pass "Ctrl+Z: the ONCE cue goes" || fail "undo the once cue: [$(cq_cues)]"
    cl_key ctrl+y; cl_read
    [[ "$(cq_cues)" == "$W3" ]] && pass "Ctrl+Y: it is back" || fail "redo the once cue: [$(cq_cues)]"

    # -- frame 1: the clip shows no cel there --
    cl_strip 1; cl_read
    cl_cmd "clip layer: sound on this cel"; wait_for 0.8 "refused?"
    cl_read
    [[ "$(cq_cues)" == "$W3" ]] && pass "frame 1 (no cel there): Sound on This Cel refused" || fail "cue on frame 1: [$(cq_cues)]"
    key Escape; wait_for 0.5 "(a dialog, if one opened)"
    screenshot "clip-cues-added"

    # -- Update from AnimBrush: a new source, the same cues --
    cl_cmd "clip layer: update clip from animbrush"; cl_read
    [[ "$C_SRC" == 2 && "$(cq_of 2)" == "0 1 step.wav|0 3 step.wav|1 0 start.wav" ]] && pass "Update from AnimBrush: source 2 has the same three sounds" \
        || fail "update: $(cl_s); cues [$(cq_cues)]"
    cl_key ctrl+z; cl_read
    [[ "$C_SRC" == 1 && "$(cq_of 1)" == "0 1 step.wav|0 3 step.wav|1 0 start.wav" ]] && pass "Ctrl+Z: source 1, its sounds" || fail "undo update: $(cl_s); cues [$(cq_cues)]"

    # -- save, reload --
    wake_draw
    key ctrl+s; wait_for 2.0 "saved"
    draw_quit; draw_settle
    draw_launch 15
    wait_for 1.5 "Reloaded"
    assert_no_crash
    cl_read
    [[ "$(cq_cues)" == "$W3" ]] && pass "Ctrl+S, reload: the three sounds are back (drCl 2)" || fail "reload: [$(cq_cues)] $(cl_s)"

    # -- remove --
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "the clip layer"
    cl_cmd "clip layer: remove the clip's sounds"; cl_read
    [[ -z "$(cq_cues)" ]] && pass "Remove the Clip's Sounds: none" || fail "remove: [$(cq_cues)]"
    cl_key ctrl+z; cl_read
    [[ "$(cq_cues)" == "$W3" ]] && pass "Ctrl+Z: all three again" || fail "undo remove: [$(cq_cues)]"
fi
cl_done
info "=== Clip layers: sound cues (data): done ==="
