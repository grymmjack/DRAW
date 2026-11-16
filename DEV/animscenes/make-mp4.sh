#!/usr/bin/env bash
# make-mp4.sh OUTDIR NAME... - an MP4 per scene for the showcase page: DRAW exports the
# frames as a full-colour PNG sequence (batch, Xvfb, throwaway HOME), ffmpeg scales them 4x
# (nearest neighbour), plays the loop twice and mixes the two WAVs under it. Not committed.
#   DRAW_BIN=/abs/DRAW.run ./make-mp4.sh /tmp/mp4 space beach
set -euo pipefail
H=$(cd "$(dirname "$0")" && pwd); R=$(cd "$H/../.." && pwd); O=$1; shift; mkdir -p "$O"
B=${DRAW_BIN:-$R/DRAW-swm.run}
for N in "$@"; do
    D="$R/SAMPLES/ANIMSCENES/$N"; T=$(mktemp -d "$O/.seq-XXXX"); mkdir -p "$T/home"
    env HOME="$T/home" XDG_CONFIG_HOME="$T/home/.config" XDG_DATA_HOME="$T/home/.local/share" XDG_CACHE_HOME="$T/home/.cache" \
        QB64PE_NOPROMPT=y timeout -k 5 180 xvfb-run -a "$B" --option ANIM_SOUND_VOLUME=0 "$D/$N.draw" --export-anim "$T/f.png" </dev/null >"$T/log" 2>&1
    FPS=$(sed -n 's/.*at \([0-9.]*\) fps.*/\1/p' "$T/log" | head -1); FPS=${FPS:-12}
    ffmpeg -v error -y -stream_loop 1 -framerate "$FPS" -i "$T/f_%04d.png" -stream_loop 1 -i "$D/$N-music.wav" -stream_loop 1 -i "$D/$N-sfx.wav" \
        -filter_complex "[0:v]scale=iw*4:ih*4:flags=neighbor,format=yuv420p[v];[1:a][2:a]amix=inputs=2:normalize=0,volume=0.9[a]" \
        -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset slow -r "$FPS" -c:a aac -b:a 128k -shortest -movflags +faststart "$O/$N.mp4"
    magick "$T/f_0001.png" -scale 400% "$O/$N-poster.png"
    echo "$N.mp4 $(stat -c %s "$O/$N.mp4") bytes, $(command ls "$T"/f_*.png | wc -l) frames at $FPS fps"
    rm -rf "$T"
done
