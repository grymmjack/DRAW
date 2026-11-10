#!/bin/bash
# =============================================================================
# anim-lightbox-apply.sh — QA test: apply to the selected frames (Animation
# 2.7, TOOLS/ANIM-OPS ANIM_OPS_frames_geom% / ANIM_FM_*, TOOLS/ANIM-LB move).
#
# In the lightbox, with frames selected in the strip (else the current one):
# Flip (Home) / Rotate (>) act on each selected frame's cell; an effect
# (Invert) changes only the selected frames - undo AND redo; the Move tool
# dragged in a pane moves the drawing of every selected frame; ANIM > Replace
# FG Color with BG in Frames swaps a colour in them. Each is one undo step.
#
# Dump: ANIMC (a CRC per frame cell), ANIMLB (the strip), ANIMLBP (panes).
# Fixture: a 64x16 sheet of 16x16 frames, transparent: frame 1 a shape A,
# frame 2 = A moved 2 px right, frame 3 = A turned 90 CW, frame 4 = A
# mirrored - so a right flip / turn / move of frame 1 makes the very picture
# of frame 4 / 3 / 2 (the checks compare cell CRCs).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== Animation: apply to the selected frames ==="

LA_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LA_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LA_DIR="/tmp/draw-qa-lbapply-$$"
mkdir -p "$LA_DIR"
magick -size 16x16 xc:none -fill '#c04040' -draw 'rectangle 2,2 3,9' -draw 'rectangle 2,8 9,9' \
    -fill '#40c040' -draw 'rectangle 6,3 7,4' "PNG32:$LA_DIR/a.png"
magick "$LA_DIR/a.png" -roll +2+0 "PNG32:$LA_DIR/b.png"
magick "$LA_DIR/a.png" -rotate 90 "PNG32:$LA_DIR/c.png"
magick "$LA_DIR/a.png" -flop "PNG32:$LA_DIR/d.png"
magick "$LA_DIR/a.png" "$LA_DIR/b.png" "$LA_DIR/c.png" "$LA_DIR/d.png" +append "PNG32:$LA_DIR/plain.png"
LA_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
python3 "$LA_PY" put "$LA_DIR/plain.png" "$LA_DIR/sheet.png" drAn "$LA_BLOB"

