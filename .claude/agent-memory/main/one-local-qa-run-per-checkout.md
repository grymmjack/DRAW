---
name: one-local-qa-run-per-checkout
description: Never run two QA runs at once from the same DRAW checkout - every DRAW writes the same QA/.dock-dump.txt, so each test reads the other DRAW's dock state (and the second run's DRAW got killed mid-test)
metadata:
  type: feedback
---

[Linux, 2026-11-20] A single anim-lightbox run started beside a 22-test dock batch (both in ~/git/DRAW,
each on its own Xvfb) wrecked both: DOCK_DUMP=QA/.dock-dump.txt is relative to the DRAW root, so both
DRAWs wrote one file - dock-native-pen read "pen hidden" while its own screen showed the pen docked
(looked like a frozen-screen bug), anim-lightbox read "current 0 / panes 0", and the pen test's DRAW
then "died" mid-test.

**Why:** separate Xvfb displays isolate the windows, not the files under QA/ (dump, QA cfg copies,
workspaces dir).

**How to apply:** chain local runs in one background script (or wait on the runner's PID) - one at a
time per checkout. A second run in parallel needs a separate worktree. If a result looks impossible
(dump disagrees with the screenshot), first check nothing else was running. Related:
[[wait-for-qa-run-by-pid]], [[feedback-tests-in-background]].
