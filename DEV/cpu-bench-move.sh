#!/bin/bash
# A/B CPU benchmark that:
#   1. launches DRAW.run with a given image
#   2. activates Move tool (V)
#   3. performs scripted "drag, wait, drag, wait" pattern
#   4. samples CPU continuously in background and reports avg / peak
#
# Usage: ./cpu-bench-move.sh <label> <image-path>

set -u
LABEL="${1:-bench}"
IMG="${2:-/home/grymmjack/Pictures/gj-mist..png}"
DRAW_BIN="/home/grymmjack/git/DRAW/DRAW.run"

if [[ ! -f "$IMG" ]]; then
    echo "Image not found: $IMG" >&2
    exit 1
fi

# Launch
setsid "$DRAW_BIN" "$IMG" >/dev/null 2>&1 &
DPID=$!

# Wait for window
WID=""
for i in $(seq 1 50); do
    WID=$(xdotool search --pid $DPID --name "DRAW v" 2>/dev/null | head -1)
    [[ -n "$WID" ]] && break
    sleep 0.2
done
if [[ -z "$WID" ]]; then
    echo "no window"; kill -9 $DPID 2>/dev/null; exit 1
fi

# Position + focus + let startup settle
xdotool windowactivate --sync "$WID"
sleep 0.5
xdotool key --window "$WID" super+Home 2>/dev/null
sleep 4

# Get window center
eval "$(xdotool getwindowgeometry --shell $WID)"
CX=$((X + WIDTH/2))
CY=$((Y + HEIGHT/2))

# Activate move tool
xdotool windowactivate --sync "$WID"
xdotool key --delay 30 v
sleep 0.5

# Start CPU sampler in background, write to log
LOG="/tmp/cpu-bench-$LABEL.$$"
( for i in $(seq 1 60); do
    CPU=$(top -b -n 1 -p $DPID 2>/dev/null | tail -1 | awk '{print $9}')
    [[ -n "$CPU" ]] && echo "$CPU" >> "$LOG"
    sleep 0.25
  done ) &
SAMPLER=$!

# Scripted move-wait-move pattern (8 cycles ~ 12 sec)
xdotool mousemove $CX $CY
sleep 0.3
for cycle in 1 2 3 4 5 6 7 8; do
    # drag
    xdotool mousemove $CX $CY
    sleep 0.05
    xdotool mousedown 1
    sleep 0.05
    for s in 1 2 3 4 5; do
        xdotool mousemove $((CX + s*8)) $((CY + s*4))
        sleep 0.04
    done
    xdotool mouseup 1
    sleep 0.05
    # wait (mouse still in window)
    sleep 1.0
    # drag back
    xdotool mousedown 1
    sleep 0.05
    for s in 1 2 3 4 5; do
        xdotool mousemove $((CX + (5-s)*8)) $((CY + (5-s)*4))
        sleep 0.04
    done
    xdotool mouseup 1
    sleep 0.5
done

# Move mouse outside window for idle measurement
xdotool mousemove 50 50
sleep 2

# Stop sampler
wait $SAMPLER 2>/dev/null

kill $DPID 2>/dev/null
wait 2>/dev/null

# Analyze
if [[ -s "$LOG" ]]; then
    awk -v label="$LABEL" '
        BEGIN { sum=0; n=0; peak=0 }
        { gsub(",", ".", $1); v=$1+0; sum+=v; n++; if (v>peak) peak=v }
        END { if (n>0) printf "%-12s n=%d  avg=%.1f%%  peak=%.1f%%\n", label, n, sum/n, peak }
    ' "$LOG"
    rm -f "$LOG"
else
    echo "$LABEL: no samples"
fi
