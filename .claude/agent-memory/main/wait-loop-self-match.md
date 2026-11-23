---
name: wait-loop-self-match
description: Waiting on a build or test process - never pgrep -f a pattern that appears in the waiting shell's own command line
metadata:
  type: feedback
---

[Linux] A wait loop `while pgrep -f 'qb64pe.*DRAW.BAS -o DRAW.run'; do sleep 5; done` never ends:
the bash running the loop has that text in its own command line, so pgrep finds it forever
(2026-11-21: the user's 1-minute build "took" an hour; Rick asked why, then "fix your wait loop").
The same session's kill helper used `pgrep -f 'DRAW\.run'`, which misses `DRAW-base.run` /
`DRAW-ins.run`, so private test builds were left running on the Xvfb display.

**Why:** pgrep -f matches full command lines, including the waiter's; a too-literal pattern misses
renamed binaries.

**How to apply:** match process names (`pgrep -x qb64pe`, `pgrep -x 'DRAW.*\.run'` - comm is 15
chars max), check make by its cwd (`readlink /proc/PID/cwd`), and wait on the result (binary mtime
>= start time) with a timeout. Better still, run the build/QA itself with run_in_background and let
the exit notification wake you - no loop at all. Kill test instances by DISPLAY in /proc/PID/environ,
never the user's DRAW.
