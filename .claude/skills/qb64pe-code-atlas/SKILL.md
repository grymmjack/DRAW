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

- **C libraries** tab — every `DECLARE LIBRARY` (C interop) compiled into the build,
  the C header/source each binds to, and static-vs-dynamic (static links drive
  QB64-PE's extra pre-compile probe pass). Appears only when the build has FFI.

Everything is client-side sort/filter/search (with a clear-× in the search box);
light+dark themed; no external data. A clickable **color legend** doubles as a filter
(click a chip to jump/filter); **tooltips** on every control, tab, column header, legend
chip and row flag explain each term; and when a GitHub `origin` remote is present, file
paths, directories and routines **link to GitHub** at the exact commit (and line range),
resolving dependency files to the submodule's own repo + pinned SHA.

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
   and `OUT=<path>`. It also writes a machine-readable **navigation sidecar** next
   to the HTML (unless `--no-map`): `code-map.json` and a universal-ctags `tags` file
   (`MAP=… TAGS=…`).

### The code-map.json sidecar (for tools / LLM navigation)

`code-map.json` is a compact index meant to save an LLM (or any tool) from
searching+re-deriving structure. Query it with `jq` instead of grepping the tree:
- `symbols` — every SUB/FUNCTION: `name → {file, line, endline, kind, loc, refs,
  external, dead, byProject, lib}` (definition lookup + size + usage).
- `calls` — best-effort call graph: `caller → [callees]`.
- `callers` — the reverse index: `callee → [callers]`.
- `includes` — the `$INCLUDE` DAG among compiled files.
- `natives` / `libs` — the FFI inventory and dependency summary.

Example: `jq '.callers.SCREEN_render' code-map.json` (who calls it),
`jq '.calls.DRW_load_binary' code-map.json` (what it calls),
`jq '.symbols[]|select(.dead)|.name' code-map.json` (dead-code candidates).
The `tags` file lets editors/agents jump to any definition.

**Caveat (in the file's `meta.caveats`):** it is regex-derived, not a compiler —
call edges can include false positives and miss dispatch-by-id / string-built
names; verify at the definition and regenerate after edits. Both sidecars are
git-ignored by `make atlas`; commit them if you want them always available.
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
