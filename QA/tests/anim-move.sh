#!/bin/bash
# =============================================================================
# anim-move.sh — QA test: ANIM > Move Brush (TOOLS/ANIM-MVBRUSH, A6).
#
#   - Start needs a brush: with none the mode stays off
#   - A drag in a frame's pane sets the path (relative to that frame's cell);
#     the tools do not act while the mode is on
#   - Esc cancels: nothing is stamped
#   - Enter stamps the brush once in each frame of the range, along the path,
#     spaced by the ease (none / in / out / in-out); one undo step (Ctrl+Z
#     takes every stamp away, Ctrl+Y puts them back)
#   - A plain brush: the same picture in every frame
#   - An AnimBrush: the next cel each frame, or every N frames
#   - The range: from the path's frame to the last frame
#
# Dump: MVB active dragging hasPath fromF ease every rx0 ry0 rx1 ry1 frames undoPos;
# MVBP f:x:y:cel (the planned top left in the cell); MVBB f:x:y:w:h (what is
# drawn in each frame's cell on the current layer, "-" nothing); MVBK f:cel
# (the AnimBrush cel at each step's spot).
# Fixture: a 96x16 sheet of 6 frames of 16x16; frame k a 4x4 square of its own
# colour at (6, 6). The path runs from cell px (2, 2) to (12, 10).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0 LIGHTBOX=0 XSHEET=0 LIGHTBOX_PANES=3 LIGHTBOX_STRIP_FLOW=ROW
# =============================================================================
info "=== ANIM > Move Brush ==="

MV_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
MV_DUMPF="$DRAW_ROOT/QA/.dock-dump.txt"
MV_DIR="/tmp/draw-qa-animmove-$$"
mkdir -p "$MV_DIR"
MV_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
MV_DRAW=()
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 ))
    MV_DRAW+=(-fill "#${MV_COLORS[$n]}" -draw "rectangle $(( x + 6 )),6 $(( x + 9 )),9")
done
magick -size 96x16 xc:none "${MV_DRAW[@]}" "PNG32:$MV_DIR/plain.png"
MV_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,12,0,0).hex())")
python3 "$MV_PY" put "$MV_DIR/plain.png" "$MV_DIR/sheet.png" drAn "$MV_BLOB"

mv_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
mv_line() { grep -m1 "^$1 " "$MV_DUMPF" 2>/dev/null; }
mv_read() {
    mv_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(mv_line ANIM)"
    read -r _ AB_N AB_CUR AB_W AB_H _ <<< "$(mv_line ABR)"
    read -r _ M_ON M_DRAG M_PATH M_FROM M_EASE M_EVERY M_X0 M_Y0 M_X1 M_Y1 M_N M_HIST _ <<< "$(mv_line MVB)"
    M_P=$(mv_line MVBP | cut -d' ' -f2-)
    M_B=$(mv_line MVBB | cut -d' ' -f2-)
    M_K=$(mv_line MVBK | cut -d' ' -f2-)
    local p k; p=($(mv_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
mv_s() { echo "MVB on ${M_ON:-?} drag ${M_DRAG:-?} path ${M_PATH:-?} from ${M_FROM:-?} ease ${M_EASE:-?} every ${M_EVERY:-?} (${M_X0:-?},${M_Y0:-?})-(${M_X1:-?},${M_Y1:-?}) n ${M_N:-?}"; }
mv_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); }
mv_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
mv_strip() { # F [shift] - click frame F in the lightbox strip
    local x1 sy sf cw ch pad
    read -r _ _ x1 _ _ _ sy _ _ _ _ _ sf _ cw ch _ _ _ pad _ <<< "$(mv_line ANIMLB)"
    local x=$(( x1 + pad + ($1 - sf) * (cw + pad) + cw / 2 )) y=$(( sy + pad + ch / 2 ))
    if [[ "${2:-}" == shift ]]; then with_mods shift click "$x" "$y"; else click "$x" "$y"; fi
    wait_for 0.4 "strip $1"
}
mv_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
mv_cmd() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    # the palette takes one typed key per frame: on a slow profile a long query is still
    # going in a second later, so wait by its length before Enter
    type_text "$1"; wait_for "$(awk -v n=${#1} 'BEGIN{printf "%.1f", 0.6 + n * 0.08}')" "Filtered"
    [[ -n "${MV_DEBUG:-}" ]] && { snap_region 0 0 1152 712 "mvcmd"; cp "$SNAP_RESULT" "$MV_DEBUG/mvcmd-$(date +%s%N).png"; }
    key Return; wait_for 1.0 "$1"
}
mv_undo() { # KEY (ctrl+z / ctrl+y) - the undo position must move; a key the app never saw
    # (slow frames on the user profile) is sent once more, an undo that moved without
    # changing the pixels is left for the checks to catch
    local h0; mv_read; h0=$M_HIST
    mv_key "$1"; mv_read
    [[ "$M_HIST" == "$h0" ]] && { info "$1 not seen (undo position $h0) - once more"; mv_key "$1"; mv_read; }
}
mv_set() { # "COMMAND" VAR WANT - a setting from the palette, once more if the palette missed it
    # (short queries: on the slow user profile a long one can lose a typed key)
    mv_cmd "$1"; mv_read
    [[ "${!2}" == "$3" ]] || { mv_cmd "$1"; mv_read; }
}
mv_drag() { # X0 Y0 X1 Y1 - cell px in the current frame's pane
    mv_read
    mouse_down "$(mv_px "$1")" "$(mv_py "$2")"
    hover "$(mv_px $(( ($1 + $3) / 2 )))" "$(mv_py $(( ($2 + $4) / 2 )))"; sleep 0.2
    hover "$(mv_px "$3")" "$(mv_py "$4")"; sleep 0.3
    mouse_up; wait_for 0.5 "path"
}
# the expected MVBB line: frames FROM..6, brush W x H (its middle on the path), EASE
mv_want_b() { # FROM EASE W H
    python3 - "$@" <<'PY'
import sys, math
fr, ease, w, h = map(int, sys.argv[1:5])
x0, y0, x1, y1 = 2, 2, 12, 10
fs = list(range(fr, 7)); n = len(fs); out = []
for f in range(1, 7):
    if f not in fs: out.append(f"{f}:-"); continue
    i = fs.index(f); t = i / (n - 1) if n > 1 else 0.0
    e = [t, t * t, t * (2 - t), t * t * (3 - 2 * t)][ease]
    x = math.floor(x0 + (x1 - x0) * e + .5) - w // 2
    y = math.floor(y0 + (y1 - y0) * e + .5) - h // 2
    cx, cy = max(0, x), max(0, y)
    out.append(f"{f}:{cx}:{cy}:{min(16, x + w) - cx}:{min(16, y + h) - cy}")
print(" ".join(out))
PY
}
# the expected MVBK line: frames FROM..6, N cels, the next every E frames
mv_want_k() { # FROM N E
    local fr=$1 n=$2 e=$3 f i=0 out=""
    for (( f = fr; f <= 6; f++ )); do out+=" $f:$(( (i / e) % n + 1 ))"; i=$(( i + 1 )); done
    echo "${out# }"
}
mv_empty="1:- 2:- 3:- 4:- 5:- 6:-"

