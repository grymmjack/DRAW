#!/bin/bash
# =============================================================================
# anim-tags.sh — QA test: named tags / frame ranges (Animation 4.4, TOOLS/ANIM
# ANIM_TG_*, TOOLS/ANIM-OPS ANIM_TG_action, the X-sheet's TAGS row, exports +
# the batch CLI's --tag).
#
# ANIM > Tag Frames... names the selected frames (the box starts "tagN"; with
# a tag selected, its name: a new one renames it); one undo step. The X-sheet
# shows a TAGS row under HOLD; a click on a tag selects its frames, so Play
# plays just them. Frame ops carry tags along. Tags are saved (drAn v4) and
# come back. --tag NAME --export-anim writes just that tag's frames; the
# sprite sheet's JSON / .bi list every tag; an unknown tag fails the run.
# ANIM > Delete Tag removes the selected one.
#
# Dump: ANIMTG n selected [name from to]... _ , ANIMXST tagsRowY [k xa xb]...
# Fixture: a 96x16 sheet of 16x16 frames, frame k a 6x6 square of its own
# colour; 6 frames at 10 fps, current 1. One layer.
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt ONION_SKIN=0
# =============================================================================
info "=== Animation: named tags ==="

TG_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
TG_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
TG_DIR="$(mktemp -d /tmp/draw-qa-tags-XXXXXX)"
mkdir -p "$TG_DIR/home" "$TG_DIR/o"
TG_DRAW=()
TG_COLORS=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0)
for n in 0 1 2 3 4 5; do
    x=$(( n * 16 + 3 + n % 4 ))
    TG_DRAW+=(-fill "#${TG_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 96x16 xc:none "${TG_DRAW[@]}" "PNG32:$TG_DIR/plain.png"
magick "PNG32:$TG_DIR/plain.png" -crop 16x16+16+0 +repage "PNG32:$TG_DIR/frame2.png"
python3 "$TG_PY" put "$TG_DIR/plain.png" "$TG_DIR/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<10h',1,16,16,0,0,6,1,10,0,0).hex())")"

