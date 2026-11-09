#!/usr/bin/env bash
# Writes native/build_info_gen.h (gitignored) with the git info DRAW shows after
# its version on interim builds: "2.7.0 (<short sha> <branch>)". A release build
# - HEAD carries a v* tag - writes "" so it shows the bare version. Run before
# compiling (the Makefile and the CI build do). See native/build_info.h.
set -u
cd "$(dirname "$0")/.." || exit 0
out=native/build_info_gen.h
info=""
if git rev-parse --git-dir >/dev/null 2>&1; then
    sha=$(git rev-parse --short=8 HEAD 2>/dev/null)
    branch=$(git symbolic-ref --short -q HEAD 2>/dev/null)
    [[ -z "$branch" ]] && branch=${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-detached}}
    release=""
    git tag --points-at HEAD 2>/dev/null | grep -qE '^v[0-9]' && release=1
    [[ "${GITHUB_REF_TYPE:-}" == tag && "${GITHUB_REF_NAME:-}" == v[0-9]* ]] && release=1
    [[ -z "$release" && -n "$sha" ]] && info="$sha $branch"
fi
info=${info//\\/}; info=${info//\"/}
new="#define DRAW_BUILD_INFO \"$info\""
[[ -f "$out" && "$(cat "$out")" == "$new" ]] || printf '%s\n' "$new" > "$out"
echo "build info: ${info:-(release)}"
