#!/bin/bash
# =============================================================================
# anim-layer-flags.sh — QA test: a layer the same on every frame, and reference
# layers (Animation 2.8, TOOLS/ANIM-OPS ANIM_LF_* / ANIM_SAME_*).
#
# ANIM > Layer Same on Every Frame puts the current frame's drawing of the
# layer on every frame; from then on a stroke in any frame lands on all of
# them - its undo and redo too - and frame ops leave the layer as it is (a
# new blank frame still shows it). ANIM > Reference Layer keeps the layer on
# screen but out of every export (Flatten & Save writes it transparent). Each
# switch is one undo step, and both come back after Ctrl+S (a PNG document
# keeps its layers in the PNG's drAw chunk, the flags in drAn).
#
# Dump: ANIMC (a CRC per frame cell), ANIMLF curRef curSame nFlags flatCrc
# (flatCrc = what an export writes), ANIMLBP (panes).
# Fixture: a 64x16 sheet of 16x16 frames, transparent, frame k a 4x4 square of
# its own colour at x = 2 + 3(k-1), y 6. Current 2. One layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: layer same on every frame, reference layers ==="

LF_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LF_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LF_DIR="/tmp/draw-qa-layerflags-$$"
mkdir -p "$LF_DIR"
LF_DRAW=()
LF_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 2 + 3 * n ))
    LF_DRAW+=(-fill "#${LF_COLORS[$n]}" -draw "rectangle $x,6 $(( x + 3 )),9")
done
magick -size 64x16 xc:none "${LF_DRAW[@]}" "PNG32:$LF_DIR/plain.png"
LF_BLOB=$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,2,12,0,0).hex())")
python3 "$LF_PY" put "$LF_DIR/plain.png" "$LF_DIR/sheet.png" drAn "$LF_BLOB"
LF_EMPTY=$(python3 -c "import zlib;print('%x' % zlib.crc32(bytes(64 * 16 * 4)))") # flatCrc of a transparent sheet