tg_line() { grep -m1 "^$1 " "$TG_DUMP" 2>/dev/null; }
tg_read() { # A_COUNT A_CUR A_PLAY, TG_N TG_SEL TG_LIST, XY1 XRH, XF[], TR_Y TR[]
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ _ A_COUNT A_CUR _ _ _ _ _ _ _ _ _ _ _ _ _ A_PLAY _ <<< "$(tg_line ANIM)"
    TG_N=""; TG_SEL=""; TG_LIST=""
    read -r _ TG_N TG_SEL TG_LIST <<< "$(tg_line ANIMTG)"
    TG_LIST="${TG_LIST% _}"; [[ "$TG_LIST" == "_" ]] && TG_LIST=""
    read -r _ _ _ _ XY1 _ _ _ XRH XTW _ <<< "$(tg_line ANIMXS)"
    XF=($(tg_line ANIMXSF))
    TR=($(tg_line ANIMXST)); TR_Y="${TR[1]:-}"
}
tg_s() { echo "tags ${TG_N:-?} sel ${TG_SEL:-?} '${TG_LIST:-}' frame ${A_CUR:-?}/${A_COUNT:-?} playing ${A_PLAY:-?} tags row '${TR[*]:-}'"; }
tg_key() { park_mouse; key "$1"; wait_for 0.6 "$1"; }
tg_xsheet() { # the X-sheet on (Num 8 unless it already is: the setting is kept)
    local on; read -r _ _ on _ <<< "$(tg_line ANIMXS)"
    [[ "$on" == -1 ]] || tg_key KP_8
}
tg_palette() {
    park_mouse; key question; wait_for 1.0 "Command palette"
    type_text "$1"; wait_for 0.4 "Filtered"; key Return; wait_for 1.0 "$1"
}
tg_box() { # TEXT (empty = keep the default): answer the Tag Frames box
    [[ -n "$1" ]] && { type_text "$1"; wait_for 0.3 "typed"; }
    key Return; wait_for 0.8 "Tag Frames box"
}
tg_hx() { echo $(( ${XF[$(( 3 * $1 - 1 ))]:-0} + ${XTW:-0} / 2 )); } # FRAME -> x of its header number
tg_hy() { echo $(( ${XY1:-0} + 1 + ${XRH:-0} / 2 )); }
tg_head() { click "$(tg_hx "$1")" "$(tg_hy)"; wait_for 0.4 "header $1"; } # FRAME
tg_tag_click() { # K -> click the middle of tag K's bar on the TAGS row
    local i
    for (( i = 2; i + 2 < ${#TR[@]}; i += 3 )); do
        [[ "${TR[$i]}" == "$1" ]] && { click $(( (TR[i + 1] + TR[i + 2]) / 2 )) $(( TR_Y + XRH / 2 )); wait_for 0.4 "tag $1"; return 0; }
    done
    return 1
}
tg_cur_now() { read -r _ _ _ c _ <<< "$(tg_line ANIM)"; echo "$c"; }
tg_batch() { # IN ARGS... -> TG_RC, TG_OUT (stdout); a throwaway HOME
    local in=$1; shift
    TG_OUT=$( cd "$DRAW_ROOT" && HOME="$TG_DIR/home" XDG_CONFIG_HOME="$TG_DIR/home/.config" XDG_DATA_HOME="$TG_DIR/home/.local/share" \
      XDG_CACHE_HOME="$TG_DIR/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$in" "$@" </dev/null 2>>"$TG_DIR/err.txt" )
    TG_RC=$?
}

info "Launching DRAW with a 96x16 sheet of 16x16 frames (6, current 1, one layer)"
draw_quit
draw_settle
DRAW_EXTRA_ARGS="$TG_DIR/sheet.png"
draw_launch 15
wait_for 1.5 "Sheet loaded"
assert_no_crash
tg_key ctrl+0
tg_read; tg_xsheet
tg_read
if [[ "$A_COUNT" != 6 || "${TG_N:-}" != 0 || -z "${TR_Y:-}" || "${XTW:-0}" -lt 1 ]]; then
    fail "start: $(tg_s), x-sheet tick '${XTW:-}' (wanted 6 frames, no tags, the TAGS row there anyway - R-13)"
else
    pass "6 frames on the X-sheet, no tags, the TAGS row there (R-13: always shown)"

    # -- Tag Frames on 2-4: "walk"; one undo step --
    tg_head 2; with_mods shift click "$(tg_hx 4)" "$(tg_hy)"; wait_for 0.4 "shift+click 4"
    tg_palette "tag frames"; tg_box walk; tg_read
    [[ "$TG_N" == 1 && "$TG_SEL" == 1 && "$TG_LIST" == "walk 2 4" ]] && pass "frames 2-4 selected, Tag Frames 'walk': tag walk 2-4, selected" || fail "tag walk: $(tg_s)"
    if [[ -n "$TR_Y" && "${TR[2]:-}" == 1 ]]; then
        TG_BAR=$(snap_region $(( TR[3] + 3 )) $(( TR_Y + XRH / 2 - 1 )) 4 3 tg-bar >/dev/null; echo "$SNAP_RESULT")
        TG_NOBAR=$(snap_region $(( XF[17] + 3 )) $(( TR_Y + XRH / 2 - 1 )) 4 3 tg-nobar >/dev/null; echo "$SNAP_RESULT")
        assert_regions_differ "$TG_BAR" "$TG_NOBAR" "the TAGS row draws walk's bar over frames 2-4, not over frame 6"
    else
        fail "no TAGS row with tag 1 in it: '${TR[*]:-}'"
    fi
    tg_key ctrl+z; tg_read
    [[ "$TG_N" == 0 && "${#TR[@]}" -le 2 ]] && pass "undo: no tags, an empty TAGS row" || fail "undo tag: $(tg_s)"
    tg_key ctrl+y; tg_read
    [[ "$TG_LIST" == "walk 2 4" ]] && pass "redo: walk 2-4 again" || fail "redo tag: $(tg_s)"

    # -- a click on the tag selects its frames; Play plays just them --
    tg_head 6; tg_read
    [[ "$TG_SEL" == 0 && "$A_CUR" == 6 ]] || fail "click frame 6: $(tg_s)"
    tg_tag_click 1; tg_read
    [[ "$TG_SEL" == 1 && "$A_CUR" == 2 ]] && pass "a click on walk's bar: its frames selected, frame 2 current" || fail "click the tag: $(tg_s)"
    park_mouse; key KP_Enter; sleep 0.3
    TG_SEEN=""
    for i in 1 2 3 4 5 6 7 8 9 10; do TG_SEEN+="$(tg_cur_now) "; sleep 0.13; done
    key KP_Enter; wait_for 0.5 "stop"
    TG_OUT_RANGE=$(tr ' ' '\n' <<< "$TG_SEEN" | grep -v '^$' | grep -cvx '[234]')
    TG_DISTINCT=$(tr ' ' '\n' <<< "$TG_SEEN" | grep -v '^$' | sort -u | wc -l)
    [[ "$TG_OUT_RANGE" == 0 && "$TG_DISTINCT" -ge 2 ]] && pass "Play: steps through 2-4 only (frames $TG_SEEN)" || fail "play the tag: frames $TG_SEEN"

    # -- frame ops carry it --
    tg_key KP_1; tg_palette "delete frame"; tg_read
    [[ "$A_COUNT" == 5 && "$TG_LIST" == "walk 1 3" ]] && pass "delete frame 1: walk is 1-3" || fail "delete frame 1: $(tg_s)"
    tg_key ctrl+z; tg_read
    [[ "$A_COUNT" == 6 && "$TG_LIST" == "walk 2 4" ]] && pass "undo: 6 frames, walk 2-4" || fail "undo delete: $(tg_s)"

    # -- rename it; a second tag takes the default name --
    tg_tag_click 1; tg_palette "tag frames"; tg_box run; tg_read
    [[ "$TG_N" == 1 && "$TG_LIST" == "run 2 4" ]] && pass "walk selected, Tag Frames 'run': renamed" || fail "rename: $(tg_s)"
    tg_head 5; with_mods shift click "$(tg_hx 6)" "$(tg_hy)"; wait_for 0.4 "shift+click 6"
    tg_palette "tag frames"; tg_box ""; tg_read
    [[ "$TG_N" == 2 && "$TG_LIST" == "run 2 4 tag2 5 6" && "$TG_SEL" == 2 ]] && pass "frames 5-6, Enter in the box: tag2 5-6" || fail "default name: $(tg_s)"

    # -- saved and back --
    tg_key ctrl+s; wait_for 1.5 "saved"
    TG_V=$(python3 "$TG_PY" get "$TG_DIR/sheet.png" drAn 2>/dev/null | cut -c1-4)
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$TG_DIR/sheet.png"
    draw_launch 15
    wait_for 1.5 "Saved sheet loaded"
    assert_no_crash
    tg_read; tg_xsheet; tg_read
    [[ "$TG_V" == 0400 && "$TG_N" == 2 && "$TG_LIST" == "run 2 4 tag2 5 6" ]] && pass "Ctrl+S, reopen: drAn v4, both tags back" || fail "reopen: drAn '$TG_V', $(tg_s)"

    # -- the batch CLI: --tag --
    tg_batch "$TG_DIR/sheet.png" --tag run --export-anim "$TG_DIR/o/r.png" --export-anim "$TG_DIR/o/r.apng"
    [[ "$TG_RC" == 0 && -s "$TG_DIR/o/r_0003.png" && ! -e "$TG_DIR/o/r_0004.png" ]] && grep -q "^wrote $TG_DIR/o/r.png .*tag run" <<< "$TG_OUT" \
        && pass "--tag run --export-anim r.png: 3 PNGs (frames 2-4), the line says 'tag run'" || fail "--tag run: exit $TG_RC, '$(ls "$TG_DIR/o" | tr '\n' ' ')', '$(tr '\n' '|' <<< "$TG_OUT")'"
    TG_AE=$(magick compare -metric AE "$TG_DIR/o/r_0001.png" "$TG_DIR/frame2.png" null: 2>&1 | awk '{print $1}')
    [[ "$TG_AE" == 0 ]] && pass "r_0001.png is frame 2, exact pixels" || fail "r_0001.png vs frame 2: '$TG_AE' pixels differ"
    TG_FRAMES=$(python3 -c "
import sys,struct
d=open(sys.argv[1],'rb').read(); p=8; n=0
while p<len(d):
    l,t=struct.unpack('>I4s',d[p:p+8])
    if t==b'acTL': n=struct.unpack('>I',d[p+8:p+12])[0]
    p+=12+l
print(n)" "$TG_DIR/o/r.apng" 2>/dev/null)
    [[ "$TG_FRAMES" == 3 ]] && pass "r.apng: 3 frames" || fail "r.apng frames '$TG_FRAMES'"
    tg_batch "$TG_DIR/sheet.png" --export-anim "$TG_DIR/o/a.png" --export-anim "$TG_DIR/o/s.json"
    [[ "$TG_RC" == 0 && -s "$TG_DIR/o/a_0006.png" ]] && grep -q '"name": "run", "from": 1, "to": 3' "$TG_DIR/o/s.json" && grep -q '"name": "tag2", "from": 4, "to": 5' "$TG_DIR/o/s.json" \
        && grep -q "^CONST S_TAG_RUN_FROM = 2" "$TG_DIR/o/s.bi" && grep -q "^CONST S_TAG_TAG2_TO = 6" "$TG_DIR/o/s.bi" \
        && pass "no --tag: all 6 frames; the sheet's JSON frameTags + .bi CONSTs list both tags" || fail "no --tag / sheet tags: exit $TG_RC, json '$(grep -o '"frameTags".*' "$TG_DIR/o/s.json" 2>/dev/null | head -c 300)', bi '$(grep TAG "$TG_DIR/o/s.bi" 2>/dev/null | tr '\n' '|')'"
    tg_batch "$TG_DIR/sheet.png" --tag nope --export-anim "$TG_DIR/o/n.png"
    [[ "$TG_RC" == 1 && ! -e "$TG_DIR/o/n_0001.png" ]] && grep -q "no such tag (the document has: run, tag2)" <<< "$TG_OUT" \
        && pass "--tag nope: exit 1, nothing written, the tags listed" || fail "--tag nope: exit $TG_RC, '$(tr '\n' '|' <<< "$TG_OUT")'"

    # -- Delete Tag --
    tg_tag_click 2; tg_palette "delete tag"; tg_read
    [[ "$TG_N" == 1 && "$TG_LIST" == "run 2 4" ]] && pass "tag2 selected, Delete Tag: only run left" || fail "delete tag: $(tg_s)"
    tg_key ctrl+z; tg_read
    [[ "$TG_N" == 2 ]] && pass "undo: tag2 back" || fail "undo delete tag: $(tg_s)"
fi
assert_no_crash

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$TG_DIR"
assert_window_exists
