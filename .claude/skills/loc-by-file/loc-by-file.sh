#!/usr/bin/env bash
# =============================================================================
# loc-by-file.sh — count real code LOC per QB64-PE source file and print a table
# sorted DESCENDING (most LOC first).
#
# "Code LOC" excludes blank lines and comment-only lines. In QB64-PE a comment
# line starts (after leading whitespace) with an apostrophe (') or `REM` — BUT a
# line starting with '$ is a METACOMMAND ('$DYNAMIC, '$INCLUDE, ...), which is a
# real directive and counts as code. Inline trailing comments (`x = 1  ' note`)
# still count: the line contains code.
#
# Read-only. Never launches DRAW. Source files = tracked *.BAS *.BI *.BM
# (via `git ls-files`, so .gitignore is respected and the QB64_GJ_LIB submodule
# is excluded — add it with --include-lib).
#
# Usage:
#   .claude/skills/loc-by-file/loc-by-file.sh [--include-lib] [--csv] [ROOT]
#     --include-lib   also count includes/QB64_GJ_LIB (the shared submodule)
#     --csv           emit CSV (loc,lines,comments,blank,path) instead of a table
#     ROOT            scan this dir instead of the repo root (optional)
# =============================================================================
set -euo pipefail

INCLUDE_LIB=0
CSV=0
ROOT=""
while [ $# -gt 0 ]; do
    case "$1" in
        --include-lib) INCLUDE_LIB=1 ;;
        --csv)         CSV=1 ;;
        -h|--help)     sed -n '2,22p' "$0"; exit 0 ;;
        -*)            echo "loc-by-file: unknown option: $1" >&2; exit 2 ;;
        *)             ROOT="$1" ;;
    esac
    shift
done

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "$ROOT" ]; then
    ROOT="$(git -C "$SKILL_DIR" rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
cd "$ROOT"

# ── Gather source files (NUL-safe) ───────────────────────────────────────────
files=()
if git rev-parse >/dev/null 2>&1; then
    while IFS= read -r -d '' f; do files+=("$f"); done \
        < <(git ls-files -z '*.BAS' '*.bas' '*.BI' '*.bi' '*.BM' '*.bm')
else
    while IFS= read -r -d '' f; do files+=("$f"); done \
        < <(find . -type f \( -name '*.BAS' -o -name '*.bas' -o -name '*.BI' \
              -o -name '*.bi' -o -name '*.BM' -o -name '*.bm' \) \
              -not -path './.git/*' -print0)
fi
if [ "$INCLUDE_LIB" -eq 1 ] && [ -d includes/QB64_GJ_LIB ]; then
    while IFS= read -r -d '' f; do files+=("$f"); done \
        < <(find includes/QB64_GJ_LIB -type f \( -name '*.BAS' -o -name '*.bas' \
              -o -name '*.BI' -o -name '*.bi' -o -name '*.BM' -o -name '*.bm' \) \
              -not -path '*/.git/*' -print0)
fi

if [ "${#files[@]}" -eq 0 ]; then
    echo "loc-by-file: no *.BAS/*.BI/*.BM source files found under: $ROOT" >&2
    exit 1
fi

# ── Count per file, then sort descending and render ──────────────────────────
# awk reads the files as ARGUMENTS (default newline RS) and flushes one
# TAB-separated record per file at each file boundary: loc<TAB>lines<TAB>cmt<TAB>blank<TAB>path
awk '
    BEGIN { SQ = sprintf("%c", 39) }                 # 39 = apostrophe
    function iscode(line,   t, low) {
        t = line
        sub(/^[ \t]+/, "", t)                         # ltrim
        if (t == "")            return 0              # blank
        if (substr(t,1,1) == SQ) {                    # starts with apostrophe
            if (substr(t,2,1) == "$") return 1        #   '"'"'$ metacommand = code
            return 0                                   #   plain comment
        }
        low = tolower(t)
        if (low == "rem")                    return 0
        if (substr(low,1,4) == "rem ")       return 0
        if (substr(low,1,3) == "rem" && substr(t,4,1) ~ /[ \t]/) return 0
        return 1
    }
    function emit() { printf "%d\t%d\t%d\t%d\t%s\n", loc, lines, cmt, blank, file }
    FNR == 1 { if (seen) emit(); seen = 1; file = FILENAME; loc = 0; lines = 0; cmt = 0; blank = 0 }
    {
        lines++
        if (iscode($0)) { loc++ }
        else {
            b = $0; sub(/^[ \t]+/, "", b)
            if (b == "") blank++; else cmt++
        }
    }
    END { if (seen) emit() }
' "${files[@]}" \
| sort -t$'\t' -k1,1rn -k5,5 \
| awk -F'\t' -v csv="$CSV" '
    BEGIN {
        if (csv) print "loc,lines,comments,blank,path"
    }
    {
        loc=$1; lines=$2; cmt=$3; blank=$4; path=$5
        rank++
        tloc+=loc; tlines+=lines; tcmt+=cmt; tblank+=blank
        if (csv) { printf "%d,%d,%d,%d,%s\n", loc, lines, cmt, blank, path; next }
        rows[rank] = sprintf("%4d  %7d  %7d  %6d  %6d   %s", rank, loc, lines, cmt, blank, path)
    }
    END {
        if (csv) exit
        printf "%-4s  %7s  %7s  %6s  %6s   %s\n", "#", "LOC", "LINES", "CMT", "BLANK", "FILE"
        printf "%s\n", "----  -------  -------  ------  ------   ----------------------------------"
        for (i = 1; i <= rank; i++) print rows[i]
        printf "%s\n", "----  -------  -------  ------  ------   ----------------------------------"
        printf "%-4s  %7d  %7d  %6d  %6d   %d files  (LOC = code, excl. blank+comment)\n", \
               "TOT", tloc, tlines, tcmt, tblank, rank
    }
'
