#!/bin/bash
# =============================================================================
# anim-xsheet-edit.sh — QA test: editing on the X-sheet (Animation 4.2,
# TOOLS/ANIM-XS ANIM_XS_hold / ANIM_XS_drop).
#
# Drag along the holds row = that frame's hold, a tick per tick dragged (at
# least 1); drag a cell to another frame / layer = its drawing moves there
# (the cell it lands on replaced, the one it left cleared), Ctrl at the drop
# copies; an empty cell does not drag; drag a frame number = the frames move
# there. Each is one undo step. Checked by the pixels (ANIMC: each frame
# cell's CRC over every layer, 0 = empty), which cells are drawn (ANIMXSR)
# and the spans (ANIMXSF: hold x tick).
#
# Fixture: a 64x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour; 4 frames at 10 fps, frame 2 held 3, current 1. One layer;
# the test adds an empty one on top.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: editing on the X-sheet ==="

XE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
XE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
XE_DIR="/tmp/draw-qa-xsedit-$$"
mkdir -p "$XE_DIR"
XE_DRAW=()
XE_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 3 + n ))
    XE_DRAW+=(-fill "#${XE_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 64x16 xc:none "${XE_DRAW[@]}" "PNG32:$XE_DIR/plain.png"
python3 "$XE_PY" put "$XE_DIR/plain.png" "$XE_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<12h',1,16,16,0,0,4,1,10,0,2,1,3).hex())")"

