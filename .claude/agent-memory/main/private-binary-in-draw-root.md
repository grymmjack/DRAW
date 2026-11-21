---
name: private-binary-in-draw-root
description: [Linux] A private test build of DRAW must live in the DRAW root (DRAW-*.run, gitignored) - DRAW chdirs to its exe dir, so a binary in the scratchpad finds no ASSETS and dies "runtime error 5 MB-RENDER.BM:48 no window"
metadata:
  type: feedback
---

[Linux, 2026-11-20] DRAW changes its working directory to the folder its executable is in, then loads
ASSETS/ relative to it. A build put in the session scratchpad (`-o $S/DRAW-t.run`) started, found no
assets, and died at MB-RENDER.BM:48 ("no window"), which looked like a code bug.

**Why:** the full suite on the farm and Rick's own DRAW.run must not be rebuilt under a running
QA run, so fixes are tested with a second binary.

**How to apply:** `qb64pe ... DRAW.BAS -o DRAW-f.run` in ~/git/DRAW (DRAW-*.run is gitignored), then
`DRAW_BIN=$HOME/git/DRAW/DRAW-f.run QA_RESULTS_DIR=$S/x ./draw-qa.sh --rerun-passed tests/...`.
One qb64pe build at a time. Related: [[feedback-tests-in-background]].
