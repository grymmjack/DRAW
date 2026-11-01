---
name: feedback-parallelize-farm-work
description: Run independent farm/host work in parallel - don't wait on one machine's run before starting work on another
metadata:
  type: feedback
---

Don't hold independent work behind an unrelated wait. 2026-10-10, while a Mac test run was going, I queued
the titan / daw compiler rebuilds "after" it; Rick: *"go ahead with the updates on the others - why wait?"*

**Why:** the farm hosts are independent machines; waiting on one serializes hours of work for nothing, and
Rick is often watching in real time.

**How to apply:** when a step on one host is running (suite, build), start every step on OTHER hosts that
does not depend on it right away, as parallel background jobs. Only one thing per host's screen at a time
(onscreen QA on mac / thinkpad), and never edit a harness copy on a host while that host runs a suite.
See [[qa-harness-toolkit]].
