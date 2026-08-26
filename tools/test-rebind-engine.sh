#!/usr/bin/env bash
# Validate the Phase 3 keyboard-rebind override engine (CFG/BINDINGS.*).
#
# Uses --dump-shortcuts (which runs INPUTS_init -> BINDINGS_load -> BINDINGS_apply)
# to observe the registry AFTER overrides are applied: a DRAW.bindings that rebinds
# Flip Horizontal (action 315) from 'h'(104) to 'j'(106) must make the generated
# table show the binding on J; with no override it must show H.
set -uo pipefail
cd "$(dirname "$0")/.."
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

[ "$fail" -eq 0 ] && echo "test-rebind-engine: ALL PASS" || echo "test-rebind-engine: FAILURES"
exit $fail
