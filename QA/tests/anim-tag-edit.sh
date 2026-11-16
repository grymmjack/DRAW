#!/bin/bash
# =============================================================================
# anim-tag-edit.sh — QA test: editing tags on the X-sheet (field kit R-13,
# 2026-11-09: "double click to edit the tag doesn't [work]. Also TAGS row in
# X-SHEET should be always there. ... edit an existing frame tag to delete it
# by backspacing it all out ... and it didn't delete it.").
#
# The TAGS row is shown with no tags (ANIMXST in the dump). A double-click on
# it over a frame with no tag tags that frame (the Tag Frames box); a
# double-click on a tag opens the box with its name (rename); clearing the name
# and pressing OK deletes the tag (Cancel still changes nothing). Undo brings
# the tag back.
#
# Dump: ANIMTG n selected [name from to]... _; ANIMXS / ANIMXSF / ANIMXST.
# Fixture: 6 frames of 16x16 at 10 fps, one layer, no tags.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: editing tags on the X-sheet ==="

TE_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
TE_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
TE_DIR="$(mktemp -d /tmp/draw-qa-tagedit-XXXXXX)"
TE_DRAW=()
for n in 0 1 2 3 4 5; do x=$(( n * 16 + 4 )); TE_DRAW+=(-fill '#c04040' -draw "rectangle $x,4 $(( x + 5 )),9"); done
magick -size 96x16 xc:none "${TE_DRAW[@]}" "PNG32:$TE_DIR/plain.png"
python3 "$TE_PY" put "$TE_DIR/plain.png" "$TE_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

te_line() { grep -m1 "^$1 " "$TE_DUMP" 2>/dev/null; }
te_read() {
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ <<< "$(te_line ANIM)"
    TG_N=""; TG_LIST=""
    read -r _ TG_N _ TG_LIST <<< "$(te_line ANIMTG)"
    TG_LIST="${TG_LIST% _}"; [[ "$TG_LIST" == "_" ]] && TG_LIST=""
    read -r _ _ XS_ON _ XY1 _ _ _ XRH XTW _ <<< "$(te_line ANIMXS)"
    XF=($(te_line ANIMXSF))
    TR_Y=""; read -r _ TR_Y _ <<< "$(te_line ANIMXST)"
}
te_s() { echo "tags ${TG_N:-?} '${TG_LIST:-}' frame ${A_CUR:-?}/${A_COUNT:-?} tags row '${TR_Y:-}'"; }
te_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
te_fx() { echo $(( ${XF[$(( 3 * $1 - 1 ))]:-0} + ${XTW:-0} / 2 )); }
te_dbl() { double_click "$(te_fx "$1")" $(( TR_Y + XRH / 2 )); wait_for 2.0 "tags row double-click $1"; }

draw_quit
draw_settle
DRAW_EXTRA_ARGS="$TE_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
park_mouse; key b; wait_for 0.3 "Brush"
te_read
[[ "${XS_ON:-}" == -1 ]] || { te_key KP_8; te_read; }
[[ "${XS_ON:-}" == -1 ]] || { te_key KP_0; te_read; [[ "${XS_ON:-}" == -1 ]] || { te_key KP_8; te_read; }; }
if [[ -z "${TR_Y:-}" || "${TG_N:-}" != 0 ]]; then
    fail "the TAGS row with no tags: $(te_s) (the old build hid the row until a tag existed)"
else
    pass "the TAGS row is there with no tags (y $TR_Y)"
    # -- double-click on an empty spot: tag that frame --
    te_dbl 3; type_text "walk"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "Tag Frames box"; te_read
    [[ "$TG_N" == 1 && "$TG_LIST" == "walk 3 3" ]] && pass "a double-click on the TAGS row at frame 3, 'walk': frame 3 tagged" || fail "double-click to tag: $(te_s)"
    # -- double-click on the tag: rename --
    te_dbl 3; type_text "run"; wait_for 0.3 "typed"; key Return; wait_for 0.8 "Tag Frames box"; te_read
    [[ "$TG_N" == 1 && "$TG_LIST" == "run 3 3" ]] && pass "a double-click on the tag: renamed to 'run'" || fail "double-click to rename: $(te_s)"
    # -- clear the name, OK: deleted --
    te_dbl 3; key BackSpace; wait_for 0.3 "cleared"; key Return; wait_for 0.8 "Tag Frames box"; te_read
    [[ "$TG_N" == 0 ]] && pass "the name cleared and OK: the tag is deleted" || fail "cleared name: $(te_s), wanted no tags"
    te_key ctrl+z; te_read
    [[ "$TG_N" == 1 && "$TG_LIST" == "run 3 3" ]] && pass "Ctrl+Z: the tag is back" || fail "undo the delete: $(te_s)"
fi
screenshot "anim-tag-edit"
assert_no_crash
rm -rf "$TE_DIR"
