#!/bin/bash
# =============================================================================
# clip-lanes.sh — QA test: keyframe lanes on a clip layer (TOOLS/CLIP, phase 3
# L3-L5, PLANS/KEYFRAME-LANES.md).
#
#   - the LANE row's value box on frame 2 (IN) = 0 and on frame 6 = 8: two X
#     keys (auto-key), the clip moves 2 px a frame (CLIPX x 6 8 10 12)
#   - the KEYS row's ease chip on frame 2: EASE IN (frame 4 at x + 2); Ctrl+Z
#   - DEL on frame 6: one key left; Ctrl+Z: two again
#   - LANE > (Y), MOD chip: a sine (amount 2, period 12); the MOD row's AMOUNT
#     box = 3
#   - Ctrl+S + reload: the same lanes (drCl v3) and pixels
#   - Clear All Lanes: none; Ctrl+Z: back
#
# Dump: CLIP / CLIPX (clip-lib.sh), CLIPL slot lane n f:v:e ..., CLIPLM slot
# lane kind shape amount period phase seed, CLIPLV slot lane v1..v6, ANIMPLN
# (the lane rows: tops, chips, the picked lane).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: keyframe lanes ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
ln_read() {
    cl_read
    read -r _ LN_Y10 LN_Y11 LN_Y12 LN_LX0 LN_LW0 LN_LX1 LN_LW1 LN_KX0 LN_KW0 LN_KX1 LN_KW1 LN_KX2 LN_KW2 LN_MX LN_MW LN_PICK _ <<< "$(cl_line ANIMPLN)"
}
ln_keys() { grep "^CLIPL $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }    # n f:v:e ...
ln_vals() { grep "^CLIPLV $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
ln_mod() { grep "^CLIPLM $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
ln_xs() { # the clip's x in frames 2..5 (CLIPX f:x:...)
    local e o=""
    for e in $C_PIX; do case "${e%%:*}" in 2|3|4|5) o+=" $(cut -d: -f2 <<< "$e")" ;; esac; done
    echo "${o# }"
}
ln_tap() { # Y X W - a chip of the lane rows (native) -> a click
    cl_hclick "$(( P_X + ($2 + $3 / 2) * P_SC / 100 ))" "$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))"; ln_read
}
ln_box() { # Y SLOT TEXT - type into a number box of the lane rows
    local x=$(( P_X + (${!2} + PM_VW / 2) * P_SC / 100 )) y=$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))
    cl_hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $3"; ln_read
}
ln_s() { echo "X [$(ln_keys 1)] vals [$(ln_vals 1)] Y [$(ln_keys 2)] mod [$(ln_mod 2)] pick ${LN_PICK:-?} xs [$(ln_xs)]; $(cl_s)"; }

cl_setup
if (( CL_OK )); then
    ln_read
    [[ -n "$LN_Y10" && "$LN_PICK" == 1 ]] && pass "the lane rows are up, lane X picked" || fail "no lane rows: $(cl_line ANIMPLN)"

    # -- two X keys by typing the value (auto-key) --
    cl_strip 2; ln_box "$LN_Y10" PM_S3 0
    cl_key KP_9; ln_box "$LN_Y10" PM_S3 8
    [[ "$(ln_keys 1)" == "2 0:0:0 4:8:0" && "$(ln_vals 1)" == "0 0 2 4 6 8" ]] && pass "auto-key: X 0 on IN, 8 four frames later (2 px a frame)" || fail "keys: $(ln_s)"
    [[ "$(ln_xs)" == "6 8 10 12" ]] && pass "the clip's pixels move: x 6 8 10 12 in frames 2-5" || fail "pixels: $(ln_s) | $C_PIX"
    screenshot "clip-lanes-x"

    # -- ease --
    cl_key KP_1; cl_key KP_5; ln_tap "$LN_Y11" "$LN_KX2" "$LN_KW2"
    V=($(ln_vals 1))
    [[ "$(ln_keys 1)" == "2 0:0:1 4:8:0" && "${V[3]}" == 2 && "${V[5]}" == 8 ]] && pass "the ease chip: EASE IN (frame 4 at 2, frame 6 at 8)" || fail "ease: $(ln_s)"
    cl_key ctrl+z; ln_read
    [[ "$(ln_keys 1)" == "2 0:0:0 4:8:0" ]] && pass "Ctrl+Z: linear again" || fail "undo ease: $(ln_s)"

    # -- DEL --
    cl_key KP_9; ln_tap "$LN_Y11" "$LN_KX1" "$LN_KW1"
    [[ "$(ln_keys 1)" == "1 0:0:0" && "$(ln_xs)" == "6 6 6 6" ]] && pass "DEL on frame 6: one key, the clip stays put" || fail "del: $(ln_s)"
    cl_key ctrl+z; ln_read
    [[ "$(ln_keys 1)" == "2 0:0:0 4:8:0" && "$(ln_xs)" == "6 8 10 12" ]] && pass "Ctrl+Z: both keys back" || fail "undo del: $(ln_s)"

    # -- a modulator on Y --
    ln_tap "$LN_Y10" "$LN_LX1" "$LN_LW1"
    [[ "$LN_PICK" == 2 ]] && pass "LANE >: Y" || fail "lane >: pick $LN_PICK"
    ln_tap "$LN_Y12" "$LN_MX" "$LN_MW"
    [[ "$(ln_mod 2)" == "1 0 2 12 0 1" && "$(ln_vals 2)" == "-1 0 1 2 2 2" ]] && pass "MOD: a sine on Y (2 px, 12 frames)" || fail "mod: $(ln_s)"
    ln_box "$LN_Y12" PM_S1 3
    [[ "$(ln_mod 2)" == "1 0 3 12 0 1" ]] && pass "the MOD row's AMOUNT box: 3" || fail "amount: $(ln_s)"
    screenshot "clip-lanes-panel"

    # -- save, reload --
    SAVED="$(ln_keys 1)|$(ln_keys 2)|$(ln_mod 2)|$C_PIX"
    wake_draw
    key ctrl+s; wait_for 2.0 "saved"
    draw_quit; draw_settle
    draw_launch 15; wait_for 1.5 "Reloaded"
    assert_no_crash
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "the clip layer"
    ln_read
    [[ "$(ln_keys 1)|$(ln_keys 2)|$(ln_mod 2)|$C_PIX" == "$SAVED" ]] && pass "Ctrl+S + reload: the same lanes and pixels" || fail "reload: [$(ln_keys 1)|$(ln_keys 2)|$(ln_mod 2)|$C_PIX] saved [$SAVED]"

    # -- clear all --
    cl_cmd "clip layer: clear all lanes"; ln_read
    [[ -z "$(ln_keys 1)$(ln_keys 2)" && "$(ln_xs)" == "6 6 6 6" ]] && pass "Clear All Lanes: no lanes, the clip stays put" || fail "clear all: $(ln_s)"
    cl_key ctrl+z; ln_read
    [[ "$(ln_keys 1)" == "2 0:0:0 4:8:0" && -n "$(ln_mod 2)" ]] && pass "Ctrl+Z: the lanes are back" || fail "undo clear all: $(ln_s)"
fi
cl_done
info "=== Clip layers: keyframe lanes: done ==="
