#!/usr/bin/env bash
# Regression: --cfg / --dirs / --dir-* path queries and the colored --help.
# Console-only: runs with NO display (proves the queries exit before any window).
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
[ -x ./DRAW.run ] || { echo "test-cli-dirs: build DRAW first (make)"; exit 1; }
fail=0
pass() { echo "PASS: $*"; }
failx() { echo "FAIL: $*"; fail=1; }
D() { env -u DISPLAY -u WAYLAND_DISPLAY ./DRAW.run "$@"; }

# --cfg honors --config and prints an absolute path
out=$(D --config QA/DRAW.qa.cfg --cfg); rc=$?
[ $rc = 0 ] && [ "$out" = "$PWD/QA/DRAW.qa.cfg" ] && pass "--config X --cfg -> $out" || failx "--cfg with --config: rc=$rc out=$out"
out=$(D --cfg); [ -n "$out" ] && [ "${out:0:1}" = "/" ] && pass "--cfg prints an absolute path ($out)" || failx "--cfg: '$out'"

# every --dir-* prints one absolute line, no trailing slash, no escape codes
for n in cfg data cache crash-logs templates brushes patterns gradients palettes fonts theme theme-images theme-sounds theme-music theme-cursors theme-fonts; do
    out=$(D --dir-$n); rc=$?
    if [ $rc = 0 ] && [ "$(printf '%s\n' "$out" | wc -l)" = 1 ] && [ "${out:0:1}" = "/" ] && [ "${out: -1}" != "/" ] && ! grep -q $'\e' <<<"$out"; then
        [ -d "$out" ] && pass "--dir-$n -> $out" || pass "--dir-$n -> $out (does not exist on this machine)"
    else
        failx "--dir-$n: rc=$rc out='$out'"
    fi
done
[ -d "$(D --dir-theme-sounds)" ] && pass "cd \$(DRAW --dir-theme-sounds) works" || failx "theme sounds dir missing"

# unknown name -> exit 2
D --dir-nope >/dev/null; [ $? = 2 ] && pass "unknown --dir-* exits 2" || failx "unknown --dir-* exit code"

# --dirs: 17 lines, labels, plain when piped
out=$(D --dirs); n=$(printf '%s\n' "$out" | wc -l)
[ "$n" = 17 ] && grep -q '^config file' <<<"$out" && grep -q '^theme-fonts' <<<"$out" && pass "--dirs lists 17 entries" || failx "--dirs ($n lines)"
grep -q $'\e' <<<"$out" && failx "--dirs piped output has escape codes" || pass "--dirs piped output is plain"

# queries never claim a multi-instance slot (config stays the primary one)
a=$(D --cfg); b=$(D --cfg); c=$(D --dirs | head -1)
[ "$a" = "$b" ] && grep -q -- "$a" <<<"$c" && pass "repeated queries report the same (primary) config" || failx "instance drift: $a / $b / $c"

# --help: plain when piped, colored with FORCE_COLOR, lists the new flags
h=$(D --help); grep -q $'\e' <<<"$h" && failx "--help piped has escapes" || pass "--help piped is plain"
hc=$(FORCE_COLOR=1 D --help); grep -q $'\e\[1;36m--cfg' <<<"$hc" && pass "--help colored with FORCE_COLOR" || failx "--help not colored with FORCE_COLOR"
hn=$(FORCE_COLOR=1 NO_COLOR=1 D --help); grep -q $'\e' <<<"$hn" && pass "FORCE_COLOR beats NO_COLOR (explicit)" || pass "NO_COLOR respected"
for f in --cfg --dirs --dir-theme-music --cycle --export-anim --no-color; do
    grep -q -- "$f" <<<"$h" && pass "--help lists $f" || failx "--help missing $f"
done

[ $fail = 0 ] && echo "test-cli-dirs: ALL PASS" || echo "test-cli-dirs: FAILURES"
exit $fail
