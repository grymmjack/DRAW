---
name: qa-draw-bin-in-repo
description: A DRAW test build must sit in the repo root to run (it changes to its own folder for ASSETS); from the scratchpad it dies at startup and QA reports window 0x0
metadata:
  type: feedback
---

[Linux, 2026-11-12] DRAW changes its working directory to the folder the executable is in, to
find `ASSETS/`. A build compiled to the scratchpad (`-o $SP/DRAW-x.run`) and run from there -
`DRAW_BIN=$SP/DRAW-x.run ./draw-qa.sh ...` or by hand - finds no assets and stops at include
time: `QB64 runtime error 5 (Illegal function call) in MB-RENDER.BM:48 -- no window is up`
(a startup warning box with no window). The harness then says "window = 0x0 ... refusing to
run". It is not the harness or the environment.

**Why:** cost ~20 minutes of chasing Xvfb / packages / instance registries.

**How to apply:** copy the build into the repo root under a gitignored name before a QA run
(`cp $SP/DRAW-x.run DRAW-swm.run`, `DRAW_BIN=$PWD/DRAW-swm.run`), and delete it when done.
Batch exports (`--export-anim`) of a .draw happen to work from the scratchpad, which hides it.
See [[qa-harness-toolkit]].
