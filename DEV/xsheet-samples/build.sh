#!/bin/bash
# DEV/xsheet-samples/build.sh [NAME...] - build the X-sheet holds + lanes examples into
# SAMPLES/XSHEET/: make-art.py writes each NAME.aseprite (layers, groups, linked cels = holds),
# a batch DRAW converts it to NAME.draw, drive.sh (run offscreen by the QA harness) adds the
# keyframe lanes on the X-sheet and saves, then a batch DRAW exports NAME.gif from the result.
#   ./DEV/xsheet-samples/build.sh                 # all three
#   ./DEV/xsheet-samples/build.sh bounce          # one
set -uo pipefail
R=$(cd "$(dirname "$0")/../.." && pwd); H="$R/DEV/xsheet-samples"
OUT=${XS_OUT:-$R/SAMPLES/XSHEET}
NAMES=${*:-bounce parallax title}
BIN=${DRAW_BIN:-$R/DRAW.run}
WORK=$(mktemp -d /tmp/draw-xsheet-samples-XXXXXX)
mkdir -p "$OUT" "$WORK/home"
batch() { # ARGS... - a fresh DRAW, throwaway HOME, its own Xvfb (no window anywhere)
    ( cd "$R" && HOME="$WORK/home" XDG_CONFIG_HOME="$WORK/home/.config" XDG_DATA_HOME="$WORK/home/.local/share" \
      XDG_CACHE_HOME="$WORK/home/.cache" xvfb-run -a -s "-screen 0 1280x800x24" timeout -k 5 120 "$BIN" "$@" </dev/null >>"$WORK/batch.txt" 2>&1 )
}
python3 "$H/make-art.py" "$WORK" || exit 1
for N in $NAMES; do
    batch "$WORK/$N.aseprite" --export "$WORK/$N.draw" || { echo "$N: batch convert failed"; tail -5 "$WORK/batch.txt"; exit 1; }
done
cp "$H/drive.sh" "$R/QA/tests/zz-xsheet-samples.sh"
( cd "$R/QA" && XS_DIR="$WORK" XS_NAMES="$NAMES" DRAW_BIN="$BIN" timeout ${XS_TIMEOUT:-2400} \
    ./draw-qa.sh --rerun-passed tests/zz-xsheet-samples.sh ) 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -E "PASS|FAIL|Results"
rm -f "$R/QA/tests/zz-xsheet-samples.sh"
for N in $NAMES; do
    cp "$WORK/$N.draw" "$OUT/$N.draw"
    batch "$OUT/$N.draw" --export-anim "$OUT/$N.gif" || echo "$N: GIF export failed"
done
echo "built: $(cd "$OUT" && ls $(for N in $NAMES; do echo "$N.draw $N.gif"; done) 2>/dev/null | tr '\n' ' ')"
rm -rf "$WORK"
