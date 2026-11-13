#!/usr/bin/env bash
# publish.sh NAME... - copy a built scene from out/NAME into SAMPLES/ANIMSCENES/NAME:
# the .draw (layers, frames, soundtrack), its GIF, the brush pack (.dset + brushes/ strips
# with frame data), the WAVs (music, sfx, the clips' sound cues - found beside the .draw by
# name), the Move Brush log and the clip log. Refuses a .draw without drAw + drAn.
# ANS_PUB=ANIMPROJECTS publishes into SAMPLES/ANIMPROJECTS instead.
set -euo pipefail
H=$(cd "$(dirname "$0")" && pwd); R=$(cd "$H/../.." && pwd)
for N in "$@"; do
    S="$H/out/$N"; D="$R/SAMPLES/${ANS_PUB:-ANIMSCENES}/$N"
    python3 "$H/pngchunks.py" "$S/$N.draw" drAw drAn >/dev/null || { echo "$N: $S/$N.draw has no drAw + drAn - not published"; exit 1; }
    [[ $(magick identify "$S/$N.gif" | wc -l) -gt 1 ]] || { echo "$N: $N.gif is not animated - not published"; exit 1; }
    rm -rf "$D"; mkdir -p "$D/brushes"
    cp "$S/$N.draw" "$S/$N.gif" "$S/$N-pack.dset" "$S"/*.wav "$D/"
    for f in "$S/$N-moves.txt" "$S/$N-clips.txt"; do [[ -s "$f" ]] && cp "$f" "$D/"; done
    cp "$S"/brushes/*.png "$D/brushes/"
    cp "$S/pack.txt" "$D/$N-pack.txt"
    echo "$N -> $D ($(du -sh "$D" | cut -f1))"
done
