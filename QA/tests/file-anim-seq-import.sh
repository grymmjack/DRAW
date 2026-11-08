#!/bin/bash
# =============================================================================
# file-anim-seq-import.sh — QA test: a numbered PNG sequence opens as frames
# (Animation 5.4, TOOLS/ANIM-IMPORT ANIM_SEQ_import%; DRAW --sequence FILE and
# ANIM > Import PNG Sequence...).
#
# Any one file of the sequence brings in all the files beside it that differ
# only in the number, in number order (padded f_0001 or not walk1 .. walk10),
# as a new untitled document; a file the same as the one before it is one
# more tick of that frame's hold, so DRAW's own PNG sequence export comes back
# as it was. A smaller file sits at its cell's top left. A name without a
# number, or a numbered file alone, opens as a plain picture.
#
# Read back: the dump (ANIM) and the batch CLI's --export-anim PNG sequence
# (one PNG per tick) compared pixel for pixel with the files. The menu
# command's file dialog is not driven here (the same import runs).
#
# QA-OPTIONS: WORKSPACE=default DOCK_DUMP=QA/.dock-dump.txt
# =============================================================================
info "=== Animation: PNG sequence import ==="

SQ_DUMP="$DRAW_ROOT/QA/.dock-dump.txt"
SQ_T="$(mktemp -d /tmp/draw-qa-seqimp-XXXXXX)"
mkdir -p "$SQ_T/home" "$SQ_T/o" "$SQ_T/a" "$SQ_T/b" "$SQ_T/c" "$SQ_T/x"
SQ_COL=(c04040 40c040 4040c0 c0c040 c040c0 40c0c0 808080 f08000 0080f0 80f000)
# a: f_0001 .. f_0005, 12x10; f_0003 repeats f_0002 (a hold); neighbours that are not frames
for n in 1 2 4 5; do
    magick -size 12x10 xc:none -fill "#${SQ_COL[$n]}" -draw "rectangle $n,2 $(( n + 4 )),7" "PNG32:$SQ_T/a/f_000$n.png"
done
cp "$SQ_T/a/f_0002.png" "$SQ_T/a/f_0003.png"
cp "$SQ_T/a/f_0005.png" "$SQ_T/a/f_0001_mask.png"; cp "$SQ_T/a/f_0005.png" "$SQ_T/a/g_0002.png"; echo notes > "$SQ_T/a/f_notes.txt"
# b: walk1 .. walk10 (no padding: 10 comes after 9); walk7 is 8x8
for n in 1 2 3 4 5 6 7 8 9 10; do
    if [[ $n == 7 ]]; then sz=8x8; else sz=12x10; fi
    magick -size $sz xc:none -fill "#${SQ_COL[$(( n - 1 ))]}" -draw "rectangle 0,0 $(( n % 6 + 1 )),$(( n % 5 + 1 ))" "PNG32:$SQ_T/b/walk$n.png"
done
magick "$SQ_T/b/walk7.png" -background none -extent 12x10 "PNG32:$SQ_T/x/walk7-in-cell.png"
# c: no number; a numbered file alone
cp "$SQ_T/a/f_0001.png" "$SQ_T/c/plain.png"; cp "$SQ_T/a/f_0002.png" "$SQ_T/c/solo_01.png"

