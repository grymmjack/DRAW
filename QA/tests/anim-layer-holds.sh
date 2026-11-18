#!/bin/bash
# =============================================================================
# anim-layer-holds.sh — QA test: per-layer holds (branch xsheet-holds-lanes,
# TOOLS/ANIM-OPS ANIM_LH_*, TOOLS/ANIM-XS XS_DRAG_LHOLD / ANIM_XS_grip% / the
# cell menu, ANIM > Hold for N Frames... / Release Hold).
#
# A layer's drawing held for N frames is N linked cells in a row. Dragging a
# cell's right end along its X-sheet row stretches the hold: the cells it
# covers take that drawing (one link group). Dragging it back shrinks it: the
# cells let go are blank. Hold for N Frames... types the length, Release Hold
# takes it back to one frame. Each is one undo step.
#
# Dump: ANIMLH s-e ... (the current layer's held runs), ANIMLK entries map,
# ANIMC (each frame cell's CRC, 0 empty), ANIMXS / ANIMXSF / ANIMXSR geometry.
# Fixture: a 96x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour; 6 frames, current 1. One layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: per-layer holds ==="

LH_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
LH_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
LH_DIR="/tmp/draw-qa-holds-$$"
mkdir -p "$LH_DIR"
LH_DRAW=()
LH_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 + 3 + n % 4 ))
    LH_DRAW+=(-fill "#${LH_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 96x16 xc:none "${LH_DRAW[@]}" "PNG32:$LH_DIR/plain.png"
python3 "$LH_PY" put "$LH_DIR/plain.png" "$LH_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

lh_line() { grep -m1 "^$1 " "$LH_DUMP" 2>/dev/null; }
lh_read() { # A_COUNT A_CUR, C[1..], LK_MAP, LH (the runs)
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(lh_line ANIM)"
    C=($(lh_line ANIMC))
    read -r _ _ LK_MAP _ <<< "$(lh_line ANIMLK)"
    LH="$(lh_line ANIMLH | sed 's/^ANIMLH//; s/ _$//; s/^ //')"
}
lh_cells() { echo "${C[*]:1}"; }
lh_s() { echo "holds '${LH}' map '${LK_MAP:-}' frame ${A_CUR:-?}/${A_COUNT:-?} cells $(lh_cells)"; }
lh_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
lh_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
lh_geom() { # the X-sheet: XF (f x w triples), the layer row's middle y
    XF=($(lh_line ANIMXSF))
    read -r _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ XLH _ <<< "$(lh_line ANIMXS)"
    XRY=$(grep -m1 "^ANIMXSR 1 " "$LH_DUMP" | cut -d' ' -f4)
    XYM=$(( XRY + XLH / 2 ))
}
fx() { echo "${XF[$(( 3 * $1 - 1 ))]}"; }   # frame's left x
fw() { echo "${XF[$(( 3 * $1 ))]}"; }       # its span
fend() { echo $(( $(fx "$1") + $(fw "$1") - 2 )); } # just inside its right end (the grip)
fmid() { echo $(( $(fx "$1") + $(fw "$1") / 2 )); }
lh_drag() { # X0 X1: press at X0 on the layer row, drag to X1, release
    mouse_down "$1" "$XYM"; hover $(( ($1 + $2) / 2 )) "$XYM"; sleep 0.15; hover "$2" "$XYM"; sleep 0.3
    mouse_up; wait_for 0.6 "drop"
}

info "Launching DRAW with a 96x16 sheet of 16x16 frames (6, current 1, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$LH_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
lh_key ctrl+0
lh_key KP_8
lh_read
C0=("${C[@]}"); LH_C0="$(lh_cells)"
lh_geom
if [[ "$A_COUNT" != 6 || "$LK_MAP" != "......" || -n "$LH" || -z "$XRY" || -z "$(fx 3)" ]]; then
    fail "start: $(lh_s) X-sheet row y '${XRY}' frames '${XF[*]}' (wanted 6 frames, no links, the X-sheet on)"
else
    pass "a sheet of 6 frames, 6 drawings, no holds; the X-sheet is on"

    # -- drag frame 1's right end to frame 3: held 1-3, frames 2 + 3 show frame 1's drawing --
    snap_region "$(fx 2)" "$XRY" "$(fw 2)" "$XLH" lh-x2a >/dev/null; LH_X2A="$SNAP_RESULT"
    # mid-drag: the hold line it will have runs out to frame 3 and ends in its
    # handle (Rick 2026-11-16: a single cell dragged right drew no line)
    mouse_down "$(fend 1)" "$XYM"; hover "$(fmid 2)" "$XYM"; sleep 0.15; hover "$(fmid 3)" "$XYM"; sleep 0.4
    HX=$(( $(fx 3) + $(fw 3) - 4 ))
    snap_region "$HX" $(( XYM - 2 )) 2 5 lh-handle >/dev/null
    HL=$(magick "$SNAP_RESULT" -colorspace Gray -format '%[fx:int(mean*255)]' info: 2>/dev/null)
    mouse_up; wait_for 0.6 "drop"; lh_read
    [[ "${HL:-0}" -ge 150 ]] && pass "mid-drag: the new hold line's handle drawn at frame 3's end (grey $HL)" || fail "mid-drag: no handle at x $HX y $XYM (grey '${HL:-?}')"
    [[ "$LH" == "1-3" && "$LK_MAP" == "Aaa..." && "${C[2]}" == "${C0[1]}" && "${C[3]}" == "${C0[1]}" && "${C[4]}" == "${C0[4]}" ]] \
        && pass "drag frame 1's end to frame 3: held 1-3 (map $LK_MAP), frames 2 + 3 show frame 1's drawing" || fail "stretch: $(lh_s)"
    snap_region "$(fx 2)" "$XRY" "$(fw 2)" "$XLH" lh-x2b >/dev/null; LH_X2B="$SNAP_RESULT"
    assert_regions_differ "$LH_X2A" "$LH_X2B" "X-sheet: frame 2's cell is now the hold line, not its own drawing"

    # -- one undo step --
    lh_key ctrl+z; lh_read
    [[ -z "$LH" && "$LK_MAP" == "......" && "$(lh_cells)" == "$LH_C0" ]] && pass "undo: no hold, frames 2 + 3's own drawings back" || fail "undo stretch: $(lh_s)"
    lh_key ctrl+y; lh_read
    [[ "$LH" == "1-3" && "${C[3]}" == "${C0[1]}" ]] && pass "redo: held 1-3 again" || fail "redo stretch: $(lh_s)"

    # -- shrink: drag the run's end (frame 3's) back to frame 2: frame 3 goes blank --
    lh_geom
    lh_drag "$(fend 3)" "$(fmid 2)"; lh_read
    [[ "$LH" == "1-2" && "${C[2]}" == "${C0[1]}" && "${C[3]}" == 0 && "${C[4]}" == "${C0[4]}" ]] \
        && pass "drag the end back to frame 2: held 1-2, frame 3 is blank" || fail "shrink: $(lh_s)"
    lh_key ctrl+z; lh_read
    [[ "$LH" == "1-3" && "${C[3]}" == "${C0[1]}" ]] && pass "undo the shrink: held 1-3, frame 3 shows the drawing again" || fail "undo shrink: $(lh_s)"

    # -- a plain click on a cell (no drag) changes nothing --
    lh_geom
    click "$(fmid 5)" "$XYM"; wait_for 0.4 "click"; lh_read
    [[ "$LH" == "1-3" && "$A_CUR" == 5 ]] && pass "a click on frame 5's cell: frame 5 current, the hold untouched" || fail "click: $(lh_s)"

    # -- Hold for N Frames... (3) on frame 5 --
    lh_palette "hold for n frames"
    key ctrl+a; type_text "3"; key Return; wait_for 0.8 "hold dialog"; lh_read
    # (frame 5 is current: its drawing holds 5-6 - the last frame caps it)
    [[ "$LH" == "1-3 5-6" && "${C[6]}" == "${C0[5]}" ]] && pass "Hold for N Frames... (3) on frame 5: held 5-6 (capped at the last frame)" || fail "hold for n: $(lh_s)"

    # -- Release Hold on frame 5: frame 6 blank --
    lh_palette "release hold"; lh_read
    [[ "$LH" == "1-3" && "${C[6]}" == 0 && "${C[5]}" == "${C0[5]}" ]] && pass "Release Hold on frame 5: no hold there, frame 6 blank" || fail "release: $(lh_s)"
    lh_key ctrl+z; lh_read
    [[ "$LH" == "1-3 5-6" ]] && pass "undo Release Hold: held 5-6 again" || fail "undo release: $(lh_s)"

    # -- dragged past the last frame: to the end, not back where it was (Rick 2026-11-16:
    #    "a human who drags passed the last frame wants the length to go to the end") --
    lh_key ctrl+z; lh_read # (the 5-6 hold off: frame 4 is its own drawing again)
    lh_geom
    read -r _ _ _ _ _ XS_X2 _ <<< "$(lh_line ANIMXS)"
    PAST=$(( $(fx 6) + $(fw 6) + 12 ))
    if [[ -z "$XS_X2" || "$PAST" -ge "$XS_X2" ]]; then
        info "no room past frame 6 on the X-sheet (x2 '${XS_X2:-?}', past $PAST) - not checked"
    else
        lh_drag "$(fend 3)" "$PAST"; lh_read
        [[ "$LH" == 1-6 ]] && pass "frame 3's end dragged past the last frame: held 1-6 (to the end)" || fail "past the end: $(lh_s)"
        lh_key ctrl+z; lh_read
        [[ "$LH" == 1-3 ]] && pass "undo: held 1-3 again" || fail "undo past the end: $(lh_s)"
    fi

fi

assert_no_crash
draw_quit
rm -rf "$LH_DIR"
