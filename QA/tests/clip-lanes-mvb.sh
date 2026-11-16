#!/bin/bash
# =============================================================================
# clip-lanes-mvb.sh — QA test: ANIM > Move Brush > Apply as Clip (TOOLS/ANIM-
# MVBRUSH MVB_apply_clip + TOOLS/CLIP lanes, phase 3 L9).
#
# The fixture's AnimBrush (4 cels, 4x4), Move Brush from frame 1, a straight
# path (2, 2) - (12, 10) in the cell:
#   - Apply as Clip: a new clip layer, In 1 Out 6, its top left at (0, 0),
#     X keys 0 -> 10 and Y keys 0 -> 8 over frames 1-6 (from In: 0 -> 5)
#   - its pixels sit where Apply would stamp (the same rounding)
#   - Ctrl+Z: the layer gone; Ctrl+Y: back with its lanes
#
# Dump: CLIP slot src in out start every mode fx fy px py, CLIPX slot
# f:x:y:w:h:tl:tr, CLIPL slot lane n f:v:e ..., MVB (the Move Brush).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Clip layers: Move Brush > Apply as Clip ==="
source "$DRAW_ROOT/QA/clip-lib.sh"
mc_read() {
    cl_read
    read -r _ MC_SLOT MC_SRC MC_IN MC_OUT _ MC_EVERY _ _ _ MC_PX MC_PY _ <<< "$(grep -m1 '^CLIP [0-9]* 2 ' "$CL_DUMPF")"
    MC_PIX=$(grep -m1 "^CLIPX ${MC_SLOT:-x} " "$CL_DUMPF" | cut -d' ' -f3-)
    MC_N=$(grep -c '^CLIP ' "$CL_DUMPF")
    read -r _ M_ON _ _ _ _ _ _ _ _ _ _ _ <<< "$(cl_line MVB)"
}
mc_keys() { grep "^CLIPL ${MC_SLOT:-x} $1 " "$CL_DUMPF" | cut -d' ' -f4-; }
mc_geom() { # the CLIPX entries cut to f:x:y:w:h
    local e o=""
    for e in $MC_PIX; do o+=" $(cut -d: -f1-5 <<< "$e")"; done
    echo "${o# }"
}
mc_s() { echo "new clip [slot ${MC_SLOT:-} src ${MC_SRC:-} in ${MC_IN:-} out ${MC_OUT:-} every ${MC_EVERY:-} at ${MC_PX:-},${MC_PY:-}] X [$(mc_keys 1)] Y [$(mc_keys 2)] clips ${MC_N:-?} MVB on ${M_ON:-?}; $(cl_s)"; }
# where Apply stamps a 4x4 brush, its middle on (2,2)-(12,10), frames 1-6, no ease
WANT=$(python3 - <<'PY'
import math
out = []
for i in range(6):
    t = i / 5
    x = math.floor(2 + 10 * t + .5) - 2; y = math.floor(2 + 8 * t + .5) - 2
    cx, cy = max(0, x), max(0, y)
    out.append(f"{i + 1}:{cx}:{cy}:{min(16, x + 4) - cx}:{min(16, y + 4) - cy}")
print(" ".join(out))
PY
)

cl_setup
if (( CL_OK )); then
    cl_key KP_1; cl_read
    cl_cmd "move brush: start"; cl_read
    mouse_down "$(cl_px 2)" "$(cl_py 2)"; hover "$(cl_px 7)" "$(cl_py 6)"; sleep 0.2; hover "$(cl_px 12)" "$(cl_py 10)"; sleep 0.3
    mouse_up; wait_for 0.6 "path"
    cl_cmd "move brush: apply as clip"; mc_read
    [[ -n "$MC_SLOT" && "$MC_N" == 2 && "$MC_IN $MC_OUT $MC_EVERY" == "1 6 1" && "$MC_PX $MC_PY" == "0 0" && "$M_ON" == 0 ]] \
        && pass "Apply as Clip: a new clip layer, frames 1-6, top left (0, 0); the Move Brush ends" || fail "apply as clip: $(mc_s)"
    [[ "$(mc_keys 1)" == "2 0:0:0 5:10:0" && "$(mc_keys 2)" == "2 0:0:0 5:8:0" ]] && pass "the move in its lanes: X 0 -> 10, Y 0 -> 8" || fail "lanes: $(mc_s)"
    [[ "$(mc_geom)" == "$WANT" ]] && pass "its pixels where Apply would stamp ($WANT)" || fail "pixels [$(mc_geom)] want [$WANT]"
    screenshot "clip-lanes-mvb"
    L0="$(mc_keys 1)|$(mc_keys 2)"

    cl_key ctrl+z; mc_read
    [[ "$MC_N" == 1 ]] && pass "Ctrl+Z: the clip layer gone" || fail "undo: $(mc_s)"
    cl_key ctrl+y; mc_read
    [[ "$MC_N" == 2 && "$(mc_keys 1)|$(mc_keys 2)" == "$L0" && "$(mc_geom)" == "$WANT" ]] && pass "Ctrl+Y: back, with its lanes" || fail "redo: $(mc_s)"
    assert_no_crash
fi
cl_done
info "=== Clip layers: Move Brush > Apply as Clip: done ==="
