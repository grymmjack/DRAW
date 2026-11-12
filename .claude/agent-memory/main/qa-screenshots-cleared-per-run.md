---
name: qa-screenshots-cleared-per-run
description: qa-harness empties results/screenshots at each run - copy a run's shots out before the next run; md-to-pdf can hang on a manual rebuild
metadata:
  type: reference
---

[Linux, 2026-11-12] `~/git/qa-harness/results/screenshots/` holds only the LAST run's shots:
starting another `QA/draw-qa.sh` run empties it. Copy the shots you need (field kits,
reports) to the scratchpad right after the run that made them, or they are gone.
For kit screenshots, a single temporary `QA/tests/zz-kit-shots-*.sh` that drives just the
needed views in one DRAW session is cheaper than re-running every feature test (delete it after).

[Linux, 2026-11-12] `DEV/make-pdf-manual.sh` (md-to-pdf engine) once hung >10 min on a
rebuild that normally takes ~1 min; a retry worked. Wrap it in `timeout 400`.
Related: [[qa-harness-toolkit]]
