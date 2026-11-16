#!/bin/bash
# =============================================================================
# clip-cues-ui.sh — QA test: a clip's sounds in the Animation panel and the
# X-sheet (GUI/ANIM-PANEL, TOOLS/ANIM-XS, TOOLS/CLIP; phase 2 K9).
#
#   - the panel's SOUND row: CEL (frame 2 shows cel 1) adds step.wav on cel 1,
#     START adds start.wav at the start; the list picks the new one (2/2)
#   - the list's < / >: the picked sound; X removes it; Ctrl+Z puts it back
#   - the X-sheet: a read-only SOUND row under the clip layer, a mark at each
#     sound's start (83 83 417 ms); a press + drag on it moves nothing
#   - the clip layer hidden: its SOUND row says it is muted (no marks)
#
# Dump: CLIPQ / CLIPQP (the picked sound), ANIMPC (chip x w of the clip rows),
# ANIMPM (row tops), ANIMXSQ slot y heard ms... (the SOUND row).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Clip layers: sounds in the panel and the X-sheet ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
mkdir -p "$CL_DIR/snd"
python3 - "$CL_DIR/snd" <<'PY'
import sys, wave, struct, math
for name, hz, ms in (("step.wav", 440, 200), ("start.wav", 660, 300)):
    w = wave.open(f"{sys.argv[1]}/{name}", "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(22050)
    n = 22050 * ms // 1000
    w.writeframes(b"".join(struct.pack("<h", int(8000 * math.sin(2 * math.pi * hz * i / 22050))) for i in range(n))); w.close()
PY
cu_cues() { grep '^CLIPQ ' "$CL_DUMPF" | cut -d' ' -f2- | tr '\n' '|' | sed 's/|$//'; }
cu_pick() { cl_line CLIPQP | cut -d' ' -f2; }
cu_chip() { # ROW (7 8 9) K - click that chip of the clip rows
    cl_read
    local pc i x w y="PM_Y$1"
    read -r -a pc <<< "$(cl_line ANIMPC)"
    case $1 in 7) i=$(( 2 + 2 * $2 )) ;; 8) i=$(( 10 + 2 * $2 )) ;; 9) i=$(( 16 + 2 * $2 )) ;; esac
    x=${pc[$i]}; w=${pc[$((i + 1))]}
    [[ -n "$x" && -n "$w" ]] || { info "no chip $1/$2: ${pc[*]}"; return 1; }
    cl_hclick "$(( P_X + (x + w / 2) * P_SC / 100 ))" "$(( P_Y + (${!y} + L_RH / 2) * P_SC / 100 ))"
    cl_read
}
cu_add() { # K FILE - a SOUND row chip, then the file dialog
    cu_chip 8 "$1"; wait_for 0.8 "the file dialog"
    type_text "$2"; wait_for 0.4 "typed"; key Return; wait_for 1.0 "picked"
    cl_read
}
cu_xsq() { cl_line ANIMXSQ | cut -d' ' -f2-; }   # slot y heard ms...

CL_EXTRA="--option LAST_DIR_OPEN=$CL_DIR/snd"
cl_setup
if (( CL_OK )); then
    [[ "$(cu_pick)" == 0 ]] && pass "no sounds: the list is empty" || fail "pick at the start: $(cu_pick)"
    cu_add 0 step.wav
    [[ "$(cu_cues)" == "1 0 1 step.wav" && "$(cu_pick)" == 1 ]] && pass "SOUND row CEL: step.wav on cel 1 (frame 2 shows it), listed" || fail "CEL chip: [$(cu_cues)] pick $(cu_pick)"
    cu_add 1 start.wav
    [[ "$(cu_cues)" == "1 0 1 step.wav|1 1 0 start.wav" && "$(cu_pick)" == 2 ]] && pass "SOUND row START: start.wav at the start, the list shows it (2/2)" || fail "START chip: [$(cu_cues)] pick $(cu_pick)"
    screenshot "clip-cues-ui-panel"

    cu_chip 9 0
    [[ "$(cu_pick)" == 1 ]] && pass "the list's <: sound 1" || fail "<: pick $(cu_pick)"
    cu_chip 9 1
    [[ "$(cu_pick)" == 2 ]] && pass "the list's >: sound 2" || fail ">: pick $(cu_pick)"
    cu_chip 9 2
    [[ "$(cu_cues)" == "1 0 1 step.wav" && "$(cu_pick)" == 1 ]] && pass "the list's X: start.wav removed" || fail "X: [$(cu_cues)] pick $(cu_pick)"
    cl_key ctrl+z; cl_read
    [[ "$(cu_cues)" == "1 0 1 step.wav|1 1 0 start.wav" ]] && pass "Ctrl+Z: it is back" || fail "undo X: [$(cu_cues)]"

    # -- the X-sheet --
    cl_key KP_8; cl_read
    read -r XQ_SLOT XQ_Y XQ_HEARD XQ_MS <<< "$(cu_xsq)"
    [[ -n "$XQ_SLOT" && "$XQ_HEARD" == -1 && "$XQ_MS" == "83 83 417" ]] && pass "the X-sheet: a SOUND row under the clip layer, marks at 83 83 417 ms" || fail "SOUND row: [$(cu_xsq)] | $(cl_line ANIMXSCL)"
    screenshot "clip-cues-ui-xsheet"
    if [[ -n "$XQ_Y" ]]; then
        B0="$C_LINE"
        read -r _ _ _ XA XB _ <<< "$(cl_line ANIMXSCL)"
        y=$(( XQ_Y + 8 )); x0=$(( (XA + XB) / 2 ))
        mouse_down "$x0" "$y"; hover $(( x0 + 20 )) "$y"; sleep 0.2; hover $(( x0 + 40 )) "$y"; sleep 0.3
        mouse_up; wait_for 0.6 "dragged"; cl_read
        [[ "$C_LINE" == "$B0" ]] && pass "a drag on the SOUND row moves nothing (read-only)" || fail "SOUND row drag moved the clip: [$C_LINE] (was [$B0])"
    fi

    # -- hidden: muted --
    click 7 "$(cl_row_y 1)"; wait_for 0.6 "the eye"; cl_read
    read -r _ _ XQ_HEARD XQ_MS <<< "$(cu_xsq)"
    [[ "$XQ_HEARD" == 0 && -z "$XQ_MS" ]] && pass "the clip layer hidden: its SOUND row is muted, no marks" || fail "hidden: [$(cu_xsq)]"
    screenshot "clip-cues-ui-muted"
fi
cl_done
info "=== Clip layers: sounds in the panel and the X-sheet: done ==="
