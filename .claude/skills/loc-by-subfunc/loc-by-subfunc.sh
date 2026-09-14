#!/usr/bin/env bash
# =============================================================================
# loc-by-subfunc.sh — count real code LOC per SUB / FUNCTION in ONE QB64-PE file
# and print a table sorted DESCENDING (biggest routine first).
#
# "Code LOC" excludes blank lines and comment-only lines (apostrophe / REM),
# but counts '$ metacommands as code — same rule as loc-by-file.sh. A routine's
# LOC is its BODY: the code lines BETWEEN the `SUB`/`FUNCTION` header and its
# `END SUB`/`END FUNCTION` (header and END line themselves are not counted).
# Code that lives outside any routine (declarations in a .BI, the main loop in a
# .BAS) is reported as one "(module-level)" row.
#
# Not fooled by DECLARE SUB/FUNCTION, EXIT SUB/FUNCTION, or END SUB/FUNCTION —
# only a line whose FIRST token is SUB or FUNCTION opens a routine. QB64-PE does
# not allow nested routines, so no nesting is handled.
#
# Read-only. Usage:
#   .claude/skills/loc-by-subfunc/loc-by-subfunc.sh <file.BM|.BI|.BAS> [--csv]
# =============================================================================
set -euo pipefail

CSV=0
FILE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --csv)     CSV=1 ;;
        -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
        -*)        echo "loc-by-subfunc: unknown option: $1" >&2; exit 2 ;;
        *)         FILE="$1" ;;
    esac
    shift
done

if [ -z "$FILE" ]; then
    echo "loc-by-subfunc: need a file argument (a .BM/.BI/.BAS source file)" >&2
    exit 2
fi
if [ ! -f "$FILE" ]; then
    echo "loc-by-subfunc: not a file: $FILE" >&2
    exit 1
fi

awk -v csv="$CSV" -v fname="$FILE" '
    BEGIN { SQ = sprintf("%c", 39); inblock = 0; modloc = 0; n = 0 }
    function iscode(line,   t, low) {
        t = line
        sub(/^[ \t]+/, "", t)
        if (t == "")            return 0
        if (substr(t,1,1) == SQ) {
            if (substr(t,2,1) == "$") return 1
            return 0
        }
        low = tolower(t)
        if (low == "rem")                    return 0
        if (substr(low,1,4) == "rem ")       return 0
        if (substr(low,1,3) == "rem" && substr(t,4,1) ~ /[ \t]/) return 0
        return 1
    }
    {
        raw = $0
        t = raw; sub(/^[ \t]+/, "", t)
        low = tolower(t)

        # ── open a routine? (first token SUB or FUNCTION) ────────────────────
        if (!inblock && (substr(low,1,4) == "sub " || substr(low,1,9) == "function ")) {
            inblock = 1; loc = 0
            if (substr(low,1,4) == "sub ") kind = "SUB"; else kind = "FUNCTION"
            rest = t
            sub(/^[A-Za-z]+[ \t]+/, "", rest)         # drop the keyword
            if (match(rest, /[ \t(]/)) name = substr(rest, 1, RSTART - 1)
            else                       name = rest
            if (name == "") name = "(anonymous)"
            next                                       # header not counted in body
        }

        # ── close a routine? (END SUB / END FUNCTION) ────────────────────────
        if (inblock && substr(low,1,4) == "end " ) {
            rest = low; sub(/^end[ \t]+/, "", rest)
            if (rest == "sub" || rest == "function" || \
                substr(rest,1,4) == "sub " || substr(rest,1,9) == "function ") {
                n++; order[n] = name; kindof[n] = kind; bodyloc[n] = loc
                inblock = 0
                next
            }
        }

        # ── ordinary line ────────────────────────────────────────────────────
        if (iscode(raw)) { if (inblock) loc++; else modloc++ }
    }
    END {
        # unterminated routine (malformed file) — still report what we have
        if (inblock) { n++; order[n] = name "(unterminated)"; kindof[n] = kind; bodyloc[n] = loc }

        if (csv) {
            print "loc,kind,name"
            if (modloc > 0) printf "%d,%s,%s\n", modloc, "MODULE", "(module-level)"
            for (i = 1; i <= n; i++) printf "%d,%s,%s\n", bodyloc[i], kindof[i], order[i]
            exit
        }

        # Build a flat list (module-level + routines), then sort desc by LOC.
        m = 0
        if (modloc > 0) { m++; L[m] = modloc; K[m] = "MODULE"; NM[m] = "(module-level)" }
        for (i = 1; i <= n; i++) { m++; L[m] = bodyloc[i]; K[m] = kindof[i]; NM[m] = order[i] }

        # simple insertion sort (files have hundreds of routines at most)
        for (i = 2; i <= m; i++) {
            lv = L[i]; kv = K[i]; nv = NM[i]; j = i - 1
            while (j >= 1 && L[j] < lv) { L[j+1]=L[j]; K[j+1]=K[j]; NM[j+1]=NM[j]; j-- }
            L[j+1]=lv; K[j+1]=kv; NM[j+1]=nv
        }

        printf "File: %s\n\n", fname
        printf "%-4s  %7s  %-9s  %s\n", "#", "LOC", "KIND", "NAME"
        printf "%s\n", "----  -------  ---------  --------------------------------------------"
        tot = 0; nsub = 0; nfun = 0
        for (i = 1; i <= m; i++) {
            printf "%4d  %7d  %-9s  %s\n", i, L[i], K[i], NM[i]
            tot += L[i]
            if (K[i] == "SUB") nsub++; else if (K[i] == "FUNCTION") nfun++
        }
        printf "%s\n", "----  -------  ---------  --------------------------------------------"
        printf "%-4s  %7d  %-9s  %d SUB + %d FUNCTION%s\n", "TOT", tot, "", \
               nsub, nfun, (modloc > 0 ? " + module-level" : "")
        printf "\n(LOC = code lines in each routine BODY; excludes blank + comment lines)\n"
    }
' "$FILE"
