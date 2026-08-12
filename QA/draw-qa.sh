#!/bin/bash
# draw-qa.sh — DRAW's QA now runs through the standalone qa-harness toolkit:
#   github.com/grymmjack/qa-harness
#
# This is a thin wrapper. It picks the DRAW adapter and forwards every argument
# to the toolkit's runner, so the CLI is unchanged:
#
#   ./draw-qa.sh                    run all DRAW tests (offscreen by default)
#   ./draw-qa.sh tests/smoke.sh     run one/several test files
#   ./draw-qa.sh --onscreen …       drive the real screen (warns + ETA first)
#   ./draw-qa.sh --list | --status | --calibrate T | --pick | --report | --stop
#   ./draw-qa.sh --help             full toolkit help
#
# The harness implementation (ported from this script's own history — see git
# before 2026-08-12) lives in the toolkit: core/ + drivers/linux-x11/ +
# adapters/draw/. DRAW's tests in QA/tests/*.sh run unchanged.
#
# Requires the toolkit checked out. Default location ~/git/qa-harness; override
# with QA_HARNESS=/path/to/qa-harness.
set -u

QA_HARNESS="${QA_HARNESS:-$HOME/git/qa-harness}"
# Tell the DRAW adapter which DRAW checkout to use (this one), so the toolkit
# isn't pinned to a single path.
DRAW_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DRAW_ROOT

if [[ ! -x "$QA_HARNESS/bin/qa" ]]; then
    echo "draw-qa: qa-harness toolkit not found at: $QA_HARNESS" >&2
    echo "  clone it:   git clone git@github.com:grymmjack/qa-harness.git \"$QA_HARNESS\"" >&2
    echo "  or set:     QA_HARNESS=/path/to/qa-harness ./draw-qa.sh ..." >&2
    exit 2
fi

exec "$QA_HARNESS/bin/qa" --adapter "$QA_HARNESS/adapters/draw" "$@"
