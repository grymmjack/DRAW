---
name: qb64pe-code-atlas
description: "Build an interactive LOC & dead-code report (\"Code Atlas\") for any QB64-PE project as a browser artifact — sortable files/routines/directories, dead-code candidates, and a submodule/dependency breakout. Orchestrates the loc-by-file and loc-by-subfunc skills."
---

# QB64-PE Code Atlas Skill

When the user invokes this skill (`/qb64pe-code-atlas`, "build a code atlas",
"make a LOC report / dashboard", "map the codebase size", "find dead code across
the project") produce an **interactive HTML report** and publish it as an Artifact
the user reviews in the browser.

## What it produces

A single self-contained page ("<Project> Code Atlas") with:
- **KPI tiles** — files, code LOC, total lines, comment/blank share, SUBs,
  FUNCTIONs, dead-code candidates, and (if any) dependency LOC.
- **Directory bars** — real code LOC per top-level directory.
- **Files** tab — per-file LOC/lines/comment/blank + a code-**density** meter.
- **Routines** tab — every SUB/FUNCTION by body LOC, with reference counts,
  `large` (≥300 LOC) and `dead?` flags, sortable/filterable, "dead only" toggle.
- **Dead-code candidates** tab — routines referenced 0× outside their own body
  (defined but never called by name), biggest first, with a verify-first caveat.
- **Dependencies** tab — appears when the project has a git submodule (or a
  `--lib` dir) containing QB64-PE source: the files **actually compiled into the
  build** ($INCLUDE-reachable) broken out, with a **By project** column = how many
  times the host project's own code references each dep routine (0 = never called
  directly). Shows included/present counts so you see how much of the submodule is used.

Everything is client-side sort/filter/search; light+dark themed; no external data.
A clickable **color legend** doubles as a filter (click a chip to jump/filter), and
**tooltips** on every control, tab, column header and legend chip explain each term.

## How it works

It **orchestrates the two sibling skills** (which must be installed alongside it):
- `../loc-by-file/loc-by-file.sh --csv <root>` → authoritative per-file code LOC
- `../loc-by-subfunc/loc-by-subfunc.sh <file> --csv` → authoritative per-routine body LOC

then adds a reference / dead-code pass (identifier frequency over comment-stripped
source, excluding each routine's own body) and splices the result into the bundled
`atlas-template.html`.

## Steps

1. **Run the generator from the project root** (foreground; a few seconds):
   ```bash
   python3 .claude/skills/qb64pe-code-atlas/gen-code-atlas.py [ROOT] \
       [--name NAME] [--lib RELPATH]... [--no-auto-lib] \
       [--ignore-dirs DIR,DIR]... [--out FILE]
   ```
   - `ROOT` defaults to the git top-level of the cwd (else cwd).
   - `--name` sets the display name (default: basename of ROOT).
   - Git **submodules are auto-detected** as dependencies; add more with `--lib`
     (repo-relative, repeatable) or disable auto-detect with `--no-auto-lib`.
   - **Dependencies are measured compiled-only:** only the dependency files actually
     reached via `$INCLUDE` from a project entry (a top-level `.BAS`, never the
     dependency's own demo programs) are counted — a submodule usually ships far more
     than a project uses (DRAW compiles 34 of QB64_GJ_LIB's 190 files). The
     Dependencies tab shows *included / present* counts. Pass `--all-dep-files` to
     measure every dependency file instead.
   - `--ignore-dirs` excludes repo-relative path prefixes that aren't part of the
     production build (comma-separated and/or repeated) — e.g. `--ignore-dirs DEV`
     drops experiment/bench sources. Ignored dirs are removed from the report **and**
     the reference corpus, so a routine called only from an ignored dir still reads
     as unused. (DRAW's convention: pass `--ignore-dirs DEV`.)
   - `--out` sets the output `.html` (default `<ROOT>/<NAME>-Code-Atlas.html`);
     **prefer writing to the session scratchpad** so nothing lands in the repo, e.g.
     `--out "$SCRATCHPAD/<NAME>-Code-Atlas.html"`.
   It prints a summary (`files= loc= subs= funcs= dead=`, one line per dependency)
   and `OUT=<path>`.
2. **Publish that OUT file as an Artifact** — `title` = `"<Project> Code Atlas"`,
   `favicon` `📐`, `icon` `chart`. Give the user the URL.
3. Relay the headline numbers and any striking findings (biggest file/routine,
   dead-code count, dependency usage). Re-running later updates the same artifact if
   you publish the same file path in the same conversation, or pass its `url`.

## Requirements & portability

- `python3` (stdlib only) and the `loc-by-file` + `loc-by-subfunc` skills in the
  same `.claude/skills/` directory. `git` is optional (used for the revision label
  and submodule detection; falls back to `find` and `—`).
- **To use on another QB64-PE project:** copy all three skill folders
  (`qb64pe-code-atlas`, `loc-by-file`, `loc-by-subfunc`) into that project's
  `.claude/skills/`, then run the generator with that project as `ROOT`.

## Counting rules (shared with the LOC skills)

Code LOC excludes blank and comment lines (`'` or `REM`) but counts `'$`
metacommands. A routine's LOC is its **body** (header and `END` line excluded).
`Ext` / `By project` = references to the routine's name **outside its own body**;
`Refs` includes internal uses such as a FUNCTION assigning its own return value, so
a high `Refs` with `Ext 0` just means every use is internal.
