#!/usr/bin/env bash
# Regression: palette color cycling exports (batch CLI, no dialogs).
#
#   1. fixture PNG + GPL --cycle x3 --export .draw   -> ranges survive a reopen
#   2. .draw --export .bas -> the generated program COMPILES, ANIMATES (two
#      screenshots differ) and exits 0 on Esc
#   (GIF / animated GIF / LBM cases are appended by their phases)
#
# Run under xvfb (DRAW needs a display). XDG isolation keeps the user's config untouched.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
[ -x ./DRAW.run ] || { echo "test-cycle-exports: build DRAW first (make)"; exit 1; }
QB64="${QB64PE:-$HOME/git/qb64pe/qb64pe}"
command -v xvfb-run >/dev/null || { echo "test-cycle-exports: xvfb-run required"; exit 1; }

OUT=$(mktemp -d)
TMPCFG=$(mktemp -d); mkdir -p "$TMPCFG/DRAW"
trap 'rm -rf "$OUT" "$TMPCFG"' EXIT
fail=0
QACFG="QA/DRAW.qa.cfg"
[ -f "$QACFG" ] || { echo "test-cycle-exports: $QACFG missing (run QA/draw-qa.sh once)"; exit 1; }

draw_batch() {  # args... ; log in $OUT/last.log
    XDG_CONFIG_HOME="$TMPCFG" QB64PE_LOG_HANDLERS=console QB64PE_LOG_LEVEL=2 \
        xvfb-run -a ./DRAW.run --config "$QACFG" "$@" >"$OUT/last.log" 2>&1
}
pass() { echo "PASS: $*"; }
failx() { echo "FAIL: $*"; fail=1; }

python3 DEV/tools/cycle-fixture.py "$OUT"

# --- 1. .draw round trip ---
draw_batch "$OUT/bands.png" --palette "$OUT/bands.gpl" --cycle 1-4:8 --cycle 5-8:4:rev --cycle 9-13:6:ping --export "$OUT/bands.draw" \
    && [ -s "$OUT/bands.draw" ] && pass ".draw written" || failx ".draw export"
draw_batch "$OUT/bands.draw" --export "$OUT/bands2.draw"
grep -aq "CYC 3: 9-13 PING 6.0/s" "$OUT/last.log" && grep -aq "CYC 2: 5-8 REV 4.0/s" "$OUT/last.log" \
    && pass "ranges survive save + reopen" || failx "ranges lost on reopen"

# --- 2. cycling .bas ---
draw_batch "$OUT/bands.draw" --export "$OUT/bands.bas" && [ -s "$OUT/bands.bas" ] && pass ".bas written" || failx ".bas export"
if [ -x "$QB64" ]; then
    if "$QB64" -w -x "$OUT/bands.bas" -o "$OUT/bands-bas.run" >"$OUT/bas-compile.log" 2>&1 && [ -x "$OUT/bands-bas.run" ]; then
        pass "generated .bas compiles"
        cat > "$OUT/run-bas.sh" <<RUN
#!/usr/bin/env bash
"$OUT/bands-bas.run" & P=\$!
sleep 2.5
xwd -root -silent > "$OUT/a.xwd"; sleep 0.4; xwd -root -silent > "$OUT/b.xwd"
W=\$(xdotool search --pid \$P | head -1); xdotool key --window "\$W" Escape
wait \$P; echo "exit=\$?" > "$OUT/bas-exit.txt"
RUN
        chmod +x "$OUT/run-bas.sh"
        xvfb-run -a -s "-screen 0 1280x800x24" "$OUT/run-bas.sh" >/dev/null 2>&1
        AE=$(/usr/bin/compare -metric AE "xwd:$OUT/a.xwd" "xwd:$OUT/b.xwd" null: 2>&1 | awk '{print int($1)}')
        [ "${AE:-0}" -gt 0 ] && pass "generated program animates ($AE px differ)" || failx "generated program does not animate"
        grep -q "exit=0" "$OUT/bas-exit.txt" 2>/dev/null && pass "Esc exits 0" || failx "Esc exit code: $(cat "$OUT/bas-exit.txt" 2>/dev/null)"
    else
        failx "generated .bas does not compile:"; tail -4 "$OUT/bas-compile.log"
    fi
else
    echo "SKIP: qb64pe not found at $QB64 (compile/run of the .bas)"
fi

#@@MORE-CASES@@

[ $fail = 0 ] && echo "test-cycle-exports: ALL PASS" || echo "test-cycle-exports: FAILURES"
exit $fail
