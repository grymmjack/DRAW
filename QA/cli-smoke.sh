#!/bin/bash
# =============================================================================
# cli-smoke.sh — standalone CLI regression guard (NOT a GUI-harness test)
#
# The console-only command-line operations must print to the console, exit, and
# NEVER show a graphics window. The app starts with $SCREENHIDE (_COMMON.BI) and
# reveals its window exactly once via _SCREENSHOW in DRAW.BAS, on the normal
# editor-launch path; every CLI op SYSTEMs earlier, so none flash a window.
# (Added 2026-08-16 alongside that change.)
#
# This lives OUTSIDE QA/tests/ on purpose: the xdotool GUI harness launches DRAW
# and keeps it running to region-diff a live UI. These checks instead launch DRAW
# with a flag and assert it EXITS with no visible window — a different lifecycle,
# so it runs standalone (Xvfb + xdotool), not through draw-qa.sh.
#
# Verifies:
#   --help / --version / --options-list  -> exit 0, console text, NO window
#   --config-upgrade                     -> exit 0, console text, NO window,
#                                           reconcile-and-exit (adds a missing key
#                                           with its default; converges on re-run)
#   normal launch                        -> a VISIBLE window appears, stays up
#
# Usage:  QA/cli-smoke.sh            (uses ./DRAW.run, builds nothing)
# Exit:   0 = all pass, 1 = a failure (prints which)
# =============================================================================
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$ROOT/DRAW.run"
QACFG="$ROOT/QA/DRAW.qa.cfg"
TMP="$(mktemp -d)"
DPY=":91"
XVFB_PID=""
FAILED=0

cleanup() { [ -n "$XVFB_PID" ] && kill "$XVFB_PID" 2>/dev/null; rm -rf "$TMP"; }
trap cleanup EXIT

pass() { echo "  PASS: $*"; }
fail() { echo "  FAIL: $*"; FAILED=1; }

command -v Xvfb   >/dev/null || { echo "cli-smoke: Xvfb not found"; exit 2; }
command -v xdotool>/dev/null || { echo "cli-smoke: xdotool not found"; exit 2; }
[ -x "$BIN" ] || { echo "cli-smoke: $BIN not built — run 'make' first"; exit 2; }
[ -f "$QACFG" ] || { echo "cli-smoke: missing $QACFG"; exit 2; }

Xvfb "$DPY" -screen 0 1280x1024x24 >/dev/null 2>&1 &
XVFB_PID=$!
sleep 1
export DISPLAY="$DPY"

# Launch DRAW with args; poll for a visible DRAW window while it runs; return via
# globals: RC (exit code), SAW_WINDOW (yes/no), OUT (captured console output path).
run_cli() {
    local out="$TMP/out.$$"; OUT="$out"
    "$BIN" "$@" >"$out" 2>&1 &
    local pid=$!; SAW_WINDOW="no"
    local i
    for i in $(seq 1 80); do
        if [ -n "$(xdotool search --onlyvisible --name 'DRAW' 2>/dev/null | head -1)" ]; then
            SAW_WINDOW="yes"
        fi
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
    done
    wait "$pid"; RC=$?
}

echo "=== CLI console-only ops (expect: exit 0, no window, console text) ==="
for flag in --help --version --options-list; do
    run_cli "$flag"
    if [ "$RC" -eq 0 ] && [ "$SAW_WINDOW" = "no" ] && [ -s "$OUT" ]; then
        pass "$flag (exit 0, no window, printed $(wc -l <"$OUT") lines)"
    else
        fail "$flag (exit=$RC window=$SAW_WINDOW bytes=$(wc -c <"$OUT"))"
    fi
done

echo "=== --config-upgrade (console-only reconcile-and-exit) ==="
# Copy the QA config and remove one known key so the upgrade has something to add.
cp "$QACFG" "$TMP/up.cfg"
grep -iv '^\s*TOOLTIPS_DISABLED\s*=' "$TMP/up.cfg" > "$TMP/up.tmp" && mv "$TMP/up.tmp" "$TMP/up.cfg"
run_cli --config "$TMP/up.cfg" --config-upgrade
if [ "$RC" -eq 0 ] && [ "$SAW_WINDOW" = "no" ] && grep -qi "Config upgraded" "$OUT"; then
    pass "--config-upgrade added the missing key (exit 0, no window)"
else
    fail "--config-upgrade (exit=$RC window=$SAW_WINDOW) output: $(head -1 "$OUT")"
