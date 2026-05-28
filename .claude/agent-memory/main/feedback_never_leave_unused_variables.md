---
name: feedback-never-leave-unused-variables
description: "QB64-PE 'Unused variable' warnings must be cleaned up immediately, never left in the codebase — applies to local DIMs AND unused SUB/FUNCTION parameters (remove from signature + all callsites). No 'reserved for future use' free passes."
metadata:
  node_type: memory
  type: feedback
---

**User directive (explicit, 2026-05-28):** "clean up the unused variables. never leave them. i don't want to have to deal with this again."

## The rule

Every QB64-PE `warning: Unused variable` is a defect, not a style nit. Resolve it in the same change that introduces it. Never commit code with unused-variable warnings, even if the build is otherwise clean (`EXIT=0`).

This applies to **both** flavors of the warning:

1. **Local `DIM`** — delete the line. Nothing else references it.
2. **SUB/FUNCTION parameter** — remove from the SUB/FUNCTION signature **and** from every callsite. QB64-PE has no overload resolution; the arity must match. Grep for the symbol name across `.BM` and `.BI` files.

## Why

Warnings accumulate silently. Once there are five, no one reads the warning lines anymore, and a *real* warning (e.g., an actual type-coercion footgun) gets buried in the noise. The user has explicitly rejected the "reserved for future use" pattern as an exception — if a parameter isn't used today, it should not be in the signature today.

## How to apply

After every successful compile, scan the trailing output for `warning: Unused variable`. For each one:

- Note the file:line.
- If it's a local DIM (`DIM x AS ...`), delete the line.
- If it's a parameter, edit the SUB/FUNCTION signature AND every callsite (5 callsites is typical for a dialog widget).
- Recompile to confirm the warning is gone before declaring the task done.

Do not announce the build is "successful with warnings" and move on. That sentence is the failure mode this memory exists to prevent.

## Sibling patterns elsewhere in the codebase

`GUI/DIALOG.BM` has older dialog-widget SUBs (`DIALOG_draw_toggle`, `DIALOG_draw_label`, etc.) that take a `ctx AS DIALOG_CTX` parameter documented as "reserved for future font/scale use." Those predate this directive. If they show up in a future build's warning list and you're touching that area, clean them up too — but don't preemptively churn the file just for that.

Related: [[feedback-draw-compile-convention]], [[feedback-qb64pe-compile-output-capture]].
