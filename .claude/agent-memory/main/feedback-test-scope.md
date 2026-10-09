---
name: feedback-test-scope
description: Size QA runs to the change - a small fix gets its targeted test(s) + baseline, not the whole related suite
metadata:
  type: feedback
---

For a small, contained change, run only the tests that exercise it (plus `DEV/tools/dock-baseline.sh` when layout is touched), then commit and push. Don't kick off the 40-50 file related-suite run (30-40 min, long dock fuzz) for every small fix.

**Why:** Rick, 2026-10-08, after a one-rule toolbox-reflow fix was held ~20 min behind a 43-file dock/toolbar/workspace run: "must we test everything on the smallest little change?"

**How to apply:** targeted test(s) + baseline → push → tell him. Save the broad related-suite run for big changes (new subsystems, input routing, render pipeline) or before a PR is first opened / marked ready; offer it rather than run it by default. Never block a push on it for a small fix. See [[qa-harness-toolkit]].

**Rick, 2026-10-09 (again):** "do we need to run these full test suites? seems excessive... if there is a way to be frugal with the testing". Full suite only when the **test geometry itself changes** (a harness pin like `LAYER_PANEL_WIDTH`, the QA config, the harness adapter) - not for refactors. A refactor proven pixel-identical (dock baseline 0 differing + an A/B build comparing old vs new results on every layout) gets its targeted tests only. Say up front when a full run is warranted and why, with an ETA.

**Test dashboard (2026-10-09):** Rick asked to *see* what testing is doing. `./DEV/qa-dash.sh` shows live runs found from /proc (any QA_RESULTS_DIR), ETA from every results dir's history, failure verdicts. When starting a suite: `./DEV/qa-dash.py --target "<why>" <patterns>` so he sees what it must pass; add understood failures to `QA/known-failures.txt` (and remove fixed ones). Tell him the dashboard is the place to watch. See [[qa-harness-toolkit]].
