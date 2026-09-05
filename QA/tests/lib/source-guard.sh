#!/bin/bash
# =============================================================================
# QA/tests/lib/source-guard.sh — shared scaffolding for SOURCE-level guard tests
#
# A source-guard test asserts that a fix's marker text is still present (or an old
# buggy pattern still absent) in the tree, so a refactor can't silently delete it.
# Several such tests (paste-move-wand, controls-scroll-marker, seam-music,
# deferred-hardening, stable-id-group-membership) used to copy-paste this block;
# they now `source` it instead.
#
# Contract for the sourcing test:
#   - set ROOT to the repo root before sourcing (all guard tests already do:
#     HERE=".../QA/tests"; ROOT="$HERE/../.."). If unset, it is derived here.
#   - after sourcing, call assert_grep / assert_absent, then guard_footer "<label>".
#   - keep the standalone-exit line so `bash <test>` still sets an exit code:
#       if [ "${BASH_SOURCE[0]}" = "$0" ]; then [ "$fails" -eq 0 ] && exit 0 || exit 1; fi
#
# When the harness SOURCES a test, it already defines pass/fail (bumping the suite
# counters); the fallbacks below only apply to standalone `bash <test>` runs.
# =============================================================================

# Repo root — respect the test's ROOT, else derive from the sourcing file's path
# (BASH_SOURCE[1] = the test that sourced us; QA/tests/X.sh -> ../.. = repo root).
: "${ROOT:=$(cd "$(dirname "${BASH_SOURCE[1]}")/../.." && pwd)}"
: "${fails:=0}"

declare -F pass >/dev/null || pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
declare -F fail >/dev/null || fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; fails=$((fails+1)); }

# assert_grep <tag> <file> <extended-regex> <desc>  — regex MUST be present in file
assert_grep() {
  local tag="$1" file="$2" re="$3" desc="$4"
  if [ ! -f "$ROOT/$file" ]; then fail "$tag: file missing: $file"; return; fi
  if grep -Eq -- "$re" "$ROOT/$file"; then pass "$tag: $desc"; else fail "$tag: MISSING in $file — $desc"; fi
}

# assert_absent <tag> <file> <extended-regex> <desc>  — regex MUST NOT be present
assert_absent() {
  local tag="$1" file="$2" re="$3" desc="$4"
  if [ ! -f "$ROOT/$file" ]; then fail "$tag: file missing: $file"; return; fi
  if grep -Eq -- "$re" "$ROOT/$file"; then fail "$tag: STILL PRESENT in $file — $desc"; else pass "$tag: $desc"; fi
}

# guard_footer <what-broke-label> — print the ALL-PRESENT / N-MISSING summary line.
guard_footer() {
  echo "---------------------------------------------"
  if [ "$fails" -eq 0 ]; then
    echo -e "\033[32mALL GUARDS PRESENT\033[0m"
  else
    echo -e "\033[31m$fails GUARD(S) MISSING — ${1:-a guarded fix was removed}\033[0m"
  fi
}
