---
name: feedback-tests-in-background
description: Always run QA / tests in the background and keep working in the foreground - never sit waiting on a test run
metadata:
  type: feedback
---

Rick 2026-11-18, verbatim: *"always run tests in the background, keep grinding in the foreground. never
ever just wait on a test, if you can do something else."* (Said after I ran a ~15 min QA set in the
foreground / sat on a Monitor until it finished while his other requests were queued.)

**Why:** QA suites take minutes to tens of minutes; Rick usually has a queue of requests, and a blocked
foreground serializes them for nothing.

**How to apply:** start every QA run (`QA/draw-qa.sh ...`) with `run_in_background: true`, then move on
to the next item (code, docs, the next fix) and read the log when the completion notice arrives. Still
obey the hard rules: QA suites run one at a time, and don't rebuild DRAW.run while a suite runs - so
foreground work during a run is editing / reading / docs, and the build waits for the run to end (or use
a separate output binary with `DRAW_BIN=`). Related: [[feedback-parallelize-farm-work]].

**Repeated 2026-11-19** (*"always run tests in the background! never just wait"*), after I broke it twice in
one morning: a 3-test QA re-run sent in the foreground, and a foreground `wait-file.sh` blocking for a farm
host's results. Both count. **No exceptions for "it's only a few tests" or "it's only a wait":** QA runs,
farm waits (`wait-remote-done.sh`, `wait-file.sh`), result collectors all go `run_in_background: true`; the
completion notice wakes me. (Builds are the one foreground job: [[feedback_draw_compile_convention]].)
