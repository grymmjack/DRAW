#!/bin/bash
# build.sh NAME [NAME...] - make each scene's art + audio (scenes/NAME.py), then build it
# in DRAW offscreen (run-scene.sh + scenes/NAME.sh). Output: $ANS_OUT/NAME/ (default
# DEV/animscenes/out, gitignored by DEV/animscenes/.gitignore).
#   DRAW_BIN=/abs/DRAW-swm.run ./DEV/animscenes/build.sh beach
#   ANS_ART_ONLY=1 ./DEV/animscenes/build.sh beach     # just the Python side
set -uo pipefail
R=$(cd "$(dirname "$0")/../.." && pwd); H="$R/DEV/animscenes"
OUT=${ANS_OUT:-$H/out}; mkdir -p "$OUT"
for N in "$@"; do
    echo "=== $N: art + audio ==="
    python3 "$H/scenes/$N.py" "$OUT" || { echo "art failed for $N"; exit 1; }
    [[ -n "${ANS_ART_ONLY:-}" ]] && continue
    read -r FW FH < "$OUT/$N/size.txt"
    cp "$H/run-scene.sh" "$R/QA/tests/zz-animscene.sh"
    ( cd "$R/QA" && T=(tests/zz-animscene.sh) && ANS_NAME=$N ANS_DIR="$OUT/$N" FW=$FW FH=$FH \
        DRAW_BIN=${DRAW_BIN:-$R/DRAW-swm.run} QA_RESULTS_DIR="${QA_RESULTS_DIR:-$OUT/qa-$N}" \
        timeout ${ANS_TIMEOUT:-3000} ./draw-qa.sh --rerun-passed "${T[@]}" ) 2>&1 | tail -${ANS_TAIL:-60}
    rm -f "$R/QA/tests/zz-animscene.sh"
done