xe_line() { grep -m1 "^$1 " "$XE_DUMP" 2>/dev/null; }
xe_read() { # XE_* (ANIMXS), XE_F spans, A_COUNT A_CUR, C[1..] (ANIMC), ROWS[r], XE_D (ANIMXSD)
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.2 "render"; } >&2
    read -r _ XE_ON XE_SHOWN XE_X1 XE_Y1 XE_X2 XE_Y2 XE_NW XE_RH XE_TW XE_GX XE_FF XE_LF XE_NR XE_FR XE_RS XE_CL _ <<< "$(xe_line ANIMXS)"
    XE_F=($(xe_line ANIMXSF)); XE_F=("${XE_F[@]:1}")
    read -r _ _ A_COUNT A_CUR _ <<< "$(xe_line ANIM)"
    C=($(xe_line ANIMC))
    ROWS=(); local r
    for (( r = 1; r <= ${XE_NR:-0}; r++ )); do ROWS[$r]="$(grep -m1 "^ANIMXSR $r " "$XE_DUMP" | cut -d' ' -f3-)"; done
    XE_D="$(xe_line ANIMXSD)"
}
xe_cells() { echo "${C[*]:1}"; }
xe_fill() { cut -d' ' -f3 <<< "${ROWS[$1]}"; }
xe_ry() { cut -d' ' -f2 <<< "${ROWS[$1]}"; }
xe_span() { # FRAME -> SPX SPW
    local i; SPX=""; SPW=""
    for (( i = 0; i + 2 < ${#XE_F[@]}; i += 3 )); do [[ "${XE_F[$i]}" == "$1" ]] && { SPX=${XE_F[$((i + 1))]}; SPW=${XE_F[$((i + 2))]}; }; done
}
xe_hold() { xe_span "$1"; echo $(( ${SPW:-0} / ${XE_TW:-1} )); } # FRAME -> its hold
xe_holds() { local f s=""; for (( f = 1; f <= A_COUNT; f++ )); do s="$s$(xe_hold $f) "; done; echo "${s% }"; }
xe_hy() { echo $(( XE_Y1 + 1 + (XE_RS + 1) * XE_RH + XE_RH / 2 )); } # the holds row's middle
xe_hy0() { echo $(( XE_Y1 + 1 + XE_RH / 2 )); }                     # the header's middle
xe_cx() { xe_span "$1"; echo $(( SPX + XE_TW / 2 )); }             # FRAME -> x of its first tick's middle
xe_cy() { echo $(( $(xe_ry "$1") + XE_RH / 2 )); }                 # ROW -> y of its middle
xe_drag() { # X1 Y1 X2 Y2 [MODS at the drop]
    mouse_down "$1" "$2"
    hover $(( ($1 + $3) / 2 )) $(( ($2 + $4) / 2 )); sleep 0.15
    hover "$3" "$4"; sleep 0.3
    if [[ -n "${5:-}" ]]; then with_mods "$5" mouse_up; else mouse_up; fi
    wait_for 0.5 "drop"
}
xe_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }

info "Launching DRAW with a 64x16 sheet of 16x16 frames (4 at 10 fps, frame 2 held 3)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$XE_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
xe_key KP_8
xe_key ctrl+shift+n
xe_read
XE_C0="$(xe_cells)"; C0=("${C[@]}")
if [[ "$XE_ON" != -1 || "${XE_TW:-0}" -lt 1 ]]; then
    fail "Num 8 did not show the X-sheet: ANIMXS '$(xe_line ANIMXS)'"
elif [[ "$XE_NR" != 2 || "$(xe_fill 1)" != 0000 || "$(xe_fill 2)" != 1111 || "$(xe_holds)" != "1 3 1 1" ]]; then
    fail "start: the X-sheet with an empty layer over the drawn one: on '$XE_ON' rows $XE_NR fills '${ROWS[1]}' / '${ROWS[2]}' holds '$(xe_holds)'"
else
    pass "the X-sheet: an empty layer over the drawn one, holds 1 3 1 1"
    XE_TOP=$(cut -d' ' -f1 <<< "${ROWS[1]}"); XE_L1=$(cut -d' ' -f1 <<< "${ROWS[2]}")

    # -- stretch a hold along the holds row; one undo step --
    xe_span 1; XE_HX=$(( SPX + XE_TW / 2 ))
    xe_drag "$XE_HX" "$(xe_hy)" $(( XE_HX + 2 * XE_TW )) "$(xe_hy)"; xe_read
    [[ "$(xe_holds)" == "1 3 1 1" ]] && fail "dragging frame 1's hold 2 ticks right changed nothing"
    [[ "$(xe_holds)" == "3 3 1 1" && "$(xe_cells)" == "$XE_C0" ]] && pass "drag frame 1's hold 2 ticks right: hold 3 (holds $(xe_holds)), no pixel moved" || fail "stretch: holds '$(xe_holds)', cells $(xe_cells)"
    xe_key ctrl+z; xe_read
    [[ "$(xe_holds)" == "1 3 1 1" ]] && pass "undo: hold 1 again (one step)" || fail "undo stretch: holds '$(xe_holds)'"
    xe_key ctrl+y; xe_read
    [[ "$(xe_holds)" == "3 3 1 1" ]] && pass "redo: hold 3" || fail "redo stretch: holds '$(xe_holds)'"
    xe_span 2; XE_HX=$(( SPX + SPW / 2 ))
    xe_drag "$XE_HX" "$(xe_hy)" $(( XE_HX - 6 * XE_TW )) "$(xe_hy)"; xe_read
    [[ "$(xe_holds)" == "3 1 1 1" ]] && pass "drag frame 2's hold far left: down to 1, not less" || fail "shrink: holds '$(xe_holds)'"
    xe_key ctrl+z; xe_key ctrl+z; xe_read
    [[ "$(xe_holds)" == "1 3 1 1" ]] || fail "undo both holds: '$(xe_holds)'"

    # -- move a drawing to another layer and frame; undo / redo --
    xe_drag "$(xe_cx 3)" "$(xe_cy 2)" "$(xe_cx 1)" "$(xe_cy 1)"; xe_read
    [[ "$(xe_fill 1)" == 1000 && "$(xe_fill 2)" == 1101 && "${C[3]}" == 0 && "$A_CUR" == 1 && "$XE_CL" == "$XE_TOP" ]] \
        && pass "drag the bottom layer's frame 3 onto the top layer's frame 1: moved (fills 1000 / 1101, frame 3 now empty), that cell current" \
        || fail "move: fills '${ROWS[1]}' / '${ROWS[2]}', cells $(xe_cells), current $A_CUR layer $XE_CL (top $XE_TOP)"
    [[ "${C[1]}" != "${C0[1]}" && "${C[2]}" == "${C0[2]}" && "${C[4]}" == "${C0[4]}" ]] && pass "frame 1 now has both drawings, frames 2 and 4 untouched" || fail "move cells: $(xe_cells) (were $XE_C0)"
    xe_key ctrl+z; xe_read
    [[ "$(xe_cells)" == "$XE_C0" && "$(xe_fill 1)" == 0000 && "$(xe_fill 2)" == 1111 ]] && pass "undo: back where it was (one step)" || fail "undo move: cells $(xe_cells), fills '${ROWS[1]}' / '${ROWS[2]}'"
    xe_key ctrl+y; xe_read
    [[ "$(xe_fill 1)" == 1000 && "${C[3]}" == 0 ]] && pass "redo: moved again" || fail "redo move: cells $(xe_cells)"

    # -- Ctrl at the drop copies, replacing what was there --
    xe_drag "$(xe_cx 4)" "$(xe_cy 2)" "$(xe_cx 3)" "$(xe_cy 2)" ctrl; xe_read
    [[ "$(xe_fill 2)" == 1111 && "${C[3]}" == "${C[4]}" && "${C[4]}" == "${C0[4]}" ]] && pass "Ctrl+drop frame 4 onto frame 3: copied (frame 3 = frame 4's drawing, frame 4 kept)" || fail "copy: fills '${ROWS[2]}', cells $(xe_cells)"
    xe_drag "$(xe_cx 1)" "$(xe_cy 1)" "$(xe_cx 4)" "$(xe_cy 2)"; xe_read
    [[ "$(xe_fill 1)" == 0000 && "$(xe_fill 2)" == 1111 && "${C[4]}" == "${C0[3]}" ]] && pass "drop onto a drawn cell replaces it (frame 3's old drawing now in frame 4)" || fail "replace: fills '${ROWS[1]}' / '${ROWS[2]}', cells $(xe_cells)"
    XE_C1="$(xe_cells)"

    # -- an empty cell does not drag --
    xe_drag "$(xe_cx 2)" "$(xe_cy 1)" "$(xe_cx 3)" "$(xe_cy 2)"; xe_read
    [[ "$(xe_cells)" == "$XE_C1" && "$(xe_fill 2)" == 1111 ]] && pass "dragging an empty cell onto a drawn one: nothing happens" || fail "empty drag: cells $(xe_cells) (were $XE_C1)"

    # -- drag a frame number: the frame moves there --
    C1=("${C[@]}")
    xe_drag "$(xe_cx 4)" "$(xe_hy0)" $(( $(xe_cx 1) - XE_TW / 4 )) "$(xe_hy0)"; xe_read
    [[ "$(xe_cells)" == "${C1[4]} ${C1[1]} ${C1[2]} ${C1[3]}" && "$(xe_holds)" == "1 1 3 1" && "$A_CUR" == 1 ]] \
        && pass "drag frame 4's number before frame 1: it is frame 1 now, the holds go with the frames ($(xe_holds))" || fail "reorder: cells $(xe_cells) (were ${C1[*]:1}), holds '$(xe_holds)', current $A_CUR"
    xe_key ctrl+z; xe_read
    [[ "$(xe_cells)" == "$XE_C1" && "$(xe_holds)" == "1 3 1 1" ]] && pass "undo: the order back" || fail "undo reorder: cells $(xe_cells), holds '$(xe_holds)'"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$XE_DIR"
assert_window_exists
