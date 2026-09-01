---
name: dev-align-tool
description: The QB64-PE source aligner is DEV/align-qb64pe.py (NOT qb64-align.py); how to run it safely for a release
metadata:
  type: reference
---

The source-formatting aligner lives at **`DEV/align-qb64pe.py`** — Rick sometimes
calls it `qb64-align.py`, but that name does not exist; use `align-qb64pe.py`.

Release invocation (Linux, observed 2026-08-31, v2.0.2):

```
python3 ./DEV/align-qb64pe.py --no-backup .
```

- Default mode is **compact**: normalizes inline-comment gaps (min-gap 1 space
  before `'`) and aligns `AS` / `=` / `:` columns within consecutive blocks.
  Whitespace-only — no code semantics change. Flags: `--align-eq`, `--align-as`,
  `--align-case`, `--global`, `--dry-run`, `--min-gap N`. `--dry-run` first to
  scope it (v2.0.2 touched only 9 files / 110 lines).
- `--no-backup` avoids littering `.orig` files that would show in `git status`.
- **Exclude the submodule**: running on `.` also rewrites files under
  `includes/QB64_GJ_LIB/` (a submodule) — revert those with
  `git -C includes/QB64_GJ_LIB checkout <file>` to keep the submodule pristine.
- Commit the align pass **separately** as a `style:` commit (matches 59324da8),
  keeping whitespace churn out of the meaningful release diff.
- QA source-guard tests are whitespace-tolerant on purpose (f00eb804) so they
  survive an align pass. Build still verified clean after aligning.

The PDF manual builder is `./DEV/make-pdf-manual.sh` → writes
`docs/DRAW-Manual.pdf` then moves it to the tracked `DRAW-Manual.pdf` at repo root.
See [[create-release-workflow]] if that memory exists.
