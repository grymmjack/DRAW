#!/bin/bash
# =============================================================================
# clip-lanes-xsheet.sh — QA test: a keyed clip's LANES row on the X-sheet
# (TOOLS/ANIM-XS + TOOLS/CLIP, phase 3 L7).
#
#   - X keys on frames 2 and 6: a LANES row with a diamond on each, filled
#     (the picked lane, X); LANE > (Y): outlined
#   - drag frame 6's diamond to frame 4: the key moves (X 0 -> 8 over two
#     frames), the current frame is 4; one Ctrl+Z puts it back
#   - Clear All Lanes: the LANES row goes
#   - Ctrl+Z (the keys and the row back), then Bake Clip to Pixels with the
#     X-sheet showing: DRAW lives on (the dump read CLIP_INST(0) from the stale
#     LANES row - ERR 9 every frame, aborted after 21: the farm sample build,
#     2026-11-12); no clip, no LANES row
#
# Dump: CLIP / CLIPL (clip-lib.sh), ANIMXSF f x w ... (frame spans), ANIMXSK
# slot y f:mark ... (the LANES row; mark 2 = the picked lane has a key there).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Clip layers: the X-sheet LANES row ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
ln_read() {
    cl_read
    read -r _ LN_Y10 LN_Y11 LN_Y12 LN_LX0 LN_LW0 LN_LX1 LN_LW1 LN_KX0 LN_KW0 LN_KX1 LN_KW1 LN_KX2 LN_KW2 LN_MX LN_MW LN_PICK _ <<< "$(cl_line ANIMPLN)"
    read -r _ XK_SLOT XK_Y XK_MARKS <<< "$(cl_line ANIMXSK)"
    XF=($(cl_line ANIMXSF))
}
ln_keys() { grep "^CLIPL $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
ln_tap() { cl_hclick "$(( P_X + ($2 + $3 / 2) * P_SC / 100 ))" "$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))"; ln_read; }
ln_box() { # Y SLOT TEXT
    local x=$(( P_X + (${!2} + PM_VW / 2) * P_SC / 100 )) y=$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))
    cl_hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $3"; ln_read
}
xk_fmid() { # FRAME -> the middle x of its span
    local i
    for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do
        [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }
    done
    echo 0
}
xk_drag() { # FROM_FRAME TO_FRAME - along the LANES row
    local y=$(( XK_Y + 8 )) a b
    a=$(xk_fmid "$1"); b=$(xk_fmid "$2")
    mouse_down "$a" "$y"; hover $(( (a + b) / 2 )) "$y"; sleep 0.2; hover "$b" "$y"; sleep 0.4
    mouse_up; wait_for 0.6 "dragged"; ln_read
}
xk_s() { echo "LANES row [${XK_SLOT:-} ${XK_Y:-} ${XK_MARKS:-}] X [$(ln_keys 1)] pick ${LN_PICK:-?}; $(cl_s)"; }

cl_setup
if (( CL_OK )); then
    ln_read
    ln_box "$LN_Y10" PM_S3 0
    cl_key KP_9; ln_box "$LN_Y10" PM_S3 8
    cl_key KP_8; ln_read
    [[ -n "$XK_SLOT" && "$XK_MARKS" == "2:2 6:2" ]] && pass "the X-sheet's LANES row: diamonds on frames 2 and 6, filled (lane X)" || fail "LANES row: $(xk_s) | $(cl_line ANIMXS)"
    screenshot "clip-lanes-xsheet"
    ln_tap "$LN_Y10" "$LN_LX1" "$LN_LW1"
    [[ "$LN_PICK" == 2 && "$XK_MARKS" == "2:1 6:1" ]] && pass "LANE > (Y): the diamonds outlined (no Y keys)" || fail "lane Y marks: $(xk_s)"
    ln_tap "$LN_Y10" "$LN_LX0" "$LN_LW0"

    # -- drag a key in time --
    xk_drag 6 4
    [[ "$(ln_keys 1)" == "2 0:0:0 2:8:0" && "$XK_MARKS" == "2:2 4:2" && "$A_CUR" == 4 ]] && pass "drag frame 6's diamond to frame 4: the key moves there, frame 4 current" || fail "key drag: $(xk_s)"
    cl_key ctrl+z; ln_read
    [[ "$(ln_keys 1)" == "2 0:0:0 4:8:0" && "$XK_MARKS" == "2:2 6:2" ]] && pass "one Ctrl+Z: the key back on frame 6" || fail "undo key drag: $(xk_s)"

    # -- no keys, no row --
    cl_cmd "clip layer: clear all lanes"; ln_read
    [[ -z "$XK_SLOT" ]] && pass "Clear All Lanes: the LANES row goes" || fail "row after clear: $(xk_s)"

    # -- bake a keyed clip with the X-sheet up --
    cl_key ctrl+z; ln_read
    [[ -n "$XK_SLOT" && "$(ln_keys 1)" == "2 0:0:0 4:8:0" ]] && pass "Ctrl+Z: the keys and the LANES row back" || fail "undo clear: $(xk_s)"
    cl_cmd "clip layer: bake clip to pixels"; wait_for 2.5 "baked, a few frames"; ln_read
    assert_no_crash
    [[ -z "$C_SLOT" && -z "$XK_SLOT" ]] && pass "Bake Clip to Pixels: no clip, no LANES row, DRAW still here" || fail "after bake: $(xk_s)"
    cl_key ctrl+z; wait_for 1.0 "a few frames"; ln_read
    [[ -n "$C_SLOT" && -n "$XK_SLOT" ]] && pass "Ctrl+Z: the clip and its LANES row back" || fail "undo bake: $(xk_s)"
    assert_no_crash
fi
cl_done
info "=== Clip layers: the X-sheet LANES row: done ==="