sq_line() { grep -m1 "^$1 " "$SQ_DUMP" 2>/dev/null; }
sq_read() { # A_ACT A_COUNT A_CUR A_FW A_FH
    { hover 300 250; wait_for 0.15 "render"; hover 305 252; wait_for 0.25 "render"; } >&2
    read -r _ A_ACT A_COUNT A_CUR A_FW A_FH _ <<< "$(sq_line ANIM)"
}
sq_s() { echo "active ${A_ACT:-?} frames ${A_COUNT:-?} of ${A_FW:-?}x${A_FH:-?}"; }
sq_open() { # ARGS
    draw_quit
    draw_settle
    DRAW_EXTRA_ARGS="$1"
    draw_launch 15
    wait_for 1.5 "sequence loaded"
    assert_no_crash
    sq_read
}
sq_batch() { # ARGS... -> SQ_RC, SQ_OUT
    SQ_OUT=$( cd "$DRAW_ROOT" && HOME="$SQ_T/home" XDG_CONFIG_HOME="$SQ_T/home/.config" XDG_DATA_HOME="$SQ_T/home/.local/share" \
      XDG_CACHE_HOME="$SQ_T/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$@" </dev/null 2>>"$SQ_T/err.txt" )
    SQ_RC=$?
}
sq_same() { # PREFIX FILES... -> 0 when PREFIX_0001.png.. are exactly FILES, in order, and no more
    local pre=$1 k=1 f ae png; shift
    for f in "$@"; do
        png="$SQ_T/o/${pre}_$(printf %04d $k).png"
        [[ -s "$png" ]] || { SQ_WHY="missing $(basename "$png")"; return 1; }
        ae=$(magick compare -metric AE "$png" "$f" null: 2>&1 | awk '{print $1}')
        [[ "$ae" == 0 ]] || { SQ_WHY="$(basename "$png") vs $(basename "$f"): '$ae' pixels differ"; cp -f "$png" "$SCREENSHOTS_DIR/seq-import-got.png" 2>/dev/null; return 1; }
        k=$(( k + 1 ))
    done
    [[ ! -e "$SQ_T/o/${pre}_$(printf %04d $k).png" ]] || { SQ_WHY="more PNGs than ticks"; return 1; }
}

info "DRAW --sequence f_0003.png (any file of the sequence)"
sq_open "--sequence $SQ_T/a/f_0003.png"
[[ "$A_ACT" == -1 && "$A_COUNT" == 4 && "$A_FW" == 12 && "$A_FH" == 10 && "$A_CUR" == 1 ]] \
    && pass "f_0001..f_0005: 4 frames of 12x10 (f_0003 = f_0002 is a hold), f_0001_mask / g_0002 / f_notes.txt left out" || fail "sequence a: $(sq_s) (wanted 4 frames of 12x10)"
sq_batch --sequence "$SQ_T/a/f_0001.png" --export-anim "$SQ_T/o/s.png"
SQ_WHY=""
[[ "$SQ_RC" == 0 ]] && sq_same s "$SQ_T"/a/f_000{1,2,3,4,5}.png \
    && pass "exported again as a PNG sequence: the same five files, pixel for pixel (the hold back as a repeat)" || fail "round trip: exit $SQ_RC, $SQ_WHY, '$(tr '\n' '|' <<< "$SQ_OUT")'"

info "walk1 .. walk10 (not padded), walk7 smaller"
sq_batch --sequence "$SQ_T/b/walk1.png" --export-anim "$SQ_T/o/w.png"
SQ_WHY=""
[[ "$SQ_RC" == 0 ]] && sq_same w "$SQ_T"/b/walk{1,2,3,4,5,6}.png "$SQ_T/x/walk7-in-cell.png" "$SQ_T"/b/walk{8,9,10}.png \
    && pass "10 frames in number order (walk10 last), walk7 at its cell's top left" || fail "walk: exit $SQ_RC, $SQ_WHY, '$(tr '\n' '|' <<< "$SQ_OUT")'"

info "Not a sequence"
sq_open "--sequence $SQ_T/c/plain.png"
SQ_PLAIN="$A_ACT"
sq_open "--sequence $SQ_T/c/solo_01.png"
[[ "$SQ_PLAIN" == 0 && "$A_ACT" == 0 ]] && pass "plain.png (no number) and solo_01.png (alone): plain pictures" || fail "not a sequence: plain.png active '$SQ_PLAIN', solo_01.png $(sq_s)"

draw_quit
draw_settle
DRAW_EXTRA_ARGS=""
draw_launch 15
rm -rf "$SQ_T"
assert_window_exists
