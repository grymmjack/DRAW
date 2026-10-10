#!/usr/bin/env bash
# qa-dash.sh - the live QA test dashboard: qa-harness's bin/qa-dash with DRAW's
# settings (tests, known failures, target). Sibling of dash.sh.
#   ./DEV/qa-dash.sh [SECONDS]          interactive, refresh every SECONDS (default 3)
#   ./DEV/qa-dash.sh --once             one snapshot
#   ./DEV/qa-dash.sh --plan 'dock-'     tests matching a regex: last results + time estimate
#   ./DEV/qa-dash.sh --target "TITLE" PATTERN...   /   --target-clear
DRAW_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
H="${QA_HARNESS:-$HOME/git/qa-harness}"
[[ -x "$H/bin/qa-dash" ]] || { echo "qa-harness not found at $H (set QA_HARNESS)" >&2; exit 1; }
args=()
if [[ "${1:-}" =~ ^[0-9.]+$ ]]; then args=(--watch "$1"); shift; fi
exec "$H/bin/qa-dash" --title "DRAW QA" --tests-dir "$DRAW_ROOT/QA/tests" \
    --known "$DRAW_ROOT/QA/known-failures.txt" --target-file "$DRAW_ROOT/.claude/qa-target.txt" \
    --hint "Start one with QA/draw-qa.sh (or DEV/farm-check.sh qa HOST)." "${args[@]}" "$@"