info "Launching DRAW with a 96x16 sheet of 6 frames"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$MV_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
mv_key KP_0
mv_read
if [[ "$A_COUNT" != 6 || -z "${PX:-}" || -z "${M_ON:-}" ]]; then
    fail "lightbox: $A_COUNT frames, current pane '${PX:-}', $(mv_s)"
else
    # -- no brush: Start does nothing --
    mv_cmd "move brush: start"; mv_read
    [[ "$M_ON" == 0 ]] && pass "Start without a brush: the mode stays off" || fail "no brush: $(mv_s)"

    # -- a plain brush: frame 1's square --
    mv_key m
    mouse_down "$(mv_px 6)" "$(mv_py 6)"; hover "$(mv_px 8)" "$(mv_py 8)"; sleep 0.2; hover "$(mv_px 9)" "$(mv_py 9)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    mv_key ctrl+b; mv_key ctrl+shift+n; mv_read
    [[ "$M_B" == "$mv_empty" ]] && pass "the stamps' layer is empty" || fail "new layer: [$M_B]"

    # the pane before Start: Start opens the Animation panel on its Move rows
    # (2026-11-11) and the end of the move shuts it, so compare after Esc to this
    mv_read; snap_region "$PX" "$PY" "$PW" "$PH" "mv-idle"; MV_SNAP_IDLE=$SNAP_RESULT
    mv_cmd "move brush: start"; mv_read
    [[ "$M_ON" == -1 && "$M_PATH" == 0 ]] && pass "Start with a brush: the mode is on, no path yet" || fail "start: $(mv_s)"
    mv_read; snap_region "$PX" "$PY" "$PW" "$PH" "mv-before"; MV_SNAP_BEFORE=$SNAP_RESULT
    mv_drag 2 2 12 10; mv_read
    snap_region "$PX" "$PY" "$PW" "$PH" "mv-ghost"; MV_SNAP_GHOST=$SNAP_RESULT
    assert_regions_differ "$MV_SNAP_BEFORE" "$MV_SNAP_GHOST" "the path and the ghosted stamps show in the pane"
    [[ "$M_ON" == -1 && "$M_PATH" == -1 && "$M_FROM" == 1 && "$M_X0 $M_Y0 $M_X1 $M_Y1" == "2 2 12 10" && "$M_N" == 6 ]] \
        && pass "the drag set the path (2,2)-(12,10) in frame 1, 6 frames" || fail "path: $(mv_s)"
    [[ "$M_B" == "$mv_empty" ]] && pass "the drag drew nothing (no tool acts in the mode)" || fail "drag drew: [$M_B]"

    # -- Esc cancels --
    mv_key Escape; mv_read
    [[ "$M_ON" == 0 && "$M_B" == "$mv_empty" ]] && pass "Esc: the mode is off, nothing stamped" || fail "Esc: $(mv_s) [$M_B]"
    snap_region "$PX" "$PY" "$PW" "$PH" "mv-after-esc"
    assert_regions_same "$MV_SNAP_IDLE" "$SNAP_RESULT" "after Esc the ghost is gone"

    # -- Enter with a plain brush, ease none --
    mv_cmd "move brush: start"; mv_drag 2 2 12 10
    mv_key Return; mv_read
    W=$(mv_want_b 1 0 4 4)
    [[ "$M_ON" == 0 && "$M_B" == "$W" ]] && pass "plain brush, ease none: one stamp per frame along the path" || fail "plain none: [$M_B], wanted [$W]; $(mv_s)"

    # -- one undo step --
    mv_undo ctrl+z; mv_read
    [[ "$M_B" == "$mv_empty" ]] && pass "Ctrl+Z takes every stamp away" || fail "undo: [$M_B]"
    mv_undo ctrl+y; mv_read
    [[ "$M_B" == "$W" ]] && pass "Ctrl+Y puts them back" || fail "redo: [$M_B]"
    mv_undo ctrl+z; mv_read

    # -- the eases (plain brush) --
    E_NAME=(none "in" out "in-out")
    for E in 1 2 3; do
        mv_set "move brush: ease ${E_NAME[$E]}" M_EASE "$E"
        mv_cmd "move brush: start"; mv_drag 2 2 12 10
        mv_key Return; mv_read
        W=$(mv_want_b 1 $E 4 4)
        [[ "$M_EASE" == "$E" && "$M_B" == "$W" ]] && pass "plain brush, ease ${E_NAME[$E]}" || fail "ease ${E_NAME[$E]}: [$M_B], wanted [$W]; $(mv_s)"
        mv_undo ctrl+z; mv_read
        [[ "$M_B" == "$mv_empty" ]] || fail "ease ${E_NAME[$E]}: undo left [$M_B]"
    done
    mv_set "move brush: ease none" M_EASE 0

    # -- an AnimBrush: 4 cels from frames 3-6 (merged: the stamps' layer is empty) --
    mv_key ctrl+b
    mv_key KP_5; mv_key KP_5; mv_read
    mv_strip 6; mv_strip 3 shift; mv_read # frames 3-6 selected (nothing selected = every frame)
    mv_key m
    mouse_down "$(mv_px 6)" "$(mv_py 6)"; hover "$(mv_px 8)" "$(mv_py 8)"; sleep 0.2; hover "$(mv_px 9)" "$(mv_py 9)"; sleep 0.3
    mouse_up; wait_for 0.6 "marquee"
    mv_cmd "animbrush: pick up merged"; mv_read
    if [[ "$AB_N" != 4 || "$AB_W" != 4 ]]; then
        fail "AnimBrush pick up: $AB_N cels ${AB_W}x$AB_H"
    else
        pass "AnimBrush of 4 cels picked up"
        mv_strip 1; mv_read # frame 1, alone selected (the Move Brush range follows a selection)
        mv_cmd "move brush: start"; mv_drag 2 2 12 10
        mv_key Return; mv_read
        W=$(mv_want_b 1 0 4 4); K=$(mv_want_k 1 4 1)
        [[ "$M_B" == "$W" ]] && pass "AnimBrush: one stamp per frame along the path" || fail "AnimBrush bounds: [$M_B], wanted [$W]"
        [[ "$M_K" == "$K" ]] && pass "AnimBrush: the next cel each frame ($K)" || fail "AnimBrush cels: [$M_K], wanted [$K]"
        mv_undo ctrl+z; mv_read
        [[ "$M_B" == "$mv_empty" ]] && pass "AnimBrush: Ctrl+Z takes it all away" || fail "AnimBrush undo: [$M_B]"

        # -- next cel every 2 frames --
        mv_set "cel every 2" M_EVERY 2
        mv_cmd "move brush: start"; mv_drag 2 2 12 10
        mv_key Return; mv_read
        K=$(mv_want_k 1 4 2)
        [[ "$M_EVERY" == 2 && "$M_K" == "$K" ]] && pass "AnimBrush: the next cel every 2 frames ($K)" || fail "every 2: [$M_K], wanted [$K]; $(mv_s)"
        mv_undo ctrl+z
        mv_set "move brush: next cel every frame" M_EVERY 1

        # -- the range: from the path's frame (3) to the last --
        mv_key KP_5; mv_key KP_5; mv_read
        mv_cmd "move brush: start"; mv_drag 2 2 12 10; mv_read
        [[ "$M_FROM" == 3 && "$M_N" == 4 ]] && pass "a path in frame 3: frames 3-6" || fail "range: $(mv_s)"
        mv_key Return; mv_read
        W=$(mv_want_b 3 0 4 4); K=$(mv_want_k 3 4 1)
        [[ "$M_B" == "$W" && "$M_K" == "$K" ]] && pass "frames 3-6 stamped, cels $K" || fail "range 3-6: [$M_B] [$M_K], wanted [$W] [$K]"
        mv_undo ctrl+z
    fi
fi

assert_no_crash
draw_quit
rm -rf "$MV_DIR"
