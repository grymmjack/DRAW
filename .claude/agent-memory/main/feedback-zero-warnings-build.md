---
name: feedback-zero-warnings-build
description: DRAW's compile output must be fully green — zero warnings AND zero infos/notes. Treat any compiler warning (e.g. "Unused variable") as a defect to fix, not accept.
metadata:
  type: feedback
---

DRAW's build must come out **completely clean — no warnings, no infos/notes**, always
green. Rick (2026-09-04): "we don't want any warnings or infos in the compile it should
always be green and clear."

**Why:** a warning-free baseline means any NEW warning stands out immediately; accumulated
"harmless" warnings (unused vars, etc.) hide real regressions and read as unfinished work.

**How to apply:**
- After a full `qb64pe -w -x DRAW.BAS -o DRAW.run`, grep the log for `warning`/`note`/
  `unused` and drive the count to **zero** — fix each (e.g. remove a genuinely unused `DIM`
  var, after confirming it's unused in *its* SUB/FUNCTION, not a same-named var elsewhere).
- New code must add zero warnings. Also keep the qb64pe MCP `lint` (Layer B) clean of real
  errors; its `not-bitwise` / `true-false` INFOS are OK only when verified safe (flags that
  are strictly 0/-1; TRUE/FALSE from `_COMMON.BI`), but prefer refactoring away false-positive
  `self-reference` noise (assign-once-via-local) so the lint signal stays trustworthy.
- Example fixed 2026-09-04: `GUI/IMAGE-ADJ.BM` `IMAGE_ADJ_lightning&` DI'd `dist AS SINGLE`
  but never used it (a `dist!` at ~line 5942 is in a different function) → removed.

[Linux] Observed on Linux; applies to all OSes (same compiler). Related:
[[feedback-lint-not-build]] (lint while iterating, full build to gate).