fi
# The key must come back with its DEFAULT value, under the upgrade marker.
if awk '/Added by --config-upgrade/{f=1} f&&/TOOLTIPS_DISABLED=/{print; hit=1} END{exit !hit}' "$TMP/up.cfg" >/dev/null; then
    pass "re-added TOOLTIPS_DISABLED with its default"
else
    fail "TOOLTIPS_DISABLED was not re-added under the upgrade marker"
fi
# Convergence: dedupe (as the on-exit save would) then re-run — must add nothing.
grep -vE '^\s*(#|;|$)' "$TMP/up.cfg" | awk -F= '!/=/{print;next} !seen[toupper($1)]++' > "$TMP/up.ded" && mv "$TMP/up.ded" "$TMP/up.cfg"
run_cli --config "$TMP/up.cfg" --config-upgrade
if grep -qi "up to date" "$OUT"; then
    pass "second run converges (no keys re-added — MAX_KEYS regression guard)"
else
    fail "second run did NOT converge: $(head -1 "$OUT")"
fi

echo "=== normal launch (expect a VISIBLE window that stays up) ==="
cp "$QACFG" "$TMP/norm.cfg"
"$BIN" --config "$TMP/norm.cfg" >"$TMP/norm.out" 2>&1 &
NPID=$!
SAW="no"
for i in $(seq 1 80); do
    if [ -n "$(xdotool search --onlyvisible --name 'DRAW' 2>/dev/null | head -1)" ]; then SAW="yes"; break; fi
    kill -0 "$NPID" 2>/dev/null || break
    sleep 0.15
done
if [ "$SAW" = "yes" ] && kill -0 "$NPID" 2>/dev/null; then
    pass "normal launch shows a window and keeps running"
else
    fail "normal launch (window=$SAW alive=$(kill -0 "$NPID" 2>/dev/null && echo yes || echo no)) $(tail -2 "$TMP/norm.out")"
fi
kill "$NPID" 2>/dev/null

echo "=== auto-scale detection (window must NOT collapse to the 320x200 minimum) ==="
# The window starts hidden ($SCREENHIDE); SCREEN_init MUST _SCREENSHOW before it
# queries _DESKTOPWIDTH, or SDL reports the desktop as 0x0 and auto-detect clamps
# the viewport to WIN_MIN (320x200) — a postage-stamp window. This Xvfb is
# 1280x1024, so a correctly auto-detected window is ~1152 wide (1280 * 0.9), well
# clear of 320. Use auto sentinels (SCREEN_WIDTH/HEIGHT/DISPLAY_SCALE/UI_SCALE=0)
# so the auto-detect path actually runs.
cp "$QACFG" "$TMP/auto.cfg"
for k in SCREEN_WIDTH SCREEN_HEIGHT DISPLAY_SCALE UI_SCALE; do
    grep -iqE "^$k=" "$TMP/auto.cfg" && sed -i "s/^$k=.*/$k=0/I" "$TMP/auto.cfg" || printf '%s=0\n' "$k" >> "$TMP/auto.cfg"
done
"$BIN" --config "$TMP/auto.cfg" >"$TMP/auto.out" 2>&1 &
APID=$!; GEO=""
for i in $(seq 1 100); do
    W=$(xdotool search --onlyvisible --name 'DRAW' 2>/dev/null | head -1)
    if [ -n "$W" ]; then GEO=$(xdotool getwindowgeometry "$W" 2>/dev/null | grep -oE 'Geometry: [0-9]+x[0-9]+' | grep -oE '[0-9]+x[0-9]+'); [ -n "$GEO" ] && break; fi
    kill -0 "$APID" 2>/dev/null || break
    sleep 0.15
done
GEOW="${GEO%x*}"
if [ -n "$GEOW" ] && [ "$GEOW" -gt 640 ] 2>/dev/null; then
    pass "auto-detect sized the window to ${GEO:-?} on a 1280x1024 desktop (not the 320x200 clamp)"
else
    fail "auto-detect gave a postage-stamp window (${GEO:-none}) — _DESKTOPWIDTH likely 0 (hidden-window regression)"
fi
kill "$APID" 2>/dev/null

echo
if [ "$FAILED" -eq 0 ]; then echo "cli-smoke: ALL PASS"; else echo "cli-smoke: FAILURES ABOVE"; fi
exit "$FAILED"
