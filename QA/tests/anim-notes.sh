#!/bin/bash
# =============================================================================
# anim-notes.sh — QA test: frame notes (Animation 4.5, TOOLS/ANIM ANIM_NOTE /
# ANIM_NT_*, TOOLS/ANIM-OPS ANIM_NT_action, the X-sheet's NOTES row).
#
# ANIM > Frame Note... gives the current frame a line of text (one undo step);
# the X-sheet then shows a NOTES row under HOLD: each note from its frame on,
# until the next. A click there makes that frame current, a double-click edits
# its note. Clear Frame Note removes the selected frames' notes. Notes go with
# their frames through frame ops, and are saved (drAn v5).
#
# Dump: ANIMNT n [frame note]... _ (spaces as _), ANIMXSN notesRowY.
# Fixture: a 96x16 sheet of 16x16 frames, frame k a 6x6 square of its own
# colour; 6 frames at 10 fps, current 1. One layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: frame notes ==="

NT_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
NT_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
NT_DIR="$(mktemp -d /tmp/draw-qa-notes-XXXXXX)"
NT_DRAW=()
NT_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 + 3 + n % 4 ))
    NT_DRAW+=(-fill "#${NT_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 96x16 xc:none "${NT_DRAW[@]}" "PNG32:$NT_DIR/plain.png"
python3 "$NT_PY" put "$NT_DIR/plain.png" "$NT_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

nt_line() { grep -m1 "^$1 " "$NT_DUMP" 2>/dev/null; }
nt_read() { # A_COUNT A_CUR, NT_N NT_LIST, XY1 XRH XTW, XF[], NR_Y
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(nt_line ANIM)"
    NT_N=""; NT_LIST=""
    read -r _ NT_N NT_LIST <<< "$(nt_line ANIMNT)"
    NT_LIST="${NT_LIST% _}"; [[ "$NT_LIST" == "_" ]] && NT_LIST=""
    read -r _ _ _ _ XY1 _ _ _ XRH XTW _ <<< "$(nt_line ANIMXS)"
    XF=($(nt_line ANIMXSF))
    NR_Y=""; read -r _ NR_Y _ <<< "$(nt_line ANIMXSN)"
}
nt_s() { echo "notes ${NT_N:-?} '${NT_LIST:-}' frame ${A_CUR:-?}/${A_COUNT:-?} notes row '${NR_Y:-}'"; }
nt_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
nt_xsheet() { local on; read -r _ _ on _ <<< "$(nt_line ANIMXS)"; [[ "$on" == -1 ]] || nt_key KP_8; }
nt_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
nt_box() { [[ -n "$1" ]] && { type_text "$1"; wait_for 0.3 "typed"; }; key Return; wait_for 0.8 "Frame Note box"; }
nt_fx() { echo $(( ${XF[$(( 3 * $1 - 1 ))]:-0} + ${XTW:-0} / 2 )); } # FRAME -> the middle of its first tick
nt_head() { click "$(nt_fx "$1")" $(( ${XY1:-0} + 1 + ${XRH:-0} / 2 )); wait_for 0.4 "header $1"; }
nt_row_click() { click "$(nt_fx "$1")" $(( NR_Y + XRH / 2 )); wait_for 0.5 "notes row $1"; }
nt_row_dbl() { double_click "$(nt_fx "$1")" $(( NR_Y + XRH / 2 )); wait_for 2.0 "notes row double-click $1"; }

info "Launching DRAW with a 96x16 sheet of 16x16 frames (6, current 1, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$NT_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
nt_key ctrl+0
nt_read; nt_xsheet; nt_read
if [[ "$A_COUNT" != 6 || "${NT_N:-}" != 0 || -n "${NR_Y:-}" || "${XTW:-0}" -lt 1 ]]; then
    fail "start: $(nt_s), x-sheet tick '${XTW:-}' (wanted 6 frames, no notes, no NOTES row)"
else
    pass "6 frames on the X-sheet, no notes, no NOTES row"

    # -- Frame Note... on frame 3; one undo step --
    nt_head 3; nt_palette "frame note"; nt_box "foot down"; nt_read
    [[ "$NT_N" == 1 && "$NT_LIST" == "3 foot_down" && -n "$NR_Y" ]] && pass "frame 3, Frame Note 'foot down': noted, the NOTES row shows" || fail "frame note: $(nt_s)"
    if [[ -n "$NR_Y" ]]; then
        NT_AT=$(snap_region $(( XF[8] + 3 )) $(( NR_Y + 2 )) 12 $(( XRH - 4 )) nt-at >/dev/null; echo "$SNAP_RESULT")
        NT_BEFORE=$(snap_region $(( XF[5] + 3 )) $(( NR_Y + 2 )) 12 $(( XRH - 4 )) nt-before >/dev/null; echo "$SNAP_RESULT")
        assert_regions_differ "$NT_AT" "$NT_BEFORE" "the NOTES row writes the note at frame 3, nothing at frame 2"
    fi
    nt_key ctrl+z; nt_read
    [[ "$NT_N" == 0 && -z "$NR_Y" ]] && pass "undo: no notes, no NOTES row" || fail "undo note: $(nt_s)"
    nt_key ctrl+y; nt_read
    [[ "$NT_LIST" == "3 foot_down" ]] && pass "redo: the note is back" || fail "redo note: $(nt_s)"

    # -- the NOTES row: a double-click edits a frame's note, a click picks the frame --
    nt_row_dbl 5; nt_box "ka-"; nt_read
    [[ "$NT_N" == 2 && "$NT_LIST" == "3 foot_down 5 ka-" ]] && pass "a double-click on the NOTES row at frame 5, 'ka-': noted" || fail "double-click note: $(nt_s)"
    nt_row_click 3; nt_read
    [[ "$A_CUR" == 3 && "$NT_N" == 2 ]] && pass "a click on the NOTES row at frame 3: frame 3 current, no box" || fail "notes row click: $(nt_s)"
    sleep 0.6
    nt_row_dbl 3; nt_box "heel"; nt_read
    [[ "$NT_LIST" == "3 heel 5 ka-" ]] && pass "a double-click on frame 3's note: the box has it, 'heel' replaces it" || fail "edit a note: $(nt_s)"

    # -- frame ops carry them --
    nt_head 1; nt_palette "delete frame"; nt_read
    [[ "$A_COUNT" == 5 && "$NT_LIST" == "2 heel 4 ka-" ]] && pass "delete frame 1: the notes move up with their frames" || fail "delete frame 1: $(nt_s)"
    nt_key ctrl+z; nt_read
    [[ "$A_COUNT" == 6 && "$NT_LIST" == "3 heel 5 ka-" ]] && pass "undo: back where they were" || fail "undo delete: $(nt_s)"

    # -- Clear Frame Note --
    nt_head 5; nt_palette "clear frame note"; nt_read
    [[ "$NT_N" == 1 && "$NT_LIST" == "3 heel" ]] && pass "frame 5, Clear Frame Note: only frame 3's left" || fail "clear note: $(nt_s)"
    nt_key ctrl+z; nt_read
    [[ "$NT_N" == 2 ]] && pass "undo: frame 5's note back" || fail "undo clear: $(nt_s)"

    # -- saved and back --
    nt_key ctrl+s; wait_for 1.5 "saved"
    NT_V=$(python3 "$NT_PY" get "$NT_DIR/sheet.png" drAn 2>/dev/null | cut -c1-4)
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$NT_DIR/sheet.png"
    draw_launch 15
    wait_for 1.5 "Saved sheet loaded"
    assert_no_crash
    nt_read; nt_xsheet; nt_read
    [[ "$NT_V" == 0500 && "$NT_LIST" == "3 heel 5 ka-" && -n "$NR_Y" ]] && pass "Ctrl+S, reopen: drAn v5, both notes back on the NOTES row" || fail "reopen: drAn '$NT_V', $(nt_s)"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$NT_DIR"
assert_window_exists
