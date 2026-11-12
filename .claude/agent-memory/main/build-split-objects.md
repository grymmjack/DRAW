---
name: build-split-objects
description: A hand-run qb64pe build of DRAW must pass -f:SplitObjectfiles=true (as the Makefile does) - ~33 s instead of ~5 min
metadata:
  type: feedback
---

[Linux, 2026-11-12] Build DRAW with the Makefile's flags, or copy them when building to another
name: `~/git/qb64pe/qb64pe -w -x -f:MaxCompilerProcesses=16 -f:SplitObjectfiles=true DRAW.BAS -o DRAW-swm.run`
took 33 s. Without `-f:SplitObjectfiles=true` (offbyone / mkilgore's compiler work) it is the old
~5 minute single-object build. Rick pointed it out: "if you use make it shouldn't take 5 minutes".

**How to apply:** prefer `make`; for a scratch-named QA build keep both `-f:` flags. The build
still goes in the repo root and is deleted afterwards ([[qa-draw-bin-in-repo]]).
