---
name: feedback-test-scope
description: HARD RULE - test only what the change exposes (its targeted tests); never start a multi-file related-suite run unasked. 3rd reminder 2026-10-11
metadata:
  type: feedback
---

**HARD RULE (3rd reminder, 2026-10-11): test only the exposed changes.** Before ANY QA run of more than ~5 test files, stop: say the file count + ETA and ask. Default = the tests that exercise the change (new/updated tests + the ones that directly drive the touched code), then commit + push.

**Rick, 2026-10-11:** after the CURRENT-workspace change had already passed its 4 affected tests (56/56) + the ws unit test, I started a 64-file workspace/dock/menu "regression set" (~1 h): "jeez this is going to take an hour - for one small change like this?!" / "we need you to remember to only test exposed changes, not hours long suites". The 35- and 57-file sets earlier that day were the same mistake.

For a small, contained change, run only the tests that exercise it (plus `DEV/tools/dock-baseline.sh` when layout is touched), then commit and push. Don't kick off the 40-50 file related-suite run (30-40 min, long dock fuzz) for every small fix.

**Why:** Rick, 2026-10-08, after a one-rule toolbox-reflow fix was held ~20 min behind a 43-file dock/toolbar/workspace run: "must we test everything on the smallest little change?"

**How to apply:** targeted test(s) + baseline → push → tell him. Save the broad related-suite run for big changes (new subsystems, input routing, render pipeline) or before a PR is first opened / marked ready; offer it rather than run it by default. Never block a push on it for a small fix. See [[qa-harness-toolkit]].

**Rick, 2026-10-09 (again):** "do we need to run these full test suites? seems excessive... if there is a way to be frugal with the testing". Full suite only when the **test geometry itself changes** (a harness pin like `LAYER_PANEL_WIDTH`, the QA config, the harness adapter) - not for refactors. A refactor proven pixel-identical (dock baseline 0 differing + an A/B build comparing old vs new results on every layout) gets its targeted tests only. Say up front when a full run is warranted and why, with an ETA.

**Test dashboard (2026-10-09):** Rick asked to *see* what testing is doing. `./DEV/qa-dash.sh` (since 2026-10-10 a wrapper over qa-harness `bin/qa-dash`) shows live runs (any QA_RESULTS_DIR; runners register themselves), ETA from every results dir's history, failure verdicts. When starting a suite: `./DEV/qa-dash.sh --target "<why>" <patterns>` so he sees what it must pass; add understood failures to `QA/known-failures.txt` (and remove fixed ones). Tell him the dashboard is the place to watch. See [[qa-harness-toolkit]].
