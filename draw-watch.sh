#!/bin/bash
# draw-watch.sh — Launch DRAW.run and alert when CPU exceeds threshold
# Usage: ./draw-watch.sh [threshold%]   (default: 80)
#
# Uses `top -b` for measurement — same source as htop, numbers will match.
# %CPU can exceed 100% on multi-core (e.g. 200% = 2 full cores used).

THRESHOLD=${1:-80}
INTERVAL=1   # seconds between top samples
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRAW_BIN="$SCRIPT_DIR/DRAW.run"

if [ ! -x "$DRAW_BIN" ]; then
    echo "Error: $DRAW_BIN not found or not executable." >&2
    exit 1
fi

DRAW_PID=""

cleanup() {
    echo ""
    echo "Monitor stopped."
    if [ -n "$DRAW_PID" ] && kill -0 "$DRAW_PID" 2>/dev/null; then
        echo "DRAW.run (PID $DRAW_PID) is still running."
    fi
    exit 0
}

trap cleanup INT TERM

echo "Starting DRAW.run..."
# setsid gives DRAW.run its own process group so Ctrl+C here won't kill it
setsid "$DRAW_BIN" &
DRAW_PID=$!

echo "Monitoring PID $DRAW_PID — CPU alert threshold: ${THRESHOLD}%"
echo "Press Ctrl+C to stop monitoring (DRAW.run keeps running)"
echo ""

# Wait up to 3 seconds for the process to appear in /proc
for i in $(seq 1 15); do
    [ -d "/proc/$DRAW_PID" ] && break
    sleep 0.2
done
if [ ! -d "/proc/$DRAW_PID" ]; then
    echo "Error: DRAW.run (PID $DRAW_PID) never appeared in /proc." >&2
    exit 1
fi

echo "[$(date '+%H:%M:%S')] First sample in ${INTERVAL}s..."
while kill -0 "$DRAW_PID" 2>/dev/null; do
    # top -b -n2: first snapshot is cumulative since boot; second snapshot is
    # the true delta over INTERVAL. top uses Irix mode by default (per-core,
    # same as htop) so no scaling needed.
    CPU=$(top -b -n2 -d "$INTERVAL" -p "$DRAW_PID" 2>/dev/null \
          | awk -v pid="$DRAW_PID" '$1==pid {cpu=$9} END {printf "%d", cpu+0.5}')

    if [ -z "$CPU" ]; then
        echo "DRAW.run has exited."
        break
    fi

    if [ "$CPU" -gt "$THRESHOLD" ]; then
        printf "\a"
        echo "[$(date '+%H:%M:%S')] ALERT: CPU ${CPU}% > ${THRESHOLD}% (PID $DRAW_PID)"
    else
        echo "[$(date '+%H:%M:%S')] OK: CPU ${CPU}% (PID $DRAW_PID)"
    fi
done

echo "DRAW.run is no longer running."
