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
