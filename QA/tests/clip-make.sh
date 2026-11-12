#!/bin/bash
# =============================================================================
# clip-make.sh — QA test: Make Clip from Selected Frames (TOOLS/CLIP, phase 2 K3).
#
#   - frames 3-5 selected, a marquee round the square: Make Clip makes a clip
#     layer (In 3, Out 5, Loop, at the marquee's top left) whose cels are those frames' squares;
#     Layer 1's frames 3-5 are empty now and the frames look the same
#   - one Ctrl+Z: no clip, Layer 1 back; Ctrl+Y: both again
#   - Make Clip with the clip layer current: refused
#   - no frames selected: every frame becomes the clip (In 1, Out to the end)
#
# Dump: CLIP / CLIPC / CLIPX (clip-lib.sh), ANIMC (Layer 1's cells: 0 = empty).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: Make Clip from Selected Frames ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
cm_animc() { cl_line ANIMC | cut -d' ' -f2-; }
cm_nclips() { grep -c '^CLIP ' "$CL_DUMPF"; }
cm_marquee() { # the square in the current frame's pane
    cl_key m
    mouse_down "$(cl_px 5)" "$(cl_py 5)"; hover "$(cl_px 8)" "$(cl_py 8)"; sleep 0.2; hover "$(cl_px 10)" "$(cl_py 10)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"; cl_read
}

if [[ -s "$CL_DIR/clip.draw" ]]; then
    draw_quit; draw_settle
    DRAW_EXTRA_ARGS="$CL_DIR/clip.draw"
    draw_launch 15
    wait_for 1.5 "Sheet loaded"
    assert_no_crash
    park_mouse
    cl_key KP_0; cl_read
    B0=$(cm_animc)
    read -r -a B0A <<< "$B0"

    # -- frames 3-5 --
    cl_strip 5; cl_strip 3 shift; cl_read
    cm_marquee
    cl_cmd "clip layer: make clip"; cl_read
    [[ "$C_LINE" == "1 3 5 1 1 LOOP 0 0 5 5" ]] && pass "Make Clip: a clip from frame 3 to 5 at the marquee (5, 5)" || fail "make clip: $(cl_s)"
    cl_expect "..123." 6 6 0 "the clip shows each frame's own square"
    read -r -a B1A <<< "$(cm_animc)"
    [[ "${B1A[2]} ${B1A[3]} ${B1A[4]}" == "0 0 0" && "${B1A[0]} ${B1A[1]} ${B1A[5]}" == "${B0A[0]} ${B0A[1]} ${B0A[5]}" ]] \
        && pass "Layer 1: frames 3-5 cut, the others untouched" || fail "Layer 1 after Make Clip [${B1A[*]}] (was [${B0A[*]}])"
    screenshot "clip-make-made"

    cl_key ctrl+z; cl_read
    [[ "$(cm_nclips)" == 0 && "$(cm_animc)" == "$B0" ]] && pass "one Ctrl+Z: no clip, Layer 1 back" || fail "undo make clip: $(cm_nclips) clips, Layer 1 [$(cm_animc)] (want [$B0])"
    cl_key ctrl+y; cl_read
    [[ "$C_LINE" == "1 3 5 1 1 LOOP 0 0 5 5" && "$(cm_animc)" == "${B1A[*]}" ]] && pass "Ctrl+Y: the clip and the cut again" \
        || fail "redo make clip: $(cl_s); Layer 1 [$(cm_animc)] (want [${B1A[*]}])"
    cl_expect "..123." 6 6 0 "Ctrl+Y: the clip's pixels"

    # -- on the clip layer: refused --
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "the clip layer"
    cm_marquee
    cl_cmd "clip layer: make clip"; cl_read
    [[ "$(cm_nclips)" == 1 ]] && pass "Make Clip on a clip layer: refused" || fail "make clip on the clip: $(cm_nclips) clips"
    cl_key ctrl+d
    for u in 1 2 3 4 5 6; do # (the marquee and the deselect are undo steps too)
        cl_key ctrl+z; cl_read
        [[ "$(cm_nclips)" == 0 && "$(cm_animc)" == "$B0" ]] && break
    done
    [[ "$(cm_nclips)" == 0 && "$(cm_animc)" == "$B0" ]] || fail "back to the start: $(cm_nclips) clips, Layer 1 [$(cm_animc)]"

    # -- no frames selected: all of them --
    click 60 "$(cl_row_y 1)"; wait_for 0.5 "Layer 1"
    cl_strip 2; cl_read
    cm_marquee
    cl_cmd "clip layer: make clip"; cl_read
    [[ "${C_LINE#* }" == "1 0 1 1 LOOP 0 0 5 5" ]] && pass "one frame selected: every frame becomes the clip (In 1, Out to the end)" || fail "make clip, all frames: $(cl_s)"
    WANT=""; for f in 1 2 3 4 5 6; do WANT+=" $f:6:6:4:4:ffffff:${CL_COLORS[$((f - 1))]}"; done
    [[ "$C_CELS" == "123456" && "$C_PIX" == "${WANT# }" ]] && pass "the clip shows every frame's own square" \
        || fail "all frames: cels [$C_CELS] pixels [$C_PIX] want [${WANT# }]"
    read -r -a B2A <<< "$(cm_animc)"
    [[ "${B2A[*]}" == "0 0 0 0 0 0" ]] && pass "Layer 1: every frame's square cut" || fail "Layer 1 after Make Clip on all frames [${B2A[*]}]"
fi
cl_done
info "=== Clip layers: Make Clip: done ==="
