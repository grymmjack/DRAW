#!/bin/bash
# =============================================================================
# file-anim-batch.sh — QA test: the batch CLI for the animation formats
# (Animation 3.7, OUTPUT/BATCH).
#
# --export and --export-anim repeat: one run writes every animation format.
# The formats only frames have (.apng .json .sheet.bas) work from --export
# too, and --export .png writes the picture flattened. Each export prints one
# console line - "wrote PATH (summary)" or "FAILED PATH: why" - plain text when
# stdout is not a terminal, and the exit code is 1 when any export failed (the
# others are still written).
#
# Throwaway HOME, no window shown (the batch exits on its first frame).
# Fixture: a 64x16 sheet of 16x16 frames, transparent, frame k a 6x6 square of
# its own colour; 4 frames at 10 fps, ping-pong, frame 2 held 3. The same
# pixels without frames for the plain-picture case.
# =============================================================================
info "=== Animation: batch CLI for the animation formats ==="

BT_PY="$DRAW_ROOT/QA/fixtures/png-chunk.py"
BT_T="$(mktemp -d /tmp/draw-qa-animbatch-XXXXXX)"
mkdir -p "$BT_T/home" "$BT_T/o"
BT_DRAW=()
BT_COLORS=(c04040 40c040 4040c0 c0c040)
for n in 0 1 2 3; do
    x=$(( n * 16 + 3 + n ))
    BT_DRAW+=(-fill "#${BT_COLORS[$n]}" -draw "rectangle $x,4 $(( x + 5 )),9")
done
magick -size 64x16 xc:none "${BT_DRAW[@]}" "PNG32:$BT_T/plain.png"
python3 "$BT_PY" put "$BT_T/plain.png" "$BT_T/sheet.png" drAn "$(python3 -c "import struct;print(struct.pack('<12h',1,16,16,0,0,4,1,10,2,2,1,3).hex())")"
bt_run() { # IN ARGS... -> BT_RC, BT_OUT (stdout)
    local in=$1; shift
    BT_OUT=$( cd "$DRAW_ROOT" && HOME="$BT_T/home" XDG_CONFIG_HOME="$BT_T/home/.config" XDG_DATA_HOME="$BT_T/home/.local/share" \
      XDG_CACHE_HOME="$BT_T/home/.cache" timeout --foreground -k 5 90 "$DRAW_BIN" "$in" "$@" </dev/null 2>>"$BT_T/err.txt" )
    BT_RC=$?
}
bt_lines() { grep -c "^$1 " <<< "$BT_OUT"; } # wrote | FAILED -> how many such lines
bt_said() { grep -q "^$1 $BT_T/o/$2\b" <<< "$BT_OUT"; } # wrote|FAILED FILE -> a line for it

# -- one run, every animation format from --export-anim --
bt_run "$BT_T/sheet.png" --export-anim "$BT_T/o/a.gif" --export-anim "$BT_T/o/a.apng" --export-anim "$BT_T/o/seq.png" \
    --export-anim "$BT_T/o/s.json" --export-anim "$BT_T/o/play.bas" --export-anim "$BT_T/o/pl.sheet.bas"
BT_ALL=1
for f in a.gif a.apng seq_0001.png seq_0010.png s.json s.png s.bi play.bas pl.sheet.bas pl.sheet.png; do [[ -s "$BT_T/o/$f" ]] || BT_ALL=0; done
[[ "$BT_RC" == 0 && "$BT_ALL" == 1 ]] && pass "one run, six --export-anim: GIF, APNG, PNG sequence, sprite sheet, BAS player, BAS + sheet - exit 0" \
    || fail "six --export-anim: exit $BT_RC, wrote: $(ls "$BT_T/o" | tr '\n' ' ')"
[[ "$(bt_lines wrote)" == 6 ]] && bt_said wrote a.gif && bt_said wrote a.apng && bt_said wrote seq.png && bt_said wrote s.json && bt_said wrote play.bas && bt_said wrote pl.sheet.bas \
    && pass "a 'wrote' line for each of the six" || fail "console lines: '$(tr '\n' '|' <<< "$BT_OUT")'"
grep -q "^wrote $BT_T/o/a.gif  (6 frames" <<< "$BT_OUT" && pass "with its summary ('$(grep "a.gif" <<< "$BT_OUT" | sed 's/.*  //')')" || fail "no summary on the GIF line: '$(grep "a.gif" <<< "$BT_OUT")'"
[[ "$BT_OUT" != *$'\e'* ]] && pass "plain text (stdout is not a terminal)" || fail "ANSI colours in piped output"

# -- --export takes the frames-only formats too, and .png flattened --
bt_run "$BT_T/sheet.png" --export "$BT_T/o/b.apng" --export "$BT_T/o/b.json" --export "$BT_T/o/b.sheet.bas" --export "$BT_T/o/flat.png"
[[ "$BT_RC" == 0 && -s "$BT_T/o/b.apng" && -s "$BT_T/o/b.json" && -s "$BT_T/o/b.sheet.png" && "$(bt_lines wrote)" == 4 ]] \
    && pass "--export .apng / .json / .sheet.bas: the frames, as from --export-anim" || fail "--export frames formats: exit $BT_RC, '$(tr '\n' '|' <<< "$BT_OUT")'"
cmp -s "$BT_T/o/a.apng" "$BT_T/o/b.apng" && pass "the two APNGs are the same bytes" || fail "--export and --export-anim APNGs differ"
BT_AE=$(magick compare -metric AE "$BT_T/o/flat.png" "PNG32:$BT_T/plain.png" null: 2>&1 | awk '{print $1}')
[[ "$BT_AE" == 0 ]] && pass "--export flat.png: the picture flattened, exact pixels" || fail "flat.png: $BT_AE pixels differ"

# -- one export fails: the rest are written, exit 1, a FAILED line says why --
bt_run "$BT_T/sheet.png" --export-anim "$BT_T/o/ok.gif" --export "$BT_T/o/bad.tif"
[[ "$BT_RC" == 1 && -s "$BT_T/o/ok.gif" ]] && bt_said wrote ok.gif && bt_said FAILED bad.tif && grep -q "unsupported export type '.tif'" <<< "$BT_OUT" \
    && pass "an unknown type: FAILED bad.tif (unsupported, with the types listed), ok.gif still written, exit 1" || fail "bad type: exit $BT_RC, '$(tr '\n' '|' <<< "$BT_OUT")'"

# -- a picture without frames --
bt_run "$BT_T/plain.png" --export-anim "$BT_T/o/p.apng"
[[ "$BT_RC" == 1 && ! -e "$BT_T/o/p.apng" ]] && bt_said FAILED p.apng && grep -q "no frames" <<< "$BT_OUT" \
    && pass "a picture without frames: FAILED p.apng: the document has no frames, exit 1" || fail "no frames: exit $BT_RC, '$(tr '\n' '|' <<< "$BT_OUT")'"

rm -rf "$BT_T"
assert_window_exists
