#!/usr/bin/env bash
# make-mp4.sh OUTDIR NAME... - an MP4 per scene for the showcase page: the GIF scaled 4x
# (nearest neighbour), looped twice, with the two WAVs mixed under it. Not committed.
set -euo pipefail
H=$(cd "$(dirname "$0")" && pwd); R=$(cd "$H/../.." && pwd); O=$1; shift; mkdir -p "$O"
for N in "$@"; do
    D="$R/SAMPLES/ANIMSCENES/$N"
    ffmpeg -v error -y -stream_loop 1 -i "$D/$N.gif" -stream_loop 1 -i "$D/$N-music.wav" -stream_loop 1 -i "$D/$N-sfx.wav" \
        -filter_complex "[0:v]scale=iw*4:ih*4:flags=neighbor,format=yuv420p[v];[1:a][2:a]amix=inputs=2:normalize=0,volume=0.9[a]" \
        -map "[v]" -map "[a]" -c:v libx264 -crf 20 -preset slow -c:a aac -b:a 128k -shortest -movflags +faststart "$O/$N.mp4"
    echo "$N.mp4 $(stat -c %s "$O/$N.mp4") bytes"
    magick "$D/$N.gif[0]" -scale 400% "$O/$N-poster.png"
done
