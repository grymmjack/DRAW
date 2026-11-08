#!/bin/bash
# =============================================================================
# anim-links.sh — QA test: linked cells (Animation 4.3, TOOLS/ANIM ANIM_LK_*,
# TOOLS/ANIM-OPS ANIM_LK_tick% / ANIM_LK_action, ANIM > Link Cells / Unlink
# Cells, the X-sheet's Shift+drop).
#
# A layer's cells in two or more frames show one drawing: Link Cells on one
# frame links it to the frame before (its pixels become that drawing);
# painting either cell paints both, its undo / redo too; linked cells (not
# the source) are hatched in sheet view; Shift at an X-sheet drop links; links
# follow their frames through frame ops (a group left with one cell goes);
# Unlink keeps the pixels; links are saved (drAn v3) and come back.
#
# Dump: ANIMLK entries map (the current layer per frame: "." none, a letter
# per group, upper case its source), ANIMC (each frame cell's CRC, 0 empty).
# Fixture: a 64x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour at (3 + k - 1, 4); 4 frames, current 2. One layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: linked cells ==="

LK_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LK_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LK_DIR="/tmp/draw-qa-links-$$"
mkdir -p "$LK_DIR"
LK_DRAW=()
LK_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 3 + n ))
    LK_DRAW+=(-fill "#${LK_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 64x16 xc:none "${LK_DRAW[@]}" "PNG32:$LK_DIR/plain.png"
python3 "$LK_PY" put "$LK_DIR/plain.png" "$LK_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,4,2,10,0,0).hex())")"

