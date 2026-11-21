#!/usr/bin/env bash
# DEV/check-unused-vars.sh - fail a build that has unused variables.
#
#   DEV/check-unused-vars.sh BUILD_OUTPUT_FILE
#
# Reads a qb64pe -w compile log and exits 1 if it has any "Unused variable"
# warning, after listing them as FILE:LINE NAME TYPE. Rick 2026-11-21: "remove
# all the unused variables... do not allow these in the future." The Makefile
# runs it after every build (and deletes the binary on a failure, so `make run`
# cannot start one), and so does the release workflow on all three OSes: a
# variable used only inside another OS's $IF branch shows up there, not here.
#
# The fix is never to silence the warning: delete the variable, or, if it is
# used only in one OS's $IF block, move its DIM inside that block. An unused
# parameter goes too, with the argument at every call site.
set -u
log=${1:?usage: check-unused-vars.sh BUILD_OUTPUT_FILE}
[[ -f "$log" ]] || { echo "check-unused-vars: no build output at $log" >&2; exit 2; }

# the warning line, then an indented "name   TYPE" line under it
list=$(sed 's/\x1b\[[0-9;]*[A-Za-z]//g; s/\r$//' "$log" | awk '
    /warning: Unused variable/ { split($0, a, ": warning"); loc = a[1]; want = 1; next }
    want && NF { printf "  %s  %s\n", loc, $0; want = 0 }')
[[ -z "$list" ]] && exit 0

n=$(grep -c . <<< "$list")
{
    echo
    echo "ERROR: $n unused variable(s) - DRAW does not allow them (DEV/check-unused-vars.sh):"
    sed -E 's/[[:space:]]+/ /g; s/^ /  /' <<< "$list"
    echo "Delete each one (an unused parameter: also its argument at every call site),"
    echo "or move a DIM used only in one OS's \$IF block inside that block."
} >&2
exit 1
