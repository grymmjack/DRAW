---
name: loc-by-file
description: "Count real code LOC (excluding blank + comment lines) for every QB64-PE source file in DRAW and print a table sorted descending, biggest file first."
---

# LOC by File Skill

When the user invokes this skill (`/loc-by-file`, "count LOC per file", "which
source files are biggest", "lines of code by file") produce a table of every
QB64-PE source file (`*.BAS`, `*.BI`, `*.BM`) with its **code LOC**, sorted
**descending** (most LOC first), plus a grand total.

## What it does

Runs the bundled script from the repo root:

```bash
.claude/skills/loc-by-file/loc-by-file.sh
```

It auto-locates the repo root (via git) so it works from any subdirectory. It is
**read-only** — never launches DRAW, never writes anything.

Source files are discovered with `git ls-files`, so `.gitignore` is respected
and the `includes/QB64_GJ_LIB` **submodule is excluded** by default.

### Options

| Flag / arg | Effect |
|---|---|
| `--include-lib` | also count `includes/QB64_GJ_LIB` (the shared submodule) |
| `--csv` | emit `loc,lines,comments,blank,path` CSV instead of the table |
| `ROOT` (positional) | scan this directory instead of the repo root |

## What counts as "code LOC"

A line is **code** unless, after trimming leading whitespace, it is:

- **blank** (empty), or
- a **comment** — starts with an apostrophe `'` or with `REM` (followed by
  space/tab/EOL).

The one exception: a line starting with `'$` is a **metacommand**
(`'$DYNAMIC`, `'$INCLUDE`, …) — a real directive, so it **counts as code**.
Lines starting with `$` (`$IF`, `$CONSOLE`, `$INCLUDEONCE`) are always code.
Inline trailing comments (`x = 1  ' note`) still count — the line has code.

## Reading the output

Columns: rank `#`, **LOC** (code), **LINES** (physical total), **CMT** (comment
lines), **BLANK**, and **FILE** (repo-relative path). The `TOT` row sums each
column and reports the file count.

`LINES = LOC + CMT + BLANK` for each row, so the gap between LOC and LINES is a
quick read on how comment/whitespace-heavy a file is. To drill into the biggest
file's routines, hand its path to the companion **loc-by-subfunc** skill.
