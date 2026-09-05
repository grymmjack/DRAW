#!/usr/bin/env bash
# Validate the Phase 3 keyboard-rebind override engine (CFG/BINDINGS.*).
#
# Uses --dump-shortcuts (which runs INPUTS_init -> BINDINGS_load -> BINDINGS_apply)
# to observe the registry AFTER overrides are applied: a DRAW.bindings that rebinds
# Flip Horizontal (action 315) from 'h'(104) to 'j'(106) must make the generated
# table show the binding on J; with no override it must show H.
set -uo pipefail
cd "$(dirname "$0")/../.."   # repo root (script lives in DEV/tools/)
[ -x ./DRAW.run ] || { echo "test-rebind-engine: build DRAW first (make)"; exit 1; }

TMPCFG=$(mktemp -d)
trap 'rm -rf "$TMPCFG" SHORTCUTS.tables.md' EXIT
mkdir -p "$TMPCFG/DRAW"
fail=0

dump() {  # $1 = XDG_CONFIG_HOME (empty for default)
    rm -f SHORTCUTS.tables.md
    if [ -n "$1" ]; then XDG_CONFIG_HOME="$1" xvfb-run -a ./DRAW.run --dump-shortcuts >/dev/null 2>&1 || true
    else xvfb-run -a ./DRAW.run --dump-shortcuts >/dev/null 2>&1 || true; fi
}

# 1. With override -> Flip H on J
printf '# test\n315 106 0 7\n' > "$TMPCFG/DRAW/DRAW.bindings"
dump "$TMPCFG"
if grep -qE '^\| `J` \| Flip horizontal ' SHORTCUTS.tables.md; then
    echo "PASS: override re-points Flip H  h -> j"
else
    echo "FAIL: override not applied (expected Flip horizontal on J)"; fail=1
fi

# 2. No override -> default H
rm -f "$TMPCFG/DRAW/DRAW.bindings"
dump ""
if grep -qE '^\| `H` \| Flip horizontal ' SHORTCUTS.tables.md; then
    echo "PASS: default binding is H"
else
    echo "FAIL: default binding wrong (expected Flip horizontal on H)"; fail=1
fi

# 3. Preset loader: --load-preset writes DRAW.bindings, the override then applies
printf '# test preset\n315 106 0 7\n' > ASSETS/PRESETS/_test.bindings
rm -f "$TMPCFG/DRAW/DRAW.bindings"
XDG_CONFIG_HOME="$TMPCFG" xvfb-run -a ./DRAW.run --load-preset _test >/dev/null 2>&1 || true
if grep -qE '^315 106 0 7' "$TMPCFG/DRAW/DRAW.bindings" 2>/dev/null; then
    dump "$TMPCFG"
    if grep -qE '^\| `J` \| Flip horizontal ' SHORTCUTS.tables.md; then
        echo "PASS: --load-preset applied (Flip H on J)"
    else
        echo "FAIL: preset wrote DRAW.bindings but override didn't apply"; fail=1
    fi
else
    echo "FAIL: --load-preset did not write DRAW.bindings"; fail=1
fi
rm -f ASSETS/PRESETS/_test.bindings

[ "$fail" -eq 0 ] && echo "test-rebind-engine: ALL PASS" || echo "test-rebind-engine: FAILURES"
exit $fail
