---
name: feedback-zsh-test-list-splitting
description: In zsh an unquoted $FILES is ONE argument - draw-qa.sh then ran the whole 425-test suite instead of a 67-file list
metadata:
  type: feedback
---

[Linux, zsh] The Bash tool runs zsh, and zsh does not word-split an unquoted
`$VAR`. `FILES=$(ls tests | grep anim ...); ./draw-qa.sh $FILES` passes the whole
list as ONE argument, and the harness falls back to the FULL suite (425 files,
~4 h). `echo $FILES | wc -w` still prints the right count, so nothing looks wrong
until `./DEV/qa-dash.sh --once` shows "n/425". Observed 2026-11-09 (stopped at 7/425).

**Why:** a full-suite run breaks [[feedback-test-scope]] (full suite only overnight)
and ties up DRAW.run for hours, so no rebuilds.

**How to apply:** build a test list in bash with an array:
`bash -c 'mapfile -t F < <(command ls tests | grep -E "anim|group" | sed "s|^|tests/|"); ./draw-qa.sh --rerun-passed "${F[@]}"'`
(or zsh `${=FILES}`). **`mapfile` only works inside `bash -c`**: zsh has no
`mapfile`, so a bare `mapfile -t T < <(...)` leaves `T` empty, `"${T[@]}"` passes
nothing, and the harness runs the FULL suite again - happened 2026-11-11 (474 files,
stopped at 1/474). Literal arrays `T=(tests/a.sh tests/b.sh)` are fine in zsh. Then check the run's `ETA — N test(s)` line, or the dash, within
a minute of starting.

Third time 2026-11-12: `T="a b c"; for t in $T ...; ./draw-qa.sh $(for t in $T; do echo tests/$t.sh; done)`
- the `for` over `$T` loops once in zsh, so the harness got one bogus path and ran all 490
tests (stopped after 13 min). A `"missing ..."` check printed the WHOLE list on one line:
that line is the tell. Wrap the whole command in `bash -c '...'`, and read the
`ETA — N test(s)` line before walking away.

Fourth time 2026-11-16 (unattended task-loop run, xsheet-holds-lanes): `T=$(ls tests | grep ... | sed 's|^|tests/|'); ./draw-qa.sh $T`
ran all 559 tests for ~10 min before I read the log's `ETA — 559` line. Switching to absolute paths
did NOT help (still one argument). The `bash -c` wrapper fixed it (`ETA — 86`). Every hand-built
test list goes inside `bash -c '...'`, no exceptions. A real fix would be in qa-harness
`core/runner.sh` (collect test files): when non-flag args were given but none is a file, abort
instead of falling back to the whole suite. Not done (never edit runner.sh while a run uses it:
bash reads scripts as it goes).

Fifth time 2026-11-17 (farm reruns over ssh): `L="a b c"; T=$(for t in $L; do printf 'tests/%s.sh ' $t; done)`
built in zsh, then sent to mac / thinkpad - one bogus path, both hosts started the FULL 606-test suite.
**Fixed in qa-harness core/runner.sh (2026-11-17, uncommitted in ~/git/qa-harness):** when test
arguments are given but none is a file, it now logs "No such test file: ..." and exits 2 (0.3 s)
instead of running the whole suite. Verified [Linux]: unsplit list aborts, `${=T}` runs 2 tests.
Farm hosts get it on their next qa-harness sync. Build lists as zsh arrays: `L=(a b); T=$(printf 'tests/%s.sh ' $L)`.
**Stopping a farm run** (also 2026-11-17): [macOS] the job runs as `bash ~/.qa-runner/job.sh` under
QA Runner.app - `pkill -f draw-qa.sh` misses it; kill job.sh's tree by pid (`pkill -P <pid>`; the
remote login shell is zsh, so wrap in `bash -c`). [Windows] `schtasks /End /TN qa-runner` leaves
the Git Bash children running - `ps -ef` in Git Bash, kill job.sh / bin/qa pids, `taskkill /F /IM DRAW.exe`.
A run still going writes into a results dir you just recreated (status total N/606 is the tell).
