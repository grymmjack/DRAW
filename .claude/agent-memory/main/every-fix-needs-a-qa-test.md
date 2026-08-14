---
name: every-fix-needs-a-qa-test
description: Rick's standing rule — every bug fixed must get a QA harness test that guards it
metadata:
  type: feedback
---

**Every bug we fix must get a test in the QA harness.** Rick, 2026-08-14: *"we need more tests — if i'm finding bugs like this we need more tests. every bug we fix i want a test for in the harness."*

**Why:** the volume of shipped regressions means untested fixes keep breaking. A guard test per fix is the safety net.

**How to apply:**
- Add a `QA/tests/<name>.sh` for each fix (see the DRAW adapter conventions in [[qa-harness-toolkit]] and the model test `QA/tests/palette-ops-color-edit.sh`).
- Prove the test actually guards: it must FAIL against the buggy build and PASS against the fixed one (temporarily re-introduce the bug, rebuild, confirm red, restore). This is the standard set in [[gotcha-cp-state-result-clobber]].
- For modal/dialog fixes, drive by keyboard where possible (deterministic) and derive click coords from render constants, not guesses.
- Commit the test alongside the fix.

Backfill tests for fixes that shipped without one when practical.
