#!/bin/bash
LABEL="${1:-bench}"
IMG="/home/grymmjack/git/DRAW/SAMPLES/Ship.png"
DRAW_BIN="/home/grymmjack/git/DRAW/DRAW.run"

setsid "$DRAW_BIN" "$IMG" >/dev/null 2>&1 &
DPID=$!
sleep 5

SUM=0; N=0; PEAK=0
for i in $(seq 1 10); do
    CPU=$(top -b -n 1 -p $DPID 2>/dev/null | tail -1 | awk '{print $9}')
    if [ -n "$CPU" ]; then
        CPUI=${CPU%.*}
        SUM=$((SUM + CPUI)); N=$((N + 1))
        [ "$CPUI" -gt "$PEAK" ] && PEAK=$CPUI
    fi
    sleep 0.5
done

kill $DPID 2>/dev/null
wait 2>/dev/null

if [ $N -gt 0 ]; then AVG=$((SUM / N)); else AVG=0; fi
printf "%-12s idle avg=%2d%%  peak=%2d%%  samples=%d\n" "$LABEL" "$AVG" "$PEAK" "$N"
