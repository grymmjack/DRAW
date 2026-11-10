---
name: feedback-keep-old-tester-builds
description: Never delete old testers-* pre-releases, and don't offer to - testers may still be on them and reporting bugs
metadata:
  type: feedback
---

Keep every old `testers-*` GitHub pre-release. Don't delete them, and don't offer to when making
a new one (the create-testers-release skill's cleanup offer doesn't apply in this repo).

**Why:** Rick 2026-11-10: "don't delete the old stuff just in case others are using and found
bugs" - a tester's report has to match a build that still exists.

**How to apply:** when publishing a new tester build, leave earlier ones alone and say nothing
about cleaning up. Delete one only if Rick asks for that specific build.
