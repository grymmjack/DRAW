---
description: Prepare a DRAW release — bump version, update docs, generate release notes
---

# Release Skill

When the user invokes this skill (e.g. "do a release", "prep a release", "release skill"), execute the following steps **in order**. Do not skip steps. Do not batch steps that require user input.

---

## Step 1 — Determine version bump

Ask the user:

> "Is this a **major**, **minor**, or **patch** release?"
> (major = breaking/large new features, minor = new features, patch = bug fixes / polish)

Parse the current version from `_COMMON.BI`:
```
CONST APP_VERSION$ = "X.Y.Z"
```

Compute the new version:
- **major** → `(X+1).0.0`
- **minor** → `X.(Y+1).0`
- **patch** → `X.Y.(Z+1)`

Show the user: `Current: X.Y.Z → New: A.B.C` and confirm before proceeding.

---

## Step 2 — Collect changes

Run:
```bash
git log --oneline --no-merges $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD
```

If no tags exist, compare against the very first commit.

Also review the **current conversation history** (the chat context above this message) for any features, fixes, or changes discussed and implemented during this session that may not yet be in git log (e.g. uncommitted work).

Produce a deduplicated, categorised list of changes:
- **New Features** — new tools, behaviours, UX additions
- **Improvements** — refinements to existing features
- **Bug Fixes** — defects corrected
- **Internal / Refactoring** — theme system, file structure, architecture changes (not user-facing)
- **Breaking Changes** — anything that changes file formats, config keys, or hotkeys

---

## Step 3 — Update `_COMMON.BI`

In `_COMMON.BI`, replace:
```qb64
CONST APP_VERSION$ = "X.Y.Z"
```
with:
```qb64
CONST APP_VERSION$ = "A.B.C"
```

---

## Step 4 — Update `CHEATSHEET.md`

Review `CHEATSHEET.md` against the collected changes list from Step 2.

For each change that affects keyboard shortcuts, hotkeys, mouse behaviour, tool names, or controls:
- Add missing entries
- Update changed entries
- Remove entries for removed features

Preserve the existing formatting and table structure. Only edit sections that need updating.

---

## Step 5 — Update `README.MD`

Review `README.MD` against the collected changes list from Step 2.

Update:
- The version badge / header if present
- Feature bullet lists (add new features, update changed ones, remove removed ones)
- The screenshot if the GUI has visually changed significantly (note only — do not replace automatically)
- Do not rewrite sections that are still accurate

---

## Step 6 — Update `copilot-instructions.md`

Review `.github/instructions/copilot-instructions.md` against the collected changes list from Step 2.

Update sections that are now inaccurate or incomplete:
- Architecture / directory structure changes
- New gotchas or updated gotchas
- New systems (theme, font, etc.)
- Updated action ID tables
- Updated file lists

Only edit what has changed. Do not rewrite accurate content.

---

## Step 7 — Compile verification

Run the build to confirm the version bump and all doc changes haven't introduced any issues:
```bash
cd /home/grymmjack/git/DRAW && /home/grymmjack/git/qb64pe/qb64pe -w -x DRAW.BAS -o DRAW.run 2>&1 | tail -5
```

Confirm `Output: .../DRAW.run` appears. Report any errors and fix before continuing.

---

## Step 8 — Output release notes in chat

Print the following markdown block in chat so the user can copy it directly to GitHub Releases:

---

```markdown
## DRAW vA.B.C

> Released YYYY-MM-DD

### New Features
- ...

### Improvements
- ...

### Bug Fixes
- ...

### Internal / Refactoring
- ...

### Breaking Changes
- ...

### Build
- QB64-PE v4.x required
- Build: `qb64pe -w -x DRAW.BAS -o DRAW.run`
```

---

## Rules

- **Always ask** before applying a version bump (Step 1). Never assume.
- **Never auto-commit**. The user will commit and tag manually.
- If a step produces no changes (e.g. CHEATSHEET.md is already accurate), state that explicitly and move on.
- If the git log is empty (no commits since last tag), say so and rely entirely on the conversation history for the change list.
- Keep release notes **user-facing**: omit internal refactors unless they affect users (file format changes, config key renames, etc.).
- Date in release notes should be today's date in `YYYY-MM-DD` format.
