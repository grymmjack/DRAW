#!/usr/bin/env bash
# Regenerate SAMPLES/COLOR CYCLING/: the palette color cycling examples.
#
#   DEV/tools/make-cycle-examples.sh            # needs DRAW.run (make) + xvfb-run
#
# DEV/tools/cycle-examples.py paints each scene (exact palette colors) and lists
# its cycle ranges; DRAW's batch mode (--palette --cycle --export) builds the
# .draw document, then exports every cycling format from it:
#   NAME.draw        the DRAW document (open it, press Shift+Tab)
#   NAME.bas         single-file QB64 program (qb64pe -x NAME.bas)
#   NAME.gif         still GIF + GrafX2 CRNG ranges (cycles in GrafX2)
#   ANIMATED_GIF_VERSION/NAME-anim.gif
#                    animated GIF of the cycle (any browser / viewer) - kept in
#                    its own folder: it is a recording, not a cycling document
#   NAME.lbm         DeluxePaint ILBM + CRNG (DeluxePaint, GrafX2, PyDPainter...)
set -euo pipefail
cd "$(dirname "$0")/../.." || exit 1
[ -x ./DRAW.run ] || { echo "build DRAW first (make)"; exit 1; }
command -v xvfb-run >/dev/null || { echo "xvfb-run required"; exit 1; }
QACFG="QA/DRAW.qa.cfg"
[ -f "$QACFG" ] || { echo "$QACFG missing (run QA/draw-qa.sh once)"; exit 1; }

DEST="SAMPLES/COLOR CYCLING"
ANIM="$DEST/ANIMATED_GIF_VERSION"
WORK=$(mktemp -d); TMPCFG=$(mktemp -d); mkdir -p "$TMPCFG/DRAW"
trap 'rm -rf "$WORK" "$TMPCFG"' EXIT
mkdir -p "$DEST" "$ANIM"

draw() { XDG_CONFIG_HOME="$TMPCFG" xvfb-run -a ./DRAW.run --config "$QACFG" "$@" >/dev/null 2>&1; }

python3 DEV/tools/cycle-examples.py "$WORK"
for png in "$WORK"/*.png; do
    name=$(basename "$png" .png)
    args=()
    while read -r spec; do [ -n "$spec" ] && args+=(--cycle "$spec"); done < "$WORK/$name.cycle"
    echo "== $name  (${args[*]})"
    draw "$png" --palette "$WORK/$name.gpl" "${args[@]}" --export "$DEST/$name.draw"
    draw "$DEST/$name.draw" --export "$DEST/$name.bas"
    draw "$DEST/$name.draw" --export "$DEST/$name.gif"
    draw "$DEST/$name.draw" --export-anim "$ANIM/$name-anim.gif"
    draw "$DEST/$name.draw" --export "$DEST/$name.lbm"
    ls -la "$DEST/$name".* "$ANIM/$name"-anim.gif | awk '{print "   ", $5, $NF}'
done
echo "done -> $DEST"
