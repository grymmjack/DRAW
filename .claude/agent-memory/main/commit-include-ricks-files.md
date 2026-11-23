---
name: commit-include-ricks-files
description: When Rick says "commit and push", include his own modified files (e.g. theme art) too - never leave them out on my own
metadata:
  type: feedback
---

When Rick asks to commit (and push), commit **everything** that is changed, including files he
edited himself (theme PNGs, art, cfg), not only the files I touched. Rick 2026-11-22: "add them,
don't omit them i have them for a reason" - after I had kept his two DARK toolbox PNGs out of
several commits.

**Why:** his changed files are deliberate work he wants in the branch; leaving them out made him
ask again, and they sat uncommitted across several pushes.

**How to apply:** at commit time run `git status`, and stage his changes too (a separate commit
of their own is fine). Leave a file out only if he says so for that commit, and if it looks
unintended (a scratch file, a binary build), ask rather than skip it silently.
