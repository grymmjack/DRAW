#!/bin/bash
# =============================================================================
# clip-xsheet.sh — QA test: a clip layer's row on the X-sheet (TOOLS/ANIM-XS +
# TOOLS/CLIP, phase 2 K5).
#
#   - the clip's row is a bar from In to its last frame (ANIMXSCL)
#   - drag the In end to frame 3: In 3 (its cels move with it); Ctrl+Z: In 2
#   - drag the Out end to frame 4: Out 4
#   - drag the middle one frame right: In 3, Out 5 - one Ctrl+Z puts both back
#
# Dump: CLIP / CLIPC (clip-lib.sh), ANIMXSF f x w ... (frame spans),
# ANIMXSCL slot y xa xb in out (each clip bar in view).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW XSHEET_NAME_WIDTH=0 XSHEET_SIZE=0
# =============================================================================
info "=== Clip layers: the X-sheet clip row ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
cx_read() { cl_read; read -r _ XC_SLOT XC_Y XC_XA XC_XB XC_IN XC_OUT _ <<< "$(cl_line ANIMXSCL)"; XF=($(cl_line ANIMXSF)); }
cx_fmid() { # FRAME -> the middle x of its span
    local i
    for (( i = 1; i + 2 < ${#XF[@]}; i += 3 )); do
        [[ "${XF[$i]}" == "$1" ]] && { echo $(( XF[i + 1] + XF[i + 2] / 2 )); return; }
    done
    echo 0
}
cx_drag() { # FROM_X TO_X - along the clip's row
    local y=$(( XC_Y + 8 )) mid=$(( ($1 + $2) / 2 ))
    mouse_down "$1" "$y"; hover "$mid" "$y"; sleep 0.2; hover "$2" "$y"; sleep 0.4
    mouse_up; wait_for 0.6 "dragged"; cx_read
}
cx_s() { echo "bar [${XC_SLOT:-} ${XC_Y:-} ${XC_XA:-} ${XC_XB:-} ${XC_IN:-} ${XC_OUT:-}] $(cl_s)"; }

cl_setup
if (( CL_OK )); then
    cl_key KP_8; cx_read
    [[ -n "$XC_SLOT" && "$XC_IN $XC_OUT" == "2 6" ]] && pass "the X-sheet shows the clip as a bar from frame 2 to 6" || fail "no clip bar: $(cx_s) | $(cl_line ANIMXS)"
    screenshot "clip-xsheet-bar"

    # -- the In end --
    cx_drag $(( XC_XA + 1 )) "$(cx_fmid 3)"
    [[ "$C_IN $C_OUT" == "3 0" && "$C_CELS" == "..1234" ]] && pass "drag the In end to frame 3: In 3, the cels start there" || fail "In drag: $(cx_s)"
    cl_key ctrl+z; cx_read
    [[ "$C_IN" == 2 && "$C_CELS" == ".12341" ]] && pass "Ctrl+Z: In 2 again" || fail "undo In drag: $(cx_s)"

    # -- the Out end --
    cx_drag $(( XC_XB - 1 )) "$(cx_fmid 4)"
    [[ "$C_IN $C_OUT" == "2 4" && "$C_CELS" == ".123.." && "$XC_OUT" == 4 ]] && pass "drag the Out end to frame 4: Out 4, the bar ends there" || fail "Out drag: $(cx_s)"

    # -- the whole bar --
    cx_drag "$(cx_fmid 3)" "$(cx_fmid 4)"
    [[ "$C_IN $C_OUT" == "3 5" && "$C_CELS" == "..123." ]] && pass "drag the bar one frame right: In 3, Out 5" || fail "bar drag: $(cx_s)"
    screenshot "clip-xsheet-slid"
    cl_key ctrl+z; cx_read
    [[ "$C_IN $C_OUT" == "2 4" && "$C_CELS" == ".123.." ]] && pass "one Ctrl+Z: In 2, Out 4 again" || fail "undo bar drag: $(cx_s)"
    cl_key ctrl+z; cx_read
    [[ "$C_IN $C_OUT" == "2 0" ]] && pass "Ctrl+Z: Out to the end again" || fail "undo Out drag: $(cx_s)"
fi
cl_done
info "=== Clip layers: the X-sheet clip row: done ==="
