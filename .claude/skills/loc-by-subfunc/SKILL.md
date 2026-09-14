---
name: loc-by-subfunc
description: "Count real code LOC (excluding blank + comment lines) per SUB / FUNCTION in one QB64-PE file and print a table sorted descending, biggest routine first."
---

# LOC by Sub/Func Skill

When the user invokes this skill (`/loc-by-subfunc <file>`, "count LOC by
sub/function in X", "which routines in X are biggest", "break down LOC in
MOUSE.BM") produce a table of every `SUB` and `FUNCTION` in that file with its
**body code LOC**, sorted **descending** (biggest routine first), plus a total.

## What it does

Runs the bundled script from the repo root with a single file argument:

```bash
.claude/skills/loc-by-subfunc/loc-by-subfunc.sh OUTPUT/SCREEN.BM
```

It is **read-only**. Pass `--csv` for `loc,kind,name` CSV instead of the table.

Pick the target file however the user described it — if they only named a module
("the mouse pipeline", "SCREEN"), resolve it to the path (`INPUT/MOUSE.BM`,
`OUTPUT/SCREEN.BM`). The companion **loc-by-file** skill lists every path if you
need to find the biggest files first.

## How routines are counted

- A routine opens on a line whose **first token** is `SUB` or `FUNCTION`, and
  closes on `END SUB` / `END FUNCTION`. `DECLARE SUB/FUNCTION`, `EXIT
  SUB/FUNCTION`, and the `END …` line itself are **not** mistaken for openers.
- A routine's **LOC is its body**: the code lines *between* the header and the
  `END` line (neither the header nor the `END` line is counted).
- "Code" excludes blank and comment lines (`'` or `REM`), but `'$` metacommands
  count — identical rule to the **loc-by-file** skill.
- Code outside any routine (declarations in a `.BI`, the main loop / top-level
  code in a `.BAS`) is reported as one **`(module-level)`** row.

QB64-PE forbids nested routines, so no nesting is handled.

## Reading the output

Columns: rank `#`, **LOC** (body code lines), **KIND** (`SUB` / `FUNCTION` /
`MODULE`), and **NAME**. The `TOT` row sums body LOC and counts the routines.

Consistency check: this total plus two lines per routine (each routine's header +
`END` line, which the body count omits) equals that file's `LINES` minus its
comment/blank lines in **loc-by-file** — i.e. the two skills reconcile exactly.