la_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
la_line() { grep -m1 "^$1 " "$LA_DUMP" 2>/dev/null; }
la_read() { # A_COUNT A_CUR, T[1..4] A_T, LB_* (strip), the current pane PX PY PW PH
    la_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(la_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(la_line ANIMC)"; T=(x $A_T)
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(la_line ANIMLB)"
    local p k; p=($(la_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
la_cx() { echo $(( LB_X1 + LB_PAD + ($1 - LB_SF) * (LB_CW + LB_PAD) + LB_CW / 2 )); } # strip cell centre x of frame F
la_cy() { echo $(( LB_SY + LB_PAD + LB_CH / 2 )); }
la_pick() { # F [ctrl] - click frame F in the strip (Ctrl+click adds it)
    la_read
    if [[ "${2:-}" == ctrl ]]; then with_mods ctrl click "$(la_cx "$1")" "$(la_cy)"; else click "$(la_cx "$1")" "$(la_cy)"; fi
    wait_for 0.4 "strip frame $1"; la_read
}
la_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); } # screen x / y of cell pixel (CX, CY) in the current pane
la_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
la_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
la_palette() { # run a command by name through the command palette
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
la_cells() { echo "${T[1]:-?} ${T[2]:-?} ${T[3]:-?} ${T[4]:-?}"; }
la_is() { # "W1 W2 W3 W4" in T0 frame numbers -> 0 when the cells hold exactly those pictures
    local w=($1) i
    for i in 1 2 3 4; do [[ "${T[$i]}" == "${T0[${w[$((i - 1))]}]}" ]] || return 1; done
}

info "Launching DRAW with a 64x16 sheet of 16x16 frames (A, A moved, A turned, A mirrored)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LA_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
la_key KP_0
la_read
T0=(x $A_T)
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 4 || -z "${PX:-}" ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames, current pane '${PX:-}'"
else
    pass "lightbox shown, 4 frames, 4 different pictures"

    # -- flip / rotate one frame's cell --
    la_pick 1
    la_key Home; la_read
    la_is "4 2 3 4" && pass "Home with frame 1: its cell flips - frame 1 is now A mirrored, the rest unchanged" || fail "flip frame 1: cells $(la_cells), wanted T0 frames 4 2 3 4"
    la_key ctrl+z; la_read
    la_is "1 2 3 4" && pass "undo: one step" || fail "undo the flip: cells $(la_cells)"
    la_key greater; la_read
    la_is "3 2 3 4" && pass "> with frame 1: its cell turns 90 CW (A turned)" || fail "rotate frame 1: cells $(la_cells), wanted T0 frames 3 2 3 4"
    la_key ctrl+z; la_read
    la_is "1 2 3 4" || fail "undo the rotate: cells $(la_cells)"

    # -- two frames at once --
    la_pick 4 ctrl
    la_key Home; la_read
    la_is "4 2 3 1" && pass "frames 1 + 4 selected, Home: each flips in its own cell (1 <-> 4 pictures)" || fail "flip frames 1 + 4: cells $(la_cells), wanted T0 frames 4 2 3 1"
    la_key ctrl+z; la_read
    la_is "1 2 3 4" && pass "undo: both back in one step" || fail "undo the 2-frame flip: cells $(la_cells)"

    # -- an effect only on the selected frame; undo and redo --
    la_pick 2
    la_palette "desaturate"; la_read
    [[ "${T[2]}" != "${T0[2]}" && "${T[1]}" == "${T0[1]}" && "${T[3]}" == "${T0[3]}" && "${T[4]}" == "${T0[4]}" ]] \
        && pass "Desaturate with frame 2: only frame 2 changes" || fail "desaturate frame 2: cells $(la_cells) (T0 $A_T)"
    LA_INV="${T[2]}"
    la_key ctrl+z; la_read
    la_is "1 2 3 4" && pass "undo the desaturate" || fail "undo the desaturate: cells $(la_cells)"
    la_key ctrl+y; la_read
    [[ "${T[2]}" == "$LA_INV" && "$LA_INV" != "${T0[2]}" && "${T[1]}" == "${T0[1]}" && "${T[4]}" == "${T0[4]}" ]] && pass "redo: frame 2 desaturated again, the others still untouched" || fail "redo the desaturate: cells $(la_cells)"
    la_key ctrl+z; la_read

    # -- the Move tool: drags the drawing of the selected frames --
    la_pick 1
    la_key v
    LA_X=$(la_px 8); LA_Y=$(la_py 8)
    hover "$LA_X" "$LA_Y"; sleep 0.3 # to the pane first, as a hand would
    mouse_down "$LA_X" "$LA_Y"
    hover $(( LA_X + PW / 16 )) "$LA_Y"; sleep 0.2
    hover $(( LA_X + 2 * PW / 16 )) "$LA_Y"; sleep 0.3
    mouse_up; wait_for 0.6 "move released"
    la_read
    la_is "2 2 3 4" && pass "Move tool, 2 px right in frame 1's pane: frame 1 is now A moved (= frame 2)" || fail "move frame 1: cells $(la_cells), wanted T0 frames 2 2 3 4"
    la_key ctrl+z; la_read
    la_is "1 2 3 4" && pass "undo the move" || fail "undo the move: cells $(la_cells)"
    la_pick 1; la_pick 3 ctrl # frames 1 + 3, current 3: drag in its pane
    LA_X=$(la_px 8); LA_Y=$(la_py 8)
    hover "$LA_X" "$LA_Y"; sleep 0.3
    mouse_down "$LA_X" "$LA_Y"
    hover $(( LA_X + PW / 16 )) "$LA_Y"; sleep 0.3
    mouse_up; wait_for 0.6 "move released"
    la_read
    [[ "${T[1]}" != "${T0[1]}" && "${T[3]}" != "${T0[3]}" && "${T[2]}" == "${T0[2]}" && "${T[4]}" == "${T0[4]}" ]] \
        && pass "frames 1 + 3 selected: both drawings move, 2 and 4 stay" || fail "move frames 1 + 3: cells $(la_cells)"
    la_key ctrl+z; la_read
    la_is "1 2 3 4" && pass "undo: one step for both" || fail "undo the 2-frame move: cells $(la_cells)"

    # -- palette swap: the FG colour picked from frame 1, replaced in frames 1 + 2 --
    la_pick 1; la_pick 2 ctrl # 1 + 2 selected, current 2 (A moved: its red at x 4)
    la_key i
    click "$(la_px 4)" "$(la_py 5)"; wait_for 0.4 "pick the red"
    la_key b
    la_palette "replace fg"; la_read
    [[ "${T[1]}" != "${T0[1]}" && "${T[2]}" != "${T0[2]}" && "${T[3]}" == "${T0[3]}" && "${T[4]}" == "${T0[4]}" ]] \
        && pass "Replace FG with BG in frames 1 + 2: they change, 3 and 4 keep the red" || fail "replace FG with BG: cells $(la_cells)"
    la_key ctrl+z; la_read
    la_is "1 2 3 4" && pass "undo the colour swap" || fail "undo the colour swap: cells $(la_cells)"
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LA_DIR"
assert_window_exists
