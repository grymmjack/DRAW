---
name: wait-for-qa-run-by-pid
description: To wait for a local QA run before starting another, wait on its xvfb-run PID - pgrep -f on "draw-qa.sh ..." never matches (it execs into qa-harness bin/qa) and \| is a literal | in pgrep's ERE
metadata:
  type: feedback
---

[Linux] Never start a second local QA run until the first has really ended: two runs at
once share qa-harness/results (and kill each other's DRAW). 2026-11-19 a wait loop
`while pgrep -f "draw-qa.sh --rerun-passed tests/a\|tests/b"` returned at once, the second
run started beside the first, and both came back with false failures (a dead DRAW, a dock
move that never happened). Two faults:
- `draw-qa.sh` execs into `qa-harness/bin/qa --adapter ...`, so no process has
  "draw-qa.sh" in its args once it is running.
- pgrep uses ERE: `\|` is a literal `|`; alternation is a bare `|`.

**Why:** the contaminated results cost a round of false triage (a "crash" that was the
other run's cleanup).

**How to apply:** take the PID of the run's `xvfb-run` (or `bin/qa`) from
`ps -eo pid,args` and loop `while kill -0 $PID`. Or `pgrep -x xvfb-run` (by process name). Any `pgrep -f "<pattern>"` can match the
very shell running it - its args hold the pattern, even inside a sed you ran in the
same command (the `[q]a-...` trick does not save you then). Better, chain dependent runs in ONE
background script so the second starts when the first command returns. Check
`ps -eo pid,etime,args | grep -E 'bin/qa|xvfb-run'` before launching anything locally.
Related: [[feedback-tests-in-background]]
