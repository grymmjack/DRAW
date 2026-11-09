#!/bin/bash
# =============================================================================
# anim-lightbox-paint.sh — QA test: in the lightbox Paste in Place lands on
# the same spot in the current frame, and a gradient fill spans the frame
# filled, not the sheet (Rick 2026-11-09: "anything that uses the canvas needs
# to consider lightbox mode").
#
# Paste in Place of something copied in frame 1, done in frame 2, puts it at
# the same place in frame 2 (the old build pasted it back in frame 1). A fill
# with a drawer gradient runs the gradient across the frame clicked in, so
# filling two empty frames gives the same picture (the old build ran it across
# the whole sheet: each frame got a different slice).
#
# Dump: ANIMC (a CRC per frame cell), ANIM, DRAWERL (... paint mode, gradient
# picked - DEFAULT_DRAW_MODE=2 starts in drawer gradient paint).
# Fixture: a 64x16 sheet of 16x16 frames: frame 1 a shape inside (2,2)-(9,9),
# frames 2-4 empty.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 DEFAULT_DRAW_MODE=2
# =============================================================================
info "=== Animation: Paste in Place and gradient fills in the current frame ==="

LE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LE_DIR="/tmp/draw-qa-lbpaint-$$"
mkdir -p "$LE_DIR"
magick -size 16x16 xc:none -fill '#c04040' -draw 'rectangle 2,2 3,9' -draw 'rectangle 2,8 9,9' \
    -fill '#40c040' -draw 'rectangle 6,3 7,4' "PNG32:$LE_DIR/a.png"
magick -size 16x16 xc:none "PNG32:$LE_DIR/e.png"
magick "$LE_DIR/a.png" "$LE_DIR/e.png" "$LE_DIR/e.png" "$LE_DIR/e.png" +append "PNG32:$LE_DIR/plain.png"
LE_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
python3 "$LE_PY" put "$LE_DIR/plain.png" "$LE_DIR/sheet.png" drAn "$LE_BLOB"

le_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
le_line() { grep -m1 "^$1 " "$LE_DUMP" 2>/dev/null; }
le_read() {
    le_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(le_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(le_line ANIMC)"; T=(x $A_T)
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(le_line ANIMLB)"
    local p k; p=($(le_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
le_cells() { echo "${T[*]:1}"; }
le_is() { local want=($1) k; for k in 1 2 3 4; do [[ "${T[$k]}" == "${T0[${want[$((k - 1))]}]}" ]] || return 1; done; }
le_others() { # FRAME: every other frame still holds its own picture
    local k; for k in 1 2 3 4; do [[ $k == "$1" ]] && continue; [[ "${T[$k]}" == "${T0[$k]}" ]] || return 1; done
}
le_pick() { # FRAME - Num 5 (next frame) until it is current (the strip may be hidden behind the X-sheet)
    local n; le_read
    for (( n = 0; n < 5 && A_CUR != $1; n++ )); do le_key KP_5; le_read; done
}
le_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); }
le_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
le_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
le_palette() { park_mouse; key question; wait_for 1.0 "Command palette"; type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"; }


info "Launching DRAW with the 4-frame sheet"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LE_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
le_read
[[ "${LB_SHOWN:-}" == -1 ]] || { le_key KP_0; le_read; }
T0=(x $A_T)
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 4 || -z "${PX:-}" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames, current pane '${PX:-}'"
else
    pass "lightbox shown, 4 frames"

    # -- Paste in Place: copied in frame 1, pasted in frame 2 at the same spot --
    le_pick 1
    le_key m
    LE_X=$(le_px 1); LE_Y=$(le_py 1)
    hover "$LE_X" "$LE_Y"; sleep 0.3
    mouse_down "$LE_X" "$LE_Y"
    hover "$(le_px 6)" "$(le_py 6)"; sleep 0.2
    hover "$(le_px 11)" "$(le_py 11)"; sleep 0.4
    mouse_up; wait_for 0.6 "marquee released"
    le_key ctrl+c
    le_palette "deselect"
    le_pick 2
    le_palette "paste in place"
    le_key Return; le_palette "deselect"; le_read
    le_is "1 1 3 4" && pass "copied in frame 1, Paste in Place in frame 2: the same spot in frame 2 (= frame 1), frame 1 untouched" || fail "paste in place in frame 2: cells $(le_cells), wanted T0 frames 1 1 3 4 (T0 ${T0[*]:1})"
    le_key ctrl+z; le_read
    le_is "1 2 3 4" || fail "undo the paste: cells $(le_cells)"

    # -- a gradient fill in two empty frames: the same picture (DEFAULT_DRAW_MODE=2: drawer gradient paint) --
    le_read
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ DW_MODE DW_GRAD _ <<< "$(le_line DRAWERL)"
    if [[ "${DW_MODE:-}" != 2 || "${DW_GRAD:-0}" -lt 1 ]]; then
        fail "no drawer gradient to paint with: mode '${DW_MODE:-}' gradient '${DW_GRAD:-}' (DRAWERL '$(le_line DRAWERL)')"
    else
        le_pick 3
        le_key f
        click "$(le_px 8)" "$(le_py 8)"; wait_for 0.6 "gradient fill 3"; le_read
        G3=${T[3]}
        [[ "$G3" != 0 && "${T[1]}" == "${T0[1]}" && "${T[2]}" == 0 && "${T[4]}" == 0 ]] || fail "gradient fill of frame 3: cells $(le_cells)"
        le_key ctrl+z; le_read
        le_pick 4
        le_key f
        click "$(le_px 8)" "$(le_py 8)"; wait_for 0.6 "gradient fill 4"; le_read
        [[ "$G3" != 0 && "${T[4]}" == "$G3" && "${T[3]}" == 0 && "${T[2]}" == 0 ]] && pass "a gradient fill of empty frame 3, and of empty frame 4: the same picture - the gradient spans the frame" || fail "gradient fill of frame 4: ${T[4]}, frame 3 gave $G3 (cells $(le_cells))"
        le_key ctrl+z
    fi
    le_key b
    screenshot "anim-lightbox-paint"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LE_DIR"
assert_window_exists
