---
name: feedback-qb64pe-never-bare
description: Never run the qb64pe binary without -x / -z (it opens the IDE on the user's desktop); it has no --version flag
metadata:
  type: feedback
---

Never run `qb64pe` bare or with unknown flags such as `--version`: it opens the QB64-PE IDE window on the user's desktop (on 2026-11-09 it opened the IDE with a "File not found" error for a file called "--version"). Always pass `-x` (console compile) or `-z` (syntax check). To get the version, read `source/global/version.bas` (`Version$ = "..."`) instead.

**Why:** Rick asked "why did you open this on my screen?" - nothing GUI may appear on his live desktop (see [[qb64pe-mem-errors-critical]] for the crash-dialog case).
**How to apply:** treat every compiler/IDE binary as a GUI program; console only with -x/-z, never "probe" it.