lf_settle() { { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.15 "render"; } >&2; }
lf_line() { grep -m1 "^$1 " "$LF_DUMP" 2>/dev/null; }
lf_read() { # A_COUNT A_CUR, T[1..] A_T, F_REF F_SAME F_N F_FLAT, the current pane PX PY PW PH
    lf_settle
    read -r _ _ A_COUNT A_CUR _ <<< "$(lf_line ANIM)"
    A_T=""; read -r _ A_T <<< "$(lf_line ANIMC)"; T=(x $A_T)
    read -r _ F_REF F_SAME F_N F_FLAT _ <<< "$(lf_line ANIMLF)"
    local p k; p=($(lf_line ANIMLBP)); PX=""; PY=""; PW=""; PH=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do
        if [[ "${p[$k]}" == "$A_CUR" ]]; then PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; PH=${p[$((k + 4))]}; fi
    done
}
lf_f() { echo "ref '${F_REF:-}' same '${F_SAME:-}' flags '${F_N:-}' export '${F_FLAT:-}'"; }
lf_cells() { echo "${T[*]:1}"; }
lf_all() { # W - TRUE when every frame cell's CRC is W
    local i
    for (( i = 1; i <= A_COUNT; i++ )); do [[ "${T[$i]}" == "$1" ]] || return 1; done
}
lf_is_t0() { [[ "$A_T" == "$LF_T0" ]]; }
lf_px() { echo $(( PX + (2 * $1 + 1) * PW / 32 )); } # screen x / y of cell pixel (CX, CY) in the current pane
lf_py() { echo $(( PY + (2 * $1 + 1) * PH / 32 )); }
lf_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
lf_palette() { # run a command by name through the command palette
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
lf_dot() { click "$(lf_px "$1")" "$(lf_py "$2")"; wait_for 0.6 "brush dot"; }

info "Launching DRAW with a 64x16 sheet of 16x16 frames (4, current 2, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LF_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse
key b
wait_for 0.3 "Brush"
lf_key KP_0
lf_read
LF_T0="$A_T"; T0=(x $A_T); LF_F0="$F_FLAT"
if [[ "$A_COUNT" != 4 || -z "${PX:-}" || -z "${F_FLAT:-}" || "${T0[1]}" == "${T0[2]}" ]]; then
    fail "start: $A_COUNT frames, current pane '${PX:-}', $(lf_f), cells $(lf_cells)"
else
    pass "lightbox, 4 frames with 4 different drawings, no layer flags ($(lf_f))"

    # -- same on every frame: frame 2's drawing on all of them; one undo step --
    lf_palette "layer same on every frame"; lf_read
    [[ "$F_SAME" == -1 ]] && lf_all "${T0[2]}" && pass "Same on Every Frame: all 4 frames now hold frame 2's drawing" || fail "same on: $(lf_f), cells $(lf_cells) (frame 2 was ${T0[2]})"
    lf_key ctrl+z; lf_read
    [[ "$F_SAME" == 0 ]] && lf_is_t0 && pass "undo: the switch off, the 4 drawings back" || fail "undo same on: $(lf_f), cells $(lf_cells)"
    lf_key ctrl+y; lf_read
    [[ "$F_SAME" == -1 ]] && lf_all "${T0[2]}" && pass "redo: on again" || fail "redo same on: $(lf_f), cells $(lf_cells)"

    # -- a dot in frame 2's pane lands on every frame; undo / redo too --
    lf_dot 12 12; lf_read
    LF_D="${T[1]}"
    [[ "$LF_D" != "${T0[2]}" ]] && lf_all "$LF_D" && pass "a brush dot in frame 2: every frame gets it" || fail "dot with the switch on: cells $(lf_cells) (before ${T0[2]})"
    lf_key ctrl+z; lf_read
    lf_all "${T0[2]}" && pass "undo the dot: gone from every frame" || fail "undo the dot: cells $(lf_cells)"
    lf_key ctrl+y; lf_read
    lf_all "$LF_D" && pass "redo the dot: on every frame again" || fail "redo the dot: cells $(lf_cells)"

    # -- frame ops leave the layer as it is: a new blank frame shows it --
    lf_key shift+KP_Add; lf_read
    [[ "$A_COUNT" == 5 ]] && lf_all "$LF_D" && pass "Add Blank Frame: frame 5 shows the layer too" || fail "blank frame: $A_COUNT frames, cells $(lf_cells)"
    lf_key ctrl+z; lf_read
    [[ "$A_COUNT" == 4 ]] && lf_all "$LF_D" || fail "undo the blank frame: $A_COUNT frames, cells $(lf_cells)"

    # -- switched off: a dot lands on the current frame only --
    lf_palette "layer same on every frame"; lf_read
    lf_dot 3 3; lf_read
    [[ "$F_SAME" == 0 && "${T[1]}" == "$LF_D" && "${T[2]}" != "$LF_D" && "${T[3]}" == "$LF_D" ]] && pass "switched off: a dot changes frame 2 only" || fail "dot with the switch off: $(lf_f), cells $(lf_cells)"
    lf_key ctrl+z; lf_key ctrl+z; lf_read
    [[ "$F_SAME" == -1 ]] && lf_all "$LF_D" || fail "undo dot + switch off: $(lf_f), cells $(lf_cells)"

    # -- reference layer: on screen, out of the export --
    lf_read; LF_F1="$F_FLAT"
    park_mouse; wait_for 0.4 "pointer away"
    snap_region "$PX" "$PY" "$PW" "$PH" "lf_pane_before" >/dev/null
    LF_SNAP_A="${SNAP_RESULT:-}"
    lf_palette "reference layer"; lf_read
    park_mouse; wait_for 0.4 "pointer away"
    snap_region "$PX" "$PY" "$PW" "$PH" "lf_pane_ref" >/dev/null
    [[ "$F_REF" == -1 && "$F_FLAT" == "$LF_EMPTY" && "$LF_F1" != "$LF_EMPTY" ]] && pass "Reference Layer: the export is empty (the only layer left out)" || fail "reference on: $(lf_f), wanted export $LF_EMPTY (was $LF_F1)"
    LF_AE=$(magick compare -metric AE "$LF_SNAP_A" "${SNAP_RESULT:-/nonexistent}" null: 2>&1 | awk '{print $1}')
    if [[ "$LF_AE" == 0 ]]; then
        pass "and the layer is still on screen, unchanged"
    else
        fail "the pane changed when the layer became a reference layer ($LF_AE pixels differ)"
    fi
    lf_palette "flatten & save"; wait_for 1.0 "written"
    LF_MAXA=$(magick "$LF_DIR/sheet.png" -alpha extract -format '%[fx:maxima]' info: 2>/dev/null)
    [[ "$LF_MAXA" == 0 ]] && pass "Flatten & Save: the PNG written is fully transparent" || fail "Flatten & Save: alpha max '$LF_MAXA' (wanted 0)"
    lf_key ctrl+z; lf_read
    [[ "$F_REF" == 0 && "$F_FLAT" == "$LF_F1" ]] && pass "undo: exported again" || fail "undo reference: $(lf_f), wanted export $LF_F1"
    lf_key ctrl+y; lf_read
    [[ "$F_REF" == -1 && "$F_SAME" == -1 && "$F_N" == 1 ]] || fail "redo reference: $(lf_f)"

    # -- both switches come back after Ctrl+S --
    lf_key ctrl+s; wait_for 1.5 "saved"
    LF_SAVED="$LF_DIR/sheet.png"
    LF_TYPES=$(python3 "$LF_PY" types "$LF_SAVED" 2>/dev/null | tr '\n' ' ')
    if [[ "$LF_TYPES" != *drAw* || "$LF_TYPES" != *drAn* ]]; then
        fail "Ctrl+S: sheet.png chunks '$LF_TYPES' (wanted drAw + drAn)"
    else
        draw_quit
        draw_settle
        DRAW_EXTRA_ARGS="$LF_SAVED"
        draw_launch 15
        wait_for 1.5 "Project loaded"
        assert_no_crash
        lf_read
        [[ "$F_REF" == -1 && "$F_SAME" == -1 && "$F_N" == 1 && "$F_FLAT" == "$LF_EMPTY" ]] && lf_all "$LF_D" \
            && pass "reopened $(basename "$LF_SAVED"): still a reference layer, still the same on every frame" || fail "reopened: $(lf_f), cells $(lf_cells)"
    fi
fi
assert_no_crash

# leave a plain DRAW running for the next test
draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LF_DIR"
assert_window_exists
