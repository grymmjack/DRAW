# Dump QA Tests Skill

When the user invokes this skill (`/dump-qa-tests`, "dump the qa tests", "show me
the qa test status by category"), produce a categorized status report of the
DRAW QA suite: every test grouped by category, with how many times it actually
ran, how many passed / failed, when it last ran, its last result, and when it
last passed / failed.

## What it does

Runs the bundled parser, which cross-references `QA/tests/*.sh` (the current test
files) against the full history in `QA/results/run-*.log` (every recorded run):

```bash
python3 .claude/skills/dump-qa-tests/dump-qa-tests.py
```

Run it from the repo root. It auto-locates `QA/` relative to the skill, so the
path argument is optional. Pass through any flags the user asked for.

**It is read-only** — it never launches DRAW and never touches `draw-qa.sh`, so
it is safe to run *while a QA suite is in progress* (it will show the in-flight
run's fresh timestamps as the live log is written).

## Reading the output

Tests are grouped by **category** = the filename prefix before the first `-`
(`layer-merge` → `layer`, `gui-dialog` → `gui`). Each category header shows its
test count, total executions, and how many are failing on their most recent run.

Per-test columns:

| Column | Meaning |
|--------|---------|
| `runs` | times the test actually executed (PASS or FAIL). Cache-skips — where the passed-cache short-circuited it with "already passed" — do **not** count as runs. |
| `pass` / `fail` | lifetime executions of each outcome |
| `last run` | timestamp of the most recent execution (from the `run-YYYYMMDD-HHMMSS.log` name) |
| `result` | outcome of that most recent execution: `pass` / `FAIL` / `never` |
| `last pass` / `last fail` | most recent timestamp of each — a `FAIL` result with an old `last pass` is a regression; a `pass` with a recent `last fail` is a flaky/recently-fixed test |

A `FAIL` in the `result` column (and the red **Failing on last run** footer) is
what to act on — those tests are currently broken. A high `fail` count with a
`pass` result means historically flaky but green now.

## Flags (pass through what the user asks)

| Flag | Effect |
|------|--------|
| *(default)* | only tests present in `QA/tests/` today |
| `--all` | also include removed/experimental tests still in the log history (marked `*` / `(removed)`) |
| `--category NAME` | only that category (e.g. `--category layer`) |
| `--failing` | only tests whose most recent run FAILED |
| `--never` | only current tests that have never actually run |
| `--sort runs\|name\|last` | order within each category (default `name`; `runs` = busiest first; `last` = most-recently-run last) |
| `--no-color` | plain output (use this when capturing to a file or when the terminal mangles ANSI) |

## After showing it

Surface the signal, not just the dump: call out the categories with tests
failing on their last run, and any current test with `runs = 0` (never
exercised). If the user is mid-triage, `--failing` narrows it to exactly the
broken set.
