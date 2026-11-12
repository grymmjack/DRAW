#!/bin/bash
# =============================================================================
# clip-lanes-mod.sh — QA test: lane modulators and the transform lanes of a
# clip layer (TOOLS/CLIP + XF_draw, phase 3 L4-L5, PLANS/KEYFRAME-LANES.md).
#
#   - X: the MOD chip five times = NOISE; AMOUNT 5: seeded jitter (CLIPLV),
#     the same after Ctrl+S + reload; SEED 7 changes it, Ctrl+Z brings it back
#   - Copy Lanes, Clear All Lanes, Paste Lanes: the same lanes again
#   - SCALE X 200 (one key): the cel twice as wide about its centre
#   - ROTATE 90: the cel's white corner moves, the 4x4 stays in place
#   - OPACITY 50: about half alpha (CLIPXA)
#   - TINT 100 (toward the clip's tint colour, white by default): all white
#
# Dump: CLIP / CLIPX (clip-lib.sh), CLIPXA slot f:alpha, CLIPL / CLIPLM /
# CLIPLV (the lanes), ANIMPLN (the lane rows).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: lane modulators + transform lanes ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
ln_read() {
    cl_read
    read -r _ LN_Y10 LN_Y11 LN_Y12 LN_LX0 LN_LW0 LN_LX1 LN_LW1 LN_KX0 LN_KW0 LN_KX1 LN_KW1 LN_KX2 LN_KW2 LN_MX LN_MW LN_PICK _ <<< "$(cl_line ANIMPLN)"
}
ln_keys() { grep "^CLIPL $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
ln_vals() { grep "^CLIPLV $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
ln_mod() { grep "^CLIPLM $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
ln_all() { grep -E "^CLIPL[MV]? $C_SLOT " "$CL_DUMPF" | cut -d' ' -f3- | tr '\n' '|'; }
ln_f() { # FRAME -> that frame's CLIPX entry
    local e
    for e in $C_PIX; do [[ "${e%%:*}" == "$1" ]] && { echo "$e"; return; }; done
}
ln_alpha() { cl_line CLIPXA | tr ' ' '\n' | grep "^$1:" | cut -d: -f2; }
ln_tap() { cl_hclick "$(( P_X + ($2 + $3 / 2) * P_SC / 100 ))" "$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))"; ln_read; }
ln_box() { # Y SLOT TEXT
    local x=$(( P_X + (${!2} + PM_VW / 2) * P_SC / 100 )) y=$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))
    cl_hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $3"; ln_read
}
ln_pick() { # LANE - press > until it is picked
    local n
    for (( n = 0; n < 12 && LN_PICK != $1; n++ )); do ln_tap "$LN_Y10" "$LN_LX1" "$LN_LW1"; done
}
ln_s() { echo "lanes [$(ln_all)] pick ${LN_PICK:-?} f2 [$(ln_f 2)] a2 [$(ln_alpha 2)]; $(cl_s)"; }

cl_setup
if (( CL_OK )); then
    ln_read
    P0="$C_PIX"; F2=$(ln_f 2) # cel 1 at (6, 6): 4x4, white top left

    # -- noise on X --
    for n in 1 2 3 4 5; do ln_tap "$LN_Y12" "$LN_MX" "$LN_MW"; done
    ln_box "$LN_Y12" PM_S1 5
    read -r MK _ MA MP _ MS _ <<< "$(ln_mod 1)"
    N1="$(ln_vals 1)"
    [[ "$MK" == 2 && "$MA" == 5 && "$MS" == 1 && "$N1" =~ ^(-?[0-5]\ ){5}-?[0-5]$ && "$N1" != "0 0 0 0 0 0" ]] && pass "MOD x5 = NOISE, AMOUNT 5: X jitters within 5 px ($N1)" || fail "noise: $(ln_s)"
    [[ "$C_PIX" != "$P0" ]] && pass "the jitter moves the pixels" || fail "noise pixels: [$C_PIX]"
    ln_box "$LN_Y12" PM_S3 7
    [[ "$(ln_mod 1)" == "2 "*" 7" && "$(ln_vals 1)" != "$N1" ]] && pass "SEED 7: other values ($(ln_vals 1))" || fail "seed: $(ln_s) (seed 1 gave [$N1])"
    cl_key ctrl+z; ln_read
    [[ "$(ln_vals 1)" == "$N1" ]] && pass "Ctrl+Z: seed 1, the same values" || fail "undo seed: $(ln_s) want [$N1]"

    SAVED="$(ln_all)|$C_PIX"
    wake_draw
    key ctrl+s; wait_for 2.0 "saved"
    draw_quit; draw_settle
    draw_launch 15; wait_for 1.5 "Reloaded"
    assert_no_crash
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "the clip layer"
    ln_read
    [[ "$(ln_all)|$C_PIX" == "$SAVED" ]] && pass "Ctrl+S + reload: the same noise, the same pixels" || fail "reload: [$(ln_all)|$C_PIX] saved [$SAVED]"

    # -- copy / clear / paste --
    L0="$(ln_all)"
    cl_cmd "clip layer: copy lanes"; cl_cmd "clip layer: clear all lanes"; ln_read
    [[ -z "$(ln_all)" && "$C_PIX" == "$P0" ]] && pass "Clear All Lanes: none, the clip back in place" || fail "clear: $(ln_s)"
    cl_cmd "clip layer: paste lanes"; ln_read
    [[ "$(ln_all)" == "$L0" ]] && pass "Paste Lanes: the copied lanes" || fail "paste: [$(ln_all)] want [$L0]"
    cl_cmd "clip layer: clear all lanes"; ln_read

    # -- SCALE X 200 --
    ln_pick 3
    ln_box "$LN_Y10" PM_S3 200
    S2=$(ln_f 2)
    [[ "$(ln_keys 3)" == "1 0:200:0" && "$S2" == 2:4:6:8:4:ffffff:* ]] && pass "SCALE X 200: the cel 8 wide about its centre ($S2)" || fail "scale: $(ln_s)"
    screenshot "clip-lanes-scale"
    cl_key ctrl+z; ln_read
    [[ "$(ln_f 2)" == "$F2" ]] && pass "Ctrl+Z: 4 wide again" || fail "undo scale: $(ln_s)"

    # -- ROTATE 90 --
    ln_pick 5
    ln_box "$LN_Y10" PM_S3 90
    R2=$(ln_f 2)
    [[ "$(ln_keys 5)" == "1 0:90:0" && "$R2" == 2:6:6:4:4:* && "$R2" != "$F2" ]] && pass "ROTATE 90: the white corner moves, the 4x4 stays put ($R2, was $F2)" || fail "rotate: $(ln_s) (was $F2)"
    cl_key ctrl+z; ln_read

    # -- OPACITY 50 --
    ln_pick 6
    ln_box "$LN_Y10" PM_S3 50
    A2=$(ln_alpha 2)
    [[ "$(ln_keys 6)" == "1 0:50:0" && "$A2" =~ ^[0-9]+$ ]] && (( A2 >= 120 && A2 <= 135 )) && pass "OPACITY 50: alpha $A2" || fail "opacity: alpha [$A2] $(ln_s)"
    cl_key ctrl+z; ln_read
    [[ "$(ln_alpha 2)" == 255 ]] && pass "Ctrl+Z: opaque again" || fail "undo opacity: alpha [$(ln_alpha 2)]"

    # -- TINT 100 --
    ln_pick 7
    ln_box "$LN_Y10" PM_S3 100
    T2=$(ln_f 2)
    [[ "$(ln_keys 7)" == "1 0:100:0" && "$T2" == 2:6:6:4:4:ffffff:ffffff ]] && pass "TINT 100: the cel all white (the default tint colour)" || fail "tint: $(ln_s)"
    screenshot "clip-lanes-tint"
fi
cl_done
info "=== Clip layers: lane modulators + transform lanes: done ==="
