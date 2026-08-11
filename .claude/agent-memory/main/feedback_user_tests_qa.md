---
name: feedback_user_tests_qa
description: After building, do NOT auto-run QA/smoke tests — the user tests the running app themselves
metadata:
  type: feedback
---

When the user is actively iterating on DRAW (reporting bugs, asking for fixes), **do NOT run the QA harness / smoke tests after a build to "verify"** — the user runs and tests the app themselves and finds auto-running QA intrusive and slow. Build, report what changed, and hand it back for THEM to test.

**Why:** Rick is testing live in his own DRAW session; a QA run spins up a separate DRAW instance, takes minutes, and gets in the way. He said plainly: *"do NOT run the smoke tests i will test."*

**How to apply:** After `make`, just report the changes and stop. Only run QA tests when the user explicitly asks, or for a one-off screenshot/repro they can't easily get themselves (e.g. the Wayland capture path) — and even then, prefer asking first. See [[reference_qa_harness_capture]].
