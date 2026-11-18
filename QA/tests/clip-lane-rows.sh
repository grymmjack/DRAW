#!/bin/bash
# =============================================================================
# clip-lane-rows.sh — QA test: a clip layer's lane rows on the X-sheet
# (branch xsheet-holds-lanes, TOOLS/ANIM-XLANE).
#
#   - X keys on frames 2 and 6: closed, the LANES summary row; the arrow
#     before the layer's name opens a row per lane in use (X) and + LANE
#   - drag a key up: its value rises; along the row: its frame moves; one
#     Ctrl+Z each
#   - right-click a key: Ease In-Out; double-click between keys: a key at
#     the curve's value there
#   - + LANE > ROTATE: a ROTATE row; its menu > Remove Lane: gone
#   - the arrow again: closed, the LANES summary row back
#
# Dump: ANIMXSLO slot open arrowX y; ANIMXSLN slot lane y lo hi mod
# rel:value:ease ...; ANIMXSLA slot y; ANIMXLM menu (x y w, value y ...);
# ANIMXSK (the LANES summary row), ANIMXSF f x w ..., ANIMXS (layH).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Clip layers: the X-sheet lane rows ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
ln_read() {
    cl_read
    read -r _ LN_Y10 LN_Y11 LN_Y12 LN_LX0 LN_LW0 LN_LX1 LN_LW1 LN_KX0 LN_KW0 LN_KX1 LN_KW1 LN_KX2 LN_KW2 LN_MX LN_MW LN_PICK _ <<< "$(cl_line ANIMPLN)"
}
ln_box() { # Y SLOT TEXT
    local x=$(( P_X + (${!2} + PM_VW / 2) * P_SC / 100 )) y=$(( P_Y + ($1 + L_RH / 2) * P_SC / 100 ))
    cl_hclick "$x" "$y"; wait_for 0.8 "input box"
    type_text "$3"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "typed $3"; ln_read
}
xl_read() {
    ln_read
    read -r _ XO_SLOT XO_OPEN XO_X XO_Y _ <<< "$(cl_line ANIMXSLO)"
    read -r _ XK_SLOT _ <<< "$(cl_line ANIMXSK)"
    read -r _ XA_SLOT XA_Y _ <<< "$(cl_line ANIMXSLA)"
    XF=($(cl_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(cl_line ANIMXS)"
    XM=($(cl_line ANIMXLM))
}
xl_lane() { grep -m1 "^ANIMXSLN [0-9]* $1 " "$CL_DUMPF" 2>/dev/null; }      # LANE -> its line
xl_keys() { xl_lane "$1" | cut -d' ' -f8-; }                                 # rel:value:ease ...
xl_y() { xl_lane "$1" | cut -d' ' -f4; }                                     # its row's y
xl_fmid() { local i; for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }; done; echo 0; }
xl_item() { local i; for (( i = 4; i + 1 < ${#XM[@]}; i += 2 )); do [[ "${XM[$i]}" == "$1" ]] && { echo "${XM[$((i + 1))]}"; return; }; done; echo ""; }
xl_pick() { # VALUE - click that item of the open lane menu
    local iy; iy=$(xl_item "$1")
    [[ -z "$iy" ]] && { echo "no item $1 in [${XM[*]}]" >&2; return 1; }
    cl_hclick $(( XM[1] + XM[3] / 2 )) $(( iy + 4 )); xl_read
}
xl_s() { echo "open ${XO_OPEN:-?} summary '${XK_SLOT:-}' add '${XA_SLOT:-}' X [$(xl_keys 1)] ROTATE [$(xl_keys 5)]"; }

cl_setup
if (( CL_OK )); then
    ln_read
    ln_box "$LN_Y10" PM_S3 0
    cl_key KP_9; ln_box "$LN_Y10" PM_S3 8
    cl_key KP_8; xl_read
    [[ "$XO_OPEN" == 0 && -n "$XK_SLOT" && -z "$XA_SLOT" ]] && pass "closed: the LANES summary row, no lane rows" || fail "closed: $(xl_s) | $(cl_line ANIMXSLO)"

    # -- open --
    cl_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); xl_read
    [[ "$XO_OPEN" == -1 && -z "$XK_SLOT" && -n "$XA_SLOT" && "$(xl_keys 1)" == "0:0:0 4:8:0" ]] \
        && pass "the arrow opens the lanes: an X row (keys 0:0, 4:8) and + LANE, no summary row" || fail "open: $(xl_s)"
    screenshot "clip-lane-rows-open"

    # -- drag frame 6's key up: its value rises --
    LY=$(xl_y 1); X6=$(xl_fmid 6); YM=$(( LY + XLH / 2 ))
    mouse_down "$X6" "$YM"; hover "$X6" $(( YM - 3 )); sleep 0.15; hover "$X6" $(( YM - 6 )); sleep 0.3
    mouse_up; wait_for 0.6 "dragged"; xl_read
    K2=$(xl_keys 1 | cut -d' ' -f2)
    [[ "${K2%%:*}" == 4 && "$(echo "$K2" | cut -d: -f2)" -gt 8 ]] && pass "drag frame 6's key up: X there rises ($K2)" || fail "value drag: $(xl_s)"
    cl_key ctrl+z; xl_read
    [[ "$(xl_keys 1)" == "0:0:0 4:8:0" ]] && pass "one Ctrl+Z: X back to 8" || fail "undo value drag: $(xl_s)"

    # -- drag it along: its frame moves --
    X5=$(xl_fmid 5)
    mouse_down "$X6" "$YM"; hover $(( (X6 + X5) / 2 )) "$YM"; sleep 0.15; hover "$X5" "$YM"; sleep 0.3
    mouse_up; wait_for 0.6 "dragged"; xl_read
    [[ "$(xl_keys 1)" == "0:0:0 3:8:0" && "$A_CUR" == 5 ]] && pass "drag it along to frame 5: the key moves there, frame 5 current" || fail "time drag: $(xl_s) frame $A_CUR"
    cl_key ctrl+z; xl_read
    [[ "$(xl_keys 1)" == "0:0:0 4:8:0" ]] && pass "one Ctrl+Z: back on frame 6" || fail "undo time drag: $(xl_s)"

    # -- right-click frame 2's key: Ease In-Out --
    X2=$(xl_fmid 2)
    right_click "$X2" "$YM"; wait_for 0.6 "menu"; xl_read
    xl_pick 31004
    [[ "$(xl_keys 1)" == "0:0:3 4:8:0" ]] && pass "right-click frame 2's key > Ease In-Out" || fail "ease: $(xl_s) menu [${XM[*]}]"

    # -- double-click between the keys: a key at the curve there (in-out halfway: 4) --
    X4=$(xl_fmid 4)
    double_click "$X4" "$YM"; wait_for 0.6 "double-click"; xl_read
    [[ "$(xl_keys 1)" == "0:0:3 2:4:3 4:8:0" ]] && pass "double-click frame 4: a key at the curve's value (4), the ease kept" || fail "add key: $(xl_s)"

    # -- + LANE > ROTATE --
    cl_hclick "$X2" $(( XA_Y + XLH / 2 )); xl_read
    xl_pick 31105
    [[ -n "$(xl_lane 5)" && -n "$(xl_keys 5)" ]] && pass "+ LANE > ROTATE: a ROTATE row with a key" || fail "+ lane: $(xl_s)"
    cl_key ctrl+z; xl_read
    [[ -z "$(xl_lane 5)" ]] && pass "Ctrl+Z: the ROTATE row goes" || fail "undo + lane: $(xl_s)"
    cl_key ctrl+y; xl_read

    # -- its menu > Remove Lane --
    RY=$(xl_y 5)
    if [[ -n "$RY" ]]; then
        right_click "$X4" $(( RY + XLH / 2 )); wait_for 0.6 "menu"; xl_read
        xl_pick 31030
        [[ -z "$(xl_lane 5)" && -n "$(xl_lane 1)" ]] && pass "ROTATE's menu > Remove Lane: its row goes, X stays" || fail "remove lane: $(xl_s)"
    else
        fail "no ROTATE row after redo: $(xl_s)"
    fi

    # -- close --
    cl_hclick $(( XO_X + 4 )) $(( XO_Y + XLH / 2 )); xl_read
    [[ "$XO_OPEN" == 0 && -n "$XK_SLOT" && -z "$XA_SLOT" && -z "$(xl_lane 1)" ]] && pass "the arrow again: closed, the LANES summary row back" || fail "close: $(xl_s)"
    assert_no_crash
fi
cl_done
info "=== Clip layers: the X-sheet lane rows: done ==="