lk_line() { grep -m1 "^$1 " "$LK_DUMP" 2>/dev/null; }
lk_read() { # A_COUNT A_CUR, C[1..], LK_N LK_MAP, the current pane PX PY PW
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(lk_line ANIM)"
    C=($(lk_line ANIMC))
    read -r _ LK_N LK_MAP _ <<< "$(lk_line ANIMLK)"
    local p k; p=($(lk_line ANIMLBP)); PX=""; PY=""; PW=""
    for (( k = 3; k + 4 < ${#p[@]}; k += 5 )); do [[ "${p[$k]}" == "$A_CUR" ]] && { PX=${p[$((k + 1))]}; PY=${p[$((k + 2))]}; PW=${p[$((k + 3))]}; }; done
}
lk_cells() { echo "${C[*]:1}"; }
lk_s() { echo "links ${LK_N:-?} map '${LK_MAP:-}' frame ${A_CUR:-?}/${A_COUNT:-?} cells $(lk_cells)"; }
lk_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
lk_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
lk_dot() { click $(( PX + (2 * $1 + 1) * PW / 32 )) $(( PY + (2 * $2 + 1) * PW / 32 )); wait_for 0.6 "brush dot"; } # CX CY in the current pane
lk_sheet_cell() { # FRAME -> the screen region inside that sheet cell, away from the drawings and the number (5x5 at cell px 9..13)
    local dx dy z
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ dx dy _ <<< "$(lk_line ANIM)"
    read -r _ z _ <<< "$(lk_line VIEW)"
    LK_RX=$(( dx + ((${1} - 1) * 16 + 9) * z / 100 )); LK_RY=$(( dy + 9 * z / 100 )); LK_RS=$(( 5 * z / 100 ))
}
lk_snap() { lk_sheet_cell "$1"; snap_region "$LK_RX" "$LK_RY" "$LK_RS" "$LK_RS" "$2" >/dev/null; echo "$SNAP_RESULT"; }
lk_same() { [[ "$(magick compare -metric AE "$1" "$2" null: 2>&1 | awk '{print $1}')" == 0 ]]; }

info "Launching DRAW with a 64x16 sheet of 16x16 frames (4, current 2, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LK_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
lk_key ctrl+0
lk_read
C0=("${C[@]}"); LK_C0="$(lk_cells)"
if [[ "$A_COUNT" != 4 || "$A_CUR" != 2 || "$LK_MAP" != "...." ]]; then
    fail "start: $(lk_s) (wanted 4 frames, current 2, no links)"
else
    pass "a sheet of 4 frames, 4 drawings, no links"
    LK_R2A=$(lk_snap 2 lk-r2a); LK_R3A=$(lk_snap 3 lk-r3a)

    # -- Link Cells on frame 2: linked to frame 1, its drawing now; hatched; one undo step --
    lk_palette "link cells"; lk_read
    [[ "$LK_MAP" == "Aa.." && "${C[2]}" == "${C0[1]}" && "${C[1]}" == "${C0[1]}" && "${C[3]}" == "${C0[3]}" ]] \
        && pass "Link Cells on frame 2: linked to frame 1 (map $LK_MAP), frame 2 shows frame 1's drawing" || fail "link: $(lk_s)"
    LK_R2B=$(lk_snap 2 lk-r2b); LK_R3B=$(lk_snap 3 lk-r3b)
    ! lk_same "$LK_R2A" "$LK_R2B" && lk_same "$LK_R3A" "$LK_R3B" && pass "sheet view: frame 2's cell is hatched, frame 3's is not" || fail "hatching: frame 2 region same '$(lk_same "$LK_R2A" "$LK_R2B" && echo yes)', frame 3 changed '$(lk_same "$LK_R3A" "$LK_R3B" || echo yes)'"
    lk_key ctrl+z; lk_read
    [[ "$LK_MAP" == "...." && "$(lk_cells)" == "$LK_C0" ]] && pass "undo: unlinked, frame 2's own drawing back" || fail "undo link: $(lk_s)"
    lk_key ctrl+y; lk_read
    [[ "$LK_MAP" == "Aa.." && "${C[2]}" == "${C0[1]}" ]] && pass "redo: linked again" || fail "redo link: $(lk_s)"

    # -- painting the link paints the source, and back --
    lk_key KP_0; key b; wait_for 0.3 "Brush"; lk_read
    lk_dot 1 13; lk_read
    LK_D1="${C[1]}"
    [[ "${C[1]}" == "${C[2]}" && "${C[1]}" != "${C0[1]}" && "$LK_MAP" == "Aa.." ]] && pass "a dot in frame 2 (the link): frame 1 has it too" || fail "paint the link: $(lk_s)"
    lk_key ctrl+z; lk_read
    [[ "${C[1]}" == "${C0[1]}" && "${C[2]}" == "${C0[1]}" ]] && pass "undo the dot: gone from both" || fail "undo the dot: $(lk_s)"
    lk_key ctrl+y; lk_read
    [[ "${C[1]}" == "$LK_D1" && "${C[2]}" == "$LK_D1" ]] && pass "redo: on both again" || fail "redo the dot: $(lk_s)"
    lk_key KP_1; lk_read
    lk_dot 14 1; lk_read
    [[ "${C[1]}" == "${C[2]}" && "${C[1]}" != "$LK_D1" ]] && pass "a dot in frame 1 (the source): frame 2 has it too" || fail "paint the source: $(lk_s)"
    LK_D2="${C[1]}"

    # -- the X-sheet: Shift at the drop links --
    lk_key KP_8
    read -r _ _ _ _ XY1 _ _ _ XRH XTW _ _ _ _ _ _ _ _ <<< "$(lk_line ANIMXS)"
    XF=($(lk_line ANIMXSF)); XRY=$(grep -m1 "^ANIMXSR 1 " "$LK_DUMP" | cut -d' ' -f4)
    X3=$(( XF[8] + XTW / 2 )); X4=$(( XF[11] + XTW / 2 )); XYM=$(( XRY + XRH / 2 ))
    mouse_down "$X3" "$XYM"; hover $(( (X3 + X4) / 2 )) "$XYM"; sleep 0.15; hover "$X4" "$XYM"; sleep 0.3
    with_mods shift mouse_up; wait_for 0.6 "drop"; lk_read
    [[ "$LK_MAP" == "AaBb" && "${C[4]}" == "${C0[3]}" && "$A_CUR" == 4 ]] && pass "X-sheet: frame 3's cell Shift+dropped on frame 4: linked (map $LK_MAP), frame 4 shows it" || fail "shift drop: $(lk_s)"

    # -- frame ops carry links; a group left with one cell goes --
    lk_key KP_1; lk_palette "delete frame"; lk_read
    [[ "$A_COUNT" == 3 && "$LK_MAP" == ".Aa" && "${C[2]}" == "${C[3]}" ]] && pass "delete frame 1: frame 2's link went with it, 3 + 4 (now 2 + 3) still linked (map $LK_MAP)" || fail "delete: $(lk_s)"
    lk_key ctrl+z; lk_read
    [[ "$A_COUNT" == 4 && "$LK_MAP" == "AaBb" ]] && pass "undo: 4 frames, both links back" || fail "undo delete: $(lk_s)"

    # -- Unlink keeps the pixels --
    lk_key KP_1; lk_key KP_5; lk_palette "unlink cells"; lk_read
    [[ "$LK_MAP" == "..Aa" && "${C[2]}" == "$LK_D2" ]] && pass "Unlink Cells on frame 2: unlinked (map $LK_MAP), its pixels kept" || fail "unlink: $(lk_s)"
    lk_key ctrl+z; lk_read
    [[ "$LK_MAP" == "AaBb" ]] || fail "undo unlink: $(lk_s)"

    # -- saved and back --
    lk_key KP_8; lk_key KP_0
    lk_key ctrl+s; wait_for 1.5 "saved"
    LK_V=$(python3 "$LK_PY" get "$LK_DIR/sheet.png" drAn 2>/dev/null | cut -c1-4)
    LK_SAVED_C="$(lk_cells)"
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$LK_DIR/sheet.png"
    draw_launch 15
    wait_for 1.5 "Saved sheet loaded"
    assert_no_crash
    lk_read
    [[ "$LK_V" == 0300 && "$LK_MAP" == "AaBb" && "$(lk_cells)" == "$LK_SAVED_C" ]] && pass "Ctrl+S, reopen: drAn v3, the links back (map $LK_MAP)" || fail "reopen: drAn '$LK_V', $(lk_s)"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$LK_DIR"
assert_window_exists
