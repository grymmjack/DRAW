#!/usr/bin/env bash
# Regression: QB64 code export must produce a COMPILABLE standalone program.
#
# Locks BUG-79: the exporter emitted the DRAW-internal helper SAFE_FREEIMAGE into
# generated code where it is undefined -> "Syntax error ... SAFE_FREEIMAGE" -> the
# exported .BAS would not compile at all. The fix emits a self-contained
# SUB SAFE_FREEIMAGE into every generated program; this test proves the output
# both CONTAINS that helper and actually COMPILES with qb64pe.
#
# Also exercises the group-aware export path touched by BUG-60 (hidden-group
# children excluded) by exporting a real multi-layer project.
#
# Uses the --export-qb64 <path> batch hook (loads the CLI file if given, exports a
# QB64 project to <path> on the first frame, then exits) so there is no GUI dialog
# to drive -- deterministic, not flaky. Run under xvfb (DRAW needs a display).
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1   # repo root (script lives in DEV/tools/)
[ -x ./DRAW.run ] || { echo "test-qb64-export: build DRAW first (make)"; exit 1; }
QB64="${QB64PE:-$HOME/git/qb64pe/qb64pe}"
[ -x "$QB64" ] || { echo "test-qb64-export: qb64pe not found at $QB64 (set QB64PE=...)"; exit 1; }
command -v xvfb-run >/dev/null || { echo "test-qb64-export: xvfb-run required"; exit 1; }

OUT=$(mktemp -d)
TMPCFG=$(mktemp -d); mkdir -p "$TMPCFG/DRAW"
trap 'rm -rf "$OUT" "$TMPCFG"' EXIT
fail=0

# Pinned QA config -> deterministic, no first-run/migration prompt to block the
# main loop before the frame-1 export fires. XDG isolation keeps the user's config
# untouched.
QACFG="QA/DRAW.qa.cfg"
export_qb64() {  # $1=out.bas  $2=optional input .draw/.png
    local out="$1" src="${2:-}"
    if [ -n "$src" ]; then
        XDG_CONFIG_HOME="$TMPCFG" xvfb-run -a ./DRAW.run --config "$QACFG" "$src" --export-qb64 "$out" >/dev/null 2>&1 || true
    else
        XDG_CONFIG_HOME="$TMPCFG" xvfb-run -a ./DRAW.run --config "$QACFG" --export-qb64 "$out" >/dev/null 2>&1 || true
    fi
}

check_case() {  # $1=label  $2=out.bas
    local label="$1" bas="$2"
    if [ ! -s "$bas" ]; then echo "FAIL[$label]: no .BAS produced at $bas"; fail=1; return; fi
    # BUG-79 (a): the self-contained SAFE_FREEIMAGE helper must be emitted
    if grep -q '^SUB SAFE_FREEIMAGE' "$bas"; then
        echo "PASS[$label]: SAFE_FREEIMAGE helper emitted"
    else
        echo "FAIL[$label]: generated program is missing the SUB SAFE_FREEIMAGE definition"; fail=1
    fi
    # BUG-79 (b): the generated program must actually COMPILE
    if "$QB64" -x "$bas" -o "$bas.run" >"$bas.compile.log" 2>&1 && [ -x "$bas.run" ]; then
        echo "PASS[$label]: generated .BAS compiles clean"
    else
        echo "FAIL[$label]: generated .BAS did NOT compile:"; tail -4 "$bas.compile.log" | sed 's/^/    /'; fail=1
    fi
}

# Case 1: default (empty) canvas -- pure BUG-79 regression, fully deterministic.
export_qb64 "$OUT/blank.bas"
check_case "blank-canvas" "$OUT/blank.bas"

# Case 2: a real multi-layer project -- broader coverage of the compositing/emit path.
SPLASH="DEV/_/DRAW Splash.draw"
if [ -f "$SPLASH" ]; then
    export_qb64 "$OUT/splash.bas" "$SPLASH"
    check_case "draw-splash" "$OUT/splash.bas"
else
    echo "SKIP[draw-splash]: sample project not found ($SPLASH)"
fi

echo "----"
[ "$fail" -eq 0 ] && echo "test-qb64-export: ALL PASS" || echo "test-qb64-export: FAILURES"
exit $fail
