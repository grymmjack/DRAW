#!/bin/bash
# =============================================================================
# clip-lanes-sound.sh — QA test: a clip's VOLUME / PAN lanes on its sounds
# (TOOLS/CLIP CLIP_cues_gen + ANIM_SND_mix, phase 3 L8).
#
# step.wav (440 Hz, peak 24 %) on cel 1: it sounds on frames 2 and 6.
#   - no lanes: both at volume 100, pan 0; the mix peaks at 24 % each side
#   - VOLUME 50 on frame 2: both at 50 (one key holds), the mix at 12 %
#   - VOLUME 100 on frame 6: that one at 100 (the volume where it starts)
#   - Ctrl+Z: both 50 again
#   - PAN -100 on frame 2: both hard left - the right side silent
#   - Ctrl+S + reload: the same volumes, pans and mix
#
# Dump: ANIMSCG n (the generated clips), ANIMSCGV peakL peakR then per
# generated clip volume% pan%, CLIPL (the lanes), ANIMPLN.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: volume / pan lanes ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
mkdir -p "$CL_DIR/snd"
python3 - "$CL_DIR/snd" <<'PY'
import sys, wave, struct, math
w = wave.open(f"{sys.argv[1]}/step.wav", "wb"); w.setnchannels(1); w.setsampwidth(2); w.setframerate(22050)
n = 22050 * 200 // 1000
w.writeframes(b"".join(struct.pack("<h", int(8000 * math.sin(2 * math.pi * 440 * i / 22050))) for i in range(n))); w.close()
PY
ln_read() {
    cl_read
    read -r _ LN_Y10 LN_Y11 LN_Y12 LN_LX0 LN_LW0 LN_LX1 LN_LW1 LN_KX0 LN_KW0 LN_KX1 LN_KW1 LN_KX2 LN_KW2 LN_MX LN_MW LN_PICK _ <<< "$(cl_line ANIMPLN)"
    SV=$(cl_line ANIMSCGV | cut -d' ' -f2-)
    SG=$(cl_line ANIMSCG | cut -d' ' -f2)
}
ln_keys() { grep "^CLIPL $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
ln_tap() { cl_hclick "$(( P_X + ($2 + $3 / 2) * P_SC / 100 ))" "$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))"; ln_read; }
ln_box() { # Y SLOT TEXT
    local x=$(( P_X + (${!2} + PM_VW / 2) * P_SC / 100 )) y=$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))
    cl_hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 1.2 "typed $3 (the mix)"; ln_read
}
ln_pick() { # LANE - press > until it is picked
    local n
    for (( n = 0; n < 12 && LN_PICK != $1; n++ )); do ln_tap "$LN_Y10" "$LN_LX1" "$LN_LW1"; done
}
ln_s() { echo "generated ${SG:-?} [peakL peakR vol pan ...: ${SV:-}] VOL [$(ln_keys 10)] PAN [$(ln_keys 11)] pick ${LN_PICK:-?}; $(cl_s)"; }

CL_EXTRA="--option LAST_DIR_OPEN=$CL_DIR/snd"
cl_setup
if (( CL_OK )); then
    cl_cmd "clip layer: sound on this cel"; wait_for 0.8 "the file dialog"
    type_text step.wav; wait_for 0.4 "typed"; key Return; wait_for 1.5 "picked (the mix)"
    ln_read
    [[ "$SG" == 2 && "$SV" == "24 24 100 0 100 0" ]] && pass "cel 1's sound on frames 2 and 6: volume 100, pan 0, the mix at 24 %" || fail "start: $(ln_s)"

    ln_pick 10
    ln_box "$LN_Y10" PM_S3 50
    [[ "$(ln_keys 10)" == "1 0:50:0" && "$SV" == "12 12 50 0 50 0" ]] && pass "VOLUME 50 on frame 2: both sounds at 50, the mix at 12 %" || fail "volume 50: $(ln_s)"
    cl_key KP_9; ln_box "$LN_Y10" PM_S3 100
    [[ "$(ln_keys 10)" == "2 0:50:0 4:100:0" && "$SV" == "24 24 50 0 100 0" ]] && pass "VOLUME 100 on frame 6: that sound at 100" || fail "volume 100: $(ln_s)"
    cl_key ctrl+z; ln_read
    [[ "$SV" == "12 12 50 0 50 0" ]] && pass "Ctrl+Z: both at 50 again" || fail "undo volume: $(ln_s)"

    cl_key KP_1; cl_key KP_5; ln_read
    ln_pick 11
    ln_box "$LN_Y10" PM_S3 -100
    [[ "$(ln_keys 11)" == "1 0:-100:0" && "$SV" == "12 0 50 -100 50 -100" ]] && pass "PAN -100: both hard left, the right side silent" || fail "pan: $(ln_s)"
    screenshot "clip-lanes-sound"

    SAVED="$SV|$(ln_keys 10)|$(ln_keys 11)"
    wake_draw
    key ctrl+s; wait_for 2.0 "saved"
    draw_quit; draw_settle
    draw_launch 15; wait_for 2.0 "Reloaded (the mix)"
    assert_no_crash
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "the clip layer"
    ln_read
    [[ "$SV|$(ln_keys 10)|$(ln_keys 11)" == "$SAVED" ]] && pass "Ctrl+S + reload: the same volumes, pans and mix" || fail "reload: [$SV|$(ln_keys 10)|$(ln_keys 11)] saved [$SAVED]"
fi
cl_done
info "=== Clip layers: volume / pan lanes: done ==="
