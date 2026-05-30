#!/usr/bin/env bash
# qb64-shot.sh — launch a QB64-PE GUI binary, screenshot it, and GUARANTEE the
# window never outlives us — whether WE tear it down, the HARD TIMEOUT fires, or
# the USER closes it by hand. Safe for automated/agent use.
#
# Usage:
#   DEV/qb64-shot.sh [--wait] <binary> [out.png] [settle_secs] [hard_timeout_secs]
#
#   --wait   After the screenshot, keep the window up and BLOCK until the user
#            closes it (or the hard timeout fires), then clean up. Without it,
#            the default is: capture, then immediately tear the window down.
#
# Defaults: out=/tmp/qb64-shot.png  settle=1.5  hard_timeout=15
#
# Exit codes: 0 capture OK | 2 bad args/env | 3 process died before a window |
#             4 no window within timeout | 5 user closed window during settle |
#             6 capture produced no/empty PNG
#
# ---------------------------------------------------------------------------
# THREE teardown guarantees (each independent — belt, suspenders, and a backup):
#
#  (A) `trap cleanup EXIT INT TERM` — when THIS script ends for ANY reason
#      (success, error, Ctrl-C), it kills the launched process GROUP.
#  (B) `setsid timeout -k 2 <secs>` — even if this script is itself killed, the
#      binary self-terminates after <secs> (SIGKILL 2s later if it ignores TERM).
#  (C) Background WATCHER subshell — polls the launched PID; the instant it
#      disappears (USER CLOSED IT, crash, or timeout) the watcher exits, which
#      lets --wait return promptly instead of blocking, and records WHY.
#
# Two bugs this deliberately avoids:
#   1. NEVER `pkill -f`/`pgrep -f <path>` — under the agent's `eval '...'` shell
#      wrapper that pattern matches the matcher's OWN argv and SIGTERMs the
#      persistent shell (observed: exit 144, wedged shell). We kill ONLY by the
#      exact integer PID we launched, via its process GROUP (negative PID).
#   2. NO blind `sleep` while a window we don't control is up — the settle is
#      liveness-checked so a mid-settle user-close aborts cleanly (exit 5)
#      instead of screenshotting a dead window.
# ---------------------------------------------------------------------------
set -uo pipefail

WAIT_FOR_CLOSE=0
if [ "${1:-}" = "--wait" ]; then WAIT_FOR_CLOSE=1; shift; fi

BIN="${1:?usage: qb64-shot.sh [--wait] <binary> [out.png] [settle] [hard_timeout]}"
OUT="${2:-/tmp/qb64-shot.png}"
SETTLE="${3:-1.5}"
HARD_TIMEOUT="${4:-15}"

[ -x "$BIN" ] || { echo "error: not executable: $BIN" >&2; exit 2; }
for t in setsid timeout xdotool import; do
    command -v "$t" >/dev/null || { echo "error: missing required tool: $t" >&2; exit 2; }
done

STATUS="$(mktemp /tmp/qb64-shot.status.XXXXXX)"   # watcher records outcome here
WATCH_PID=""

# --- Launch in its OWN process group, under a hard timeout backstop (B) ------
setsid timeout -k 2 "$HARD_TIMEOUT" "$BIN" &
LAUNCH_PID=$!
echo "launched: $BIN  pid=$LAUNCH_PID  (hard timeout ${HARD_TIMEOUT}s)"

# --- Guaranteed teardown (A): by PID GROUP, never by name -------------------
cleanup() {
    [ -n "$WATCH_PID" ] && kill "$WATCH_PID" 2>/dev/null   # stop watcher (exact pid)
    kill -TERM -"$LAUNCH_PID" 2>/dev/null                  # TERM the whole group
    for _ in 1 2 3 4 5; do
        kill -0 "$LAUNCH_PID" 2>/dev/null || break
        sleep 0.2
    done
    kill -KILL -"$LAUNCH_PID" 2>/dev/null                  # make sure
    rm -f "$STATUS"
}
trap cleanup EXIT INT TERM

# --- Background WATCHER (C): detect the process vanishing, record why --------
# Polls only the EXACT launched PID (no name matching). SINGLE exit path: wait
# for the PID to vanish, THEN classify by elapsed time. (An earlier version
# classified by which code path noticed the exit, which RACED the `timeout`
# backstop at the boundary and mislabeled a real timeout as a user-close.)
# Writes one of:
#   user_or_crash <secs>   — gone before the hard timeout  (user closed / crash)
#   timeout <secs>         — gone at/after the hard timeout (backstop reaped it)
( start=$SECONDS
  while kill -0 "$LAUNCH_PID" 2>/dev/null; do sleep 0.3; done
  elapsed=$((SECONDS - start))
  if [ "$elapsed" -ge "$HARD_TIMEOUT" ]; then
      echo "timeout $elapsed" > "$STATUS"
  else
      echo "user_or_crash $elapsed" > "$STATUS"
  fi
) &
WATCH_PID=$!

# --- Wait for the X11 window to actually map (bounded, liveness-checked) -----
WID=""
for _ in $(seq 1 30); do                                  # up to ~6s
    kill -0 "$LAUNCH_PID" 2>/dev/null || { echo "error: process exited before a window appeared" >&2; exit 3; }
    WID="$(xdotool search --pid "$LAUNCH_PID" 2>/dev/null | head -1)"
    [ -n "$WID" ] && break
    sleep 0.2
done
[ -n "$WID" ] || { echo "error: no window for pid $LAUNCH_PID within timeout" >&2; exit 4; }
echo "window: $WID"

# --- Liveness-checked settle (NOT a blind sleep) ----------------------------
# Sleep in small ticks; if the user closes the window mid-settle, bail cleanly
# rather than capturing a dead window.
ticks=$(awk -v s="$SETTLE" 'BEGIN{printf "%d", (s/0.1)+0.5}')
for _ in $(seq 1 "$ticks"); do
    kill -0 "$LAUNCH_PID" 2>/dev/null || { echo "note: user closed the window during settle — no capture" >&2; exit 5; }
    sleep 0.1
done

# --- Timing-correct capture -------------------------------------------------
xdotool windowactivate "$WID" 2>/dev/null
xdotool keyup --window "$WID" ctrl shift alt 2>/dev/null
import -window "$WID" "$OUT" 2>/dev/null
if [ ! -s "$OUT" ]; then
    echo "error: capture produced no image (window may have closed at the last instant)" >&2
    exit 6
fi
echo "saved: $OUT"

# --- Optional interactive wait: block until the USER closes it (or timeout) --
if [ "$WAIT_FOR_CLOSE" = 1 ]; then
    echo "waiting for you to close the window (or ${HARD_TIMEOUT}s hard timeout)..."
    wait "$WATCH_PID" 2>/dev/null     # returns the instant the process vanishes
    reason="$(cat "$STATUS" 2>/dev/null)"
    case "$reason" in
        user_or_crash*) echo "window closed by user after ${reason#* }s" ;;
        timeout*)       echo "hard timeout reached (${reason#* }s) — torn down" ;;
        *)              echo "window gone (reason unknown)" ;;
    esac
fi
# trap fires on exit -> group killed -> nothing left behind.
