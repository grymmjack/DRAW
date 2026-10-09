---
name: feedback-test-scope
description: Size QA runs to the change - a small fix gets its targeted test(s) + baseline, not the whole related suite
metadata:
  type: feedback
---

For a small, contained change, run only the tests that exercise it (plus `DEV/tools/dock-baseline.sh` when layout is touched), then commit and push. Don't kick off the 40-50 file related-suite run (30-40 min, long dock fuzz) for every small fix.

**Why:** Rick, 2026-10-08, after a one-rule toolbox-reflow fix was held ~20 min behind a 43-file dock/toolbar/workspace run: "must we test everything on the smallest little change?"

**How to apply:** targeted test(s) + baseline → push → tell him. Save the broad related-suite run for big changes (new subsystems, input routing, render pipeline) or before a PR is first opened / marked ready; offer it rather than run it by default. Never block a push on it for a small fix. See [[qa-harness-toolkit]].
