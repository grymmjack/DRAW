#!/bin/bash
# assemble.sh PACKDIR PAGEDIR - after make-pack.py PACKDIR and build-scenes.sh (PACKDIR/out):
# copies the pack and samples into the repo, and builds the docs page's images in PAGEDIR.
set -euo pipefail
P=$1; G=$2; R=$(cd "$(dirname "$0")/../.." && pwd)
mkdir -p "$R/SAMPLES/ANIMBRUSH/brushes" "$R/SAMPLES/ANIMBRUSH/scenes" "$G/brushes" "$G/scenes"
cp "$P/animbrush-pack.dset" "$R/ASSETS/DSETS/BRUSHES/animbrush-pack.dset"
cp "$P"/brushes/*.png "$R/SAMPLES/ANIMBRUSH/brushes/"
cp "$P"/preview/*.gif "$G/brushes/"
for s in castle-night campfire-night waterfall-day; do
    cp "$P/scenes/$s-base.png" "$R/SAMPLES/ANIMBRUSH/scenes/"
    cp "$P/out/$s.draw" "$P/out/$s.gif" "$R/SAMPLES/ANIMBRUSH/scenes/"
    magick "$P/out/$s.gif" -coalesce -scale 300% -layers Optimize "$G/scenes/$s.gif"
    magick "$P/out/$s.gif" -coalesce \( -clone 0 -clone 6 +append \) \( -clone 12 -clone 18 +append \) \
        -delete 0-23 -background '#262b44' -append -scale 200% "$G/scenes/$s-strip.png"
done
echo "assembled into $R/SAMPLES/ANIMBRUSH, $R/ASSETS/DSETS/BRUSHES and $G"
