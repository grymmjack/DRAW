#!/bin/bash
# =============================================================================
# clip-lanes-canvas.sh — QA test: the Move tool on a clip with X / Y keys keys
# the current frame (TOOLS/CLIP CLIP_move_by, phase 3 L6).
#
#   - X keys 0 (frame 2 = IN) and 8 (frame 6): 2 px a frame
#   - frame 4, V + drag 2 right 2 down: an X key 6 and a Y key 2 at frame 4
#     (from IN: 2); the clip's own X / Y stay 6, 6; one Ctrl+Z undoes both
#   - Right (the Move tool's nudge) on frame 4: the X key there 5; Ctrl+Z
#   - Clear All Lanes, then a drag: the whole clip moves as before (X / Y 8 8)
#
# Dump: CLIP / CLIPX (clip-lib.sh), CLIPL / CLIPLV, ANIMPLN.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: Move keys X / Y ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
ln_read() {
    cl_read
    read -r _ LN_Y10 LN_Y11 LN_Y12 LN_LX0 LN_LW0 LN_LX1 LN_LW1 LN_KX0 LN_KW0 LN_KX1 LN_KW1 LN_KX2 LN_KW2 LN_MX LN_MW LN_PICK _ <<< "$(cl_line ANIMPLN)"
}
ln_keys() { grep "^CLIPL $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
ln_vals() { grep "^CLIPLV $C_SLOT $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
ln_box() { # Y SLOT TEXT
    local x=$(( P_X + (${!2} + PM_VW / 2) * P_SC / 100 )) y=$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))
    cl_hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $3"; ln_read
}
ln_frame4() { cl_key KP_1; cl_key KP_5; cl_key KP_5; cl_key KP_5; ln_read; }
ln_drag() { # FROM-X FROM-Y TO-X TO-Y (cell pixels, frame view)
    mouse_down "$(cl_px "$1")" "$(cl_py "$2")"; hover "$(cl_px $(( ($1 + $3) / 2 )))" "$(cl_py $(( ($2 + $4) / 2 )))"; sleep 0.2
    hover "$(cl_px "$3")" "$(cl_py "$4")"; sleep 0.3
    mouse_up; wait_for 0.8 "moved"; ln_read
}
ln_s() { echo "X [$(ln_keys 1)] Y [$(ln_keys 2)] vals X [$(ln_vals 1)] Y [$(ln_vals 2)] at ${C_PX:-?},${C_PY:-?}; $(cl_s)"; }

cl_setup
if (( CL_OK )); then
    ln_read
    ln_box "$LN_Y10" PM_S3 0
    cl_key KP_9; ln_box "$LN_Y10" PM_S3 8
    [[ "$(ln_keys 1)" == "2 0:0:0 4:8:0" ]] && pass "X keys 0 and 8 (frames 2 and 6)" || fail "setup keys: $(ln_s)"

    # -- drag on frame 4 --
    ln_frame4
    [[ "$A_CUR" == 4 ]] || fail "not on frame 4: $(ln_s)"
    cl_key v
    ln_drag 11 7 13 9
    [[ "$(ln_keys 1)" == "3 0:0:0 2:6:0 4:8:0" && "$(ln_keys 2)" == "1 2:2:0" && "$C_PX $C_PY" == "6 6" ]] \
        && pass "V + drag on frame 4: X key 6 and Y key 2 there, the clip's X / Y unchanged" || fail "drag: $(ln_s)"
    [[ "$(ln_vals 1)" == "0 0 3 6 7 8" ]] && pass "X runs 0 3 6 7 8 through the new key" || fail "X values: $(ln_s)"
    screenshot "clip-lanes-canvas"
    cl_key ctrl+z; ln_read
    [[ "$(ln_keys 1)" == "2 0:0:0 4:8:0" && -z "$(ln_keys 2)" ]] && pass "one Ctrl+Z: both keys gone" || fail "undo drag: $(ln_s)"

    # -- nudge --
    cl_key Right; ln_read
    [[ "$(ln_keys 1)" == "3 0:0:0 2:5:0 4:8:0" && "$C_PX" == 6 ]] && pass "Right on frame 4: an X key 5 there" || fail "nudge: $(ln_s)"
    cl_key ctrl+z; ln_read
    [[ "$(ln_keys 1)" == "2 0:0:0 4:8:0" ]] && pass "Ctrl+Z: the nudge key gone" || fail "undo nudge: $(ln_s)"

    # -- no X / Y keys: the old whole-clip move --
    cl_cmd "clip layer: clear all lanes"; ln_read
    cl_key v
    ln_drag 7 7 9 9
    [[ -z "$(ln_keys 1)$(ln_keys 2)" && "$C_PX $C_PY" == "8 8" ]] && pass "no X / Y keys: the drag moves the whole clip (8, 8)" || fail "plain move: $(ln_s)"
    cl_expect ".12341" 8 8 0 "the whole clip's pixels moved in every frame"
fi
cl_done
info "=== Clip layers: Move keys X / Y: done ==="
