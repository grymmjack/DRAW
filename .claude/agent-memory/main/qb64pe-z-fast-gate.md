---
name: qb64pe-z-fast-gate
description: CORRECTION — `qb64pe -z` is NOT a faster error-gate than `-x`. A qb64pe build is transpile→g++; syntax errors abort during transpile, and `-x` short-circuits there too (never reaching the slow g++). So a FAILING `-x` ≈ a failing `-z` (~100s). For iterative dev just run `-x` (fails as fast on errors + gives a binary). Also: the MCP lint tool's fragment-mode -z is unreliable.
metadata:
  type: reference
---

**[Linux] `qb64pe -z` does NOT speed up catching syntax errors vs `-x`.** (Rick corrected an
earlier wrong claim, 2026-09-04; verified empirically.)

A qb64pe build has two phases: **(1) transpile** BASIC→C++ (the progress-bar phase), then
**(2) g++** compile+link of the generated C++ (the "Compiling C++ code into executable…"
phase — the ~11-min bulk on this ~170k-line project). Key facts:

- **Syntax / reserved-word / string-literal errors are caught in phase 1 (transpile).**
- **`-x` short-circuits at phase 1 on such errors — it never reaches g++.** VERIFIED: every
  failed `-x` build this session (`out`, `""`, `pdf_engine$()`) shows NO "Compiling C++ code
  into executable" line; each aborted during transpile.
- Therefore a **FAILING `-x` ≈ a failing `-z` (~100s here)** — same phase, same time.
- The earlier "`-z` is ~8× faster" was a BAD comparison: a **failed** `-z` (100s, short-circuited
  on the first error at ~76% of transpile) vs a **successful** `-x` (~13min). A CLEAN `-z`
  transpiles the WHOLE project (killed at 5.5 min, still going) — it is NOT ~100s.

**Correct workflow:** for iterative dev, **just run `qb64pe -x DRAW.BAS`.** It fails at
transpile just as fast as `-z` on a syntax error AND produces a runnable binary on success,
so a separate `-z` pre-gate saves nothing and adds a step. `-z` is only worth it for a
**no-binary "does the whole thing transpile" check** (e.g. CI), where skipping g++ on a clean
compile saves ~g++ time. (Still consistent with [[feedback-lint-not-build]]: use the instant
Layer-B regex for the self-reference/reserved-word class while typing; reserve the full `-x`
build for when you need to run/screenshot/test.)

- **The qb64pe MCP `lint` tool's Layer-A `-z` on a `.BM` FRAGMENT is still unreliable** — it
  emitted a spurious "Invalid variable name … `t0 = _UPTIME`" in the untouched `CORE/PERF.BM`,
  which a plain `qb64pe -z DRAW.BAS` does NOT (the tool adds `-w -m -q`; see the MCP repo's
  NOTES.md). And Layer-B's "self-reference SIGSEGV" FALSE-flags every `CASE x : FUNC$ = "..."`
  assignment (those are returns, not recursive reads).

- **Errors the transpile phase catches** (in `-x` or `-z`): `out` collides with the `OUT`
  statement (gotcha #20); `""` is NOT an escaped quote in QB64-PE (use single quotes in HTML
  attrs or `CHR$(34)`); a no-arg `FUNCTION Foo$` is CALLED without parens (`Foo$`, not `Foo$()`).
