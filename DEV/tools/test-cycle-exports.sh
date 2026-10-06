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

# --- 3. GIF + GrafX2 CRNG ---
draw_batch "$OUT/bands.draw" --export "$OUT/bands.gif" && [ -s "$OUT/bands.gif" ] && pass ".gif written" || failx ".gif export"
if command -v identify >/dev/null; then
    /usr/bin/convert "$OUT/bands.gif" "$OUT/bands-gif.png" 2>/dev/null
    AE=$(/usr/bin/compare -metric AE "$OUT/bands.png" "$OUT/bands-gif.png" null: 2>&1 | awk '{print int($1)}')
    [ "$AE" = "0" ] && pass "GIF decodes pixel-exact (ImageMagick)" || failx "GIF pixels differ from source ($AE)"
fi
# CRNG records: rate BE16, flags BE16, lo, hi  (8/s fwd 1-4, 4/s rev 5-8, ping 9-13 written fwd)
HEX=$(xxd -p "$OUT/bands.gif" | tr -d '\n')
echo "$HEX" | grep -q "21ff0b43524e4700000000312e301208890001010404440003050806660001090d00" \
    && pass "GrafX2 CRNG extension bytes" || failx "CRNG extension missing/wrong"
echo "$HEX" | grep -q "21ff0b4452415743594" && pass "DRAWCYCL extension present" || failx "DRAWCYCL extension missing"

# --- 4. GIF import: DRAW's own GIF (DRAWCYCL keeps ping-pong) ---
draw_batch "$OUT/bands.gif" --export "$OUT/from-gif.draw"
grep -aq "CYC 3: 9-13 PING 6.0/s" "$OUT/last.log" && grep -aq "CYC 2: 5-8 REV 4.0/s" "$OUT/last.log" \
    && pass "GIF import restores exact ranges (DRAWCYCL)" || failx "GIF import ranges"

# --- 5. GIF import: a real GrafX2 file (CRNG only) -> re-export keeps the CRNG bytes ---
draw_batch QA/fixtures/grafx2-crng.gif --export "$OUT/grafx2-re.gif"
grep -aq "CYC 1: 1-3 FWD" "$OUT/last.log" && grep -aq "CYC 2: 32-47 REV" "$OUT/last.log" \
    && pass "GrafX2 GIF ranges imported (1-3 fwd, 32-47 rev)" || failx "GrafX2 GIF ranges"
CR_ORIG=$(xxd -p QA/fixtures/grafx2-crng.gif | tr -d '\n' | grep -o "21ff0b43524e4700000000312e300c[0-9a-f]\{24\}00")
CR_RE=$(xxd -p "$OUT/grafx2-re.gif" | tr -d '\n' | grep -o "21ff0b43524e4700000000312e300c[0-9a-f]\{24\}00")
[ -n "$CR_ORIG" ] && [ "$CR_ORIG" = "$CR_RE" ] && pass "GrafX2 CRNG bytes identical after DRAW round trip" || failx "CRNG bytes changed ($CR_ORIG vs $CR_RE)"
if command -v identify >/dev/null; then
    /usr/bin/convert QA/fixtures/grafx2-crng.gif "$OUT/g-orig.png"; /usr/bin/convert "$OUT/grafx2-re.gif" "$OUT/g-re.png"
    AE=$(/usr/bin/compare -fuzz 1% -metric AE "$OUT/g-orig.png" "$OUT/g-re.png" null: 2>&1 | awk '{print int($1)}')
    [ "$AE" = "0" ] && pass "GrafX2 GIF pixels kept (within 1 level: duplicate colors are made unique)" || failx "GrafX2 GIF pixels differ ($AE)"
fi

# --- 6. animated GIF of the cycle ---
draw_batch "$OUT/bands.draw" --export-anim "$OUT/anim.gif" && [ -s "$OUT/anim.gif" ] && pass "animated .gif written" || failx "animated gif export"
if command -v identify >/dev/null; then
    NF=$(identify "$OUT/anim.gif" | wc -l); TOT=$(identify -format "%T\n" "$OUT/anim.gif" | awk '{s+=$1} END {print s}')
    # 8/s fwd n=4 (0.5 s), 4/s rev n=4 (1 s), 6/s ping n=5 (8 steps = 1.333 s) -> LCM 4 s
    [ "$NF" = "48" ] && [ "$TOT" = "400" ] && pass "animated GIF: exact 4 s loop in $NF frames" || failx "animated GIF frames=$NF total=${TOT}cs (want 48 / 400)"
    /usr/bin/convert "$OUT/anim.gif" -coalesce "$OUT/anim-%03d.png" 2>/dev/null
    AE=$(/usr/bin/compare -metric AE "$OUT/bands.png" "$OUT/anim-000.png" null: 2>&1 | awk '{print int($1)}')
    [ "$AE" = "0" ] && pass "animated GIF frame 1 == the art" || failx "animated GIF frame 1 differs ($AE)"
    AE=$(/usr/bin/compare -metric AE "$OUT/anim-000.png" "$OUT/anim-001.png" null: 2>&1 | awk '{print int($1)}')
    [ "${AE:-0}" -gt 0 ] && pass "animated GIF frame 2 is cycled" || failx "animated GIF frame 2 unchanged"
fi
if command -v ffmpeg >/dev/null; then
    ffmpeg -v error -i "$OUT/anim.gif" -f null - && pass "ffmpeg decodes the animated GIF" || failx "ffmpeg cannot decode the animated GIF"
fi

#@@MORE-CASES@@

[ $fail = 0 ] && echo "test-cycle-exports: ALL PASS" || echo "test-cycle-exports: FAILURES"
exit $fail
