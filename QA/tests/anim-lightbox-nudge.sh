#!/bin/bash
# =============================================================================
# anim-lightbox-nudge.sh — QA test: the keys act on the selected frames in the
# lightbox (field kit T-14, Rick 2026-11-08: "Keyboard shortcuts are not
# applying only to selected frames (nudge, for example)").
#
# In the lightbox, with no marquee: Ctrl+arrow (any tool), or an arrow with
# the Move tool, shifts the current layer's drawing of each selected frame
# inside its cell, as the pane Move tool drags it - one undo step per press.
# Delete (clear) and Backspace (Fill with FG) change only the selected frames.
# The old build moved / cleared / filled the whole layer, every frame.
#
# Dump: ANIMC (a CRC per frame cell), ANIMLB (the strip).
# Fixture: a 64x16 sheet of 16x16 frames, transparent: frame 1 a shape A,
# frame 2 = A moved 2 px right, frame 3 = A turned, frame 4 = A mirrored.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0
# =============================================================================
info "=== Animation: nudge / clear / fill the selected frames in the lightbox ==="

LN_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LN_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LN_DIR="/tmp/draw-qa-lbnudge-$$"
mkdir -p "$LN_DIR"
magick -size 16x16 xc:none -fill '#c04040' -draw 'rectangle 2,2 3,9' -draw 'rectangle 2,8 9,9' \
    -fill '#40c040' -draw 'rectangle 6,3 7,4' "PNG32:$LN_DIR/a.png"
magick "$LN_DIR/a.png" -roll +2+0 "PNG32:$LN_DIR/b.png"
magick "$LN_DIR/a.png" -rotate 90 "PNG32:$LN_DIR/c.png"
magick "$LN_DIR/a.png" -flop "PNG32:$LN_DIR/d.png"
magick "$LN_DIR/a.png" "$LN_DIR/b.png" "$LN_DIR/c.png" "$LN_DIR/d.png" +append "PNG32:$LN_DIR/plain.png"
LN_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,1,12,0,0).hex())")
python3 "$LN_PY" put "$LN_DIR/plain.png" "$LN_DIR/sheet.png" drAn "$LN_BLOB"

ln_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
ln_line() { grep -m1 "^$1 " "$LN_DUMP" 2>/dev/null; }
ln_read() { # A_COUNT A_CUR, T[1..4] A_T, LB_* (strip)
    ln_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(ln_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(ln_line ANIMC)"; T=(x $A_T)
    read -r _ LB_SHOWN LB_X1 LB_Y1 LB_X2 LB_Y2 LB_SY LB_SH LB_BY LB_BH LB_EY LB_EH LB_SF LB_SN LB_CW LB_CH LB_P LB_PW LB_PH LB_PAD _ <<< "$(ln_line ANIMLB)"
}
ln_cx() { echo $(( LB_X1 + LB_PAD + ($1 - LB_SF) * (LB_CW + LB_PAD) + LB_CW / 2 )); }
ln_cy() { echo $(( LB_SY + LB_PAD + LB_CH / 2 )); }
ln_pick() { # F [ctrl] - click frame F in the strip (Ctrl+click adds it)
    ln_read
    if [[ "${2:-}" == ctrl ]]; then with_mods ctrl click "$(ln_cx "$1")" "$(ln_cy)"; else click "$(ln_cx "$1")" "$(ln_cy)"; fi
    wait_for 0.4 "strip frame $1"; ln_read
}
ln_key() { park_mouse; key "$1"; wait_for 0.5 "$1"; }
ln_cells() { echo "${T[1]:-?} ${T[2]:-?} ${T[3]:-?} ${T[4]:-?}"; }
ln_is() { # "W1 W2 W3 W4" in T0 frame numbers -> 0 when the cells hold exactly those pictures
    local w=($1) i
    for i in 1 2 3 4; do [[ "${T[$i]}" == "${T0[${w[$((i - 1))]}]}" ]] || return 1; done
}
ln_only() { # F: frame F changed, the other three still as T0
    local i
    for i in 1 2 3 4; do
        if [[ $i == "$1" ]]; then [[ "${T[$i]}" != "${T0[$i]}" ]] || return 1
        else [[ "${T[$i]}" == "${T0[$i]}" ]] || return 1; fi
    done
}

info "Launching DRAW with a 64x16 sheet of 16x16 frames (A, A moved 2 px, A turned, A mirrored)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LN_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
ln_key b
ln_key KP_0
ln_read
T0=(x $A_T)
if [[ "${LB_SHOWN:-}" != -1 || "$A_COUNT" != 4 ]]; then
    fail "lightbox: shown '${LB_SHOWN:-}', $A_COUNT frames"
else
    pass "lightbox shown, 4 frames"

    # -- Ctrl+Right twice with the brush: frame 1's drawing 2 px right --
    ln_pick 1
    ln_key ctrl+Right; ln_key ctrl+Right; ln_read
    ln_is "2 2 3 4" && pass "frame 1, Ctrl+Right x2: frame 1 is now A moved 2 px (= frame 2), frames 2-4 unchanged" \
        || fail "Ctrl+Right x2 on frame 1: cells $(ln_cells), wanted T0 frames 2 2 3 4"
    ln_key ctrl+z; ln_read
    ln_only 1 && pass "undo: one step per press (1 px back, frame 1 still moved)" || fail "undo one nudge: cells $(ln_cells)"
    ln_key ctrl+z; ln_read
    ln_is "1 2 3 4" && pass "undo again: as loaded" || fail "undo the nudges: cells $(ln_cells)"

    # -- the Move tool: a bare arrow nudges the selected frames --
    ln_key v
    ln_key Right; ln_key Right; ln_read
    ln_is "2 2 3 4" && pass "Move tool, Right x2: only frame 1 moves" || fail "Move tool Right x2: cells $(ln_cells), wanted T0 frames 2 2 3 4"
    ln_key ctrl+z; ln_key ctrl+z; ln_read
    ln_is "1 2 3 4" || fail "undo the Move tool nudges: cells $(ln_cells)"
    ln_key b

    # -- two frames at once --
    ln_pick 3 ctrl # 1 + 3 selected
    ln_key ctrl+shift+Down; ln_read
    [[ "${T[1]}" != "${T0[1]}" && "${T[3]}" != "${T0[3]}" && "${T[2]}" == "${T0[2]}" && "${T[4]}" == "${T0[4]}" ]] \
        && pass "frames 1 + 3, Ctrl+Shift+Down: both drawings move, 2 and 4 stay" || fail "nudge frames 1 + 3: cells $(ln_cells)"
    ln_key ctrl+z; ln_read
    ln_is "1 2 3 4" && pass "undo: one step for both" || fail "undo the 2-frame nudge: cells $(ln_cells)"

    # -- Delete and Backspace (Fill with FG) on one frame --
    ln_pick 2
    ln_key Delete; ln_read
    ln_only 2 && pass "Delete with frame 2: only frame 2 is cleared" || fail "Delete frame 2: cells $(ln_cells) (T0 ${T0[*]:1})"
    ln_key ctrl+z; ln_read
    ln_is "1 2 3 4" && pass "undo the clear" || fail "undo the clear: cells $(ln_cells)"
    ln_key BackSpace; ln_read
    ln_only 2 && pass "Backspace (Fill with FG) with frame 2: only frame 2 is filled" || fail "Fill frame 2: cells $(ln_cells)"
    ln_key ctrl+z; ln_read
    ln_is "1 2 3 4" && pass "undo the fill" || fail "undo the fill: cells $(ln_cells)"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LN_DIR"
assert_window_exists
