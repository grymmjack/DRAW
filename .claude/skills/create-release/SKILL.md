---
name: create-release
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

Also check **merged pull requests** since the last tag to capture feature-chunk descriptions:

```bash
gh pr list --repo grymmjack/DRAW --state merged --limit 20 --json number,title,body,mergedAt,headRefName --jq '.[] | "PR #\(.number): \(.title) | Branch: \(.headRefName) | Merged: \(.mergedAt[0:10])\n\(.body)\n---"'
```

Filter to only PRs merged **after** the last tag date (`git log --format="%ci" -1 <tag>`). PR descriptions often contain richer change details than commit messages — use them to supplement the git log.

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

## Step 4 — Update `SHORTCUTS.md`

Review `SHORTCUTS.md` (the canonical keyboard + mouse reference; `CHEATSHEET.md` is only a redirect stub — leave it) against the collected changes list from Step 2.

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

## Step 6 — Update instruction files

Review each file in `.claude/instructions/` against the collected changes list from Step 2. Update only the files affected by this release — skip files whose content is still accurate.

| File                  | Update when…                                                                                                                                    |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `draw-project.md`     | Architecture changes, new directories, new/changed gotchas, new tools in key files table, updated adding-tools checklist, new QB64-PE APIs used |
| `draw-undo.md`        | Undo system changes, new undo callers, new bug patterns                                                                                         |
| `draw-rendering.md`   | Render pipeline step changes, new blend modes, layer type field changes, cache invalidation rule changes                                        |
| `draw-mouse.md`       | `MOUSE_OBJ` field additions, new `DEFERRED_ACTION%` values, processing flow changes                                                             |
| `draw-ui.md`          | New action IDs or ranges, new menu items, toolbar row/column layout changes, new organizer slots                                                |
| `draw-sound.md`       | New sound constants, new playback wiring, new config keys, music system changes                                                                 |
| `draw-fileformat.md`  | New `.draw` binary sections or version bump, new config fields, new theme fields                                                                |

For each file that needs updating:

- Add missing entries
- Update changed entries
- Remove entries for removed features
- Preserve existing formatting and table structure
- Only edit sections that need updating

---

## Step 7 — Compile verification

Run the build to confirm the version bump and all doc changes haven't introduced any issues:

```bash
cd /home/grymmjack/git/DRAW && /home/grymmjack/git/qb64pe/qb64pe -w -x DRAW.BAS -o DRAW.run 2>&1 | tail -5
```

Confirm `Output: .../DRAW.run` appears, then run `DEV/check-unused-vars.sh` on that build output (the
release CI fails on any unused variable). Report any errors and fix before continuing. This checks the
**Linux** build only - Step 9 has CI build macOS and Windows before anything is tagged.

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

```

---

## Step 9 — Commit, tag, push, and publish the notes

Rick trusts this step to the skill (2026-11-06: "that should be part of this release skill").

1. Save the Step 8 notes to a scratchpad file (e.g. `release-notes-A.B.C.md`).
2. Commit the release changes (version bump + docs) on `main`:
   `Release A.B.C: <short summary>`, with the attribution trailer. Push `main` - **not the tag yet**.
3. **Build all three platforms in CI before tagging.** A local build is Linux only: code inside a
   `$IF WIN` / `$IF MAC` block, or a variable only another OS's code uses, compiles here and fails
   there. (2.10.0: the macOS and Windows builds failed `check-unused-vars` after the tag was pushed,
   so the tag had to be deleted and moved to the fix.) Run the release workflow by hand on `main`,
   without creating a release, and wait for it in the background:
   ```bash
   gh workflow run build-release.yml --repo grymmjack/DRAW --ref main -f create_release=false
   gh run list --repo grymmjack/DRAW --workflow build-release.yml --limit 1   # its run id
   # poll every 30 s: gh run view <id> --json status,conclusion
   ```
   Every job (`build-linux`, `build-macos`, `build-windows`) must be `success`; `Create Release` shows
   `skipped`. If one fails, read `gh run view <id> --log-failed`, fix it on `main`, commit, push and run
   this step again. Tag only the commit that passed.
4. Annotated tag on that commit + push:
   ```bash
   git tag -a vA.B.C -m "DRAW vA.B.C"
   git push origin vA.B.C
   ```
5. **Don't `gh release create`.** The tag push starts `.github/workflows/build-release.yml`, which builds
   Linux / Windows / macOS (~5 min) and creates the release itself (assets `DRAW-lnx-x64.tar.gz`,
   `DRAW-osx-x64.tar.gz`, `DRAW-win-x64.zip`) with GitHub's auto-generated notes.
6. Watch in the background: find the run with
   `gh run list --repo grymmjack/DRAW --workflow build-release.yml --limit 1`, then poll every 30 s
   until `gh release view vA.B.C --json isDraft` says `false` (stop and report if the run concludes
   anything but `success`). Then replace the notes and title:
   ```bash
   gh release edit vA.B.C --repo grymmjack/DRAW --title "DRAW vA.B.C" --notes-file release-notes-A.B.C.md
   ```
7. Check the result (`gh release view vA.B.C --json name,body,assets,url`) and give the user the URL.

---

## Rules

- **Always ask** before applying a version bump (Step 1). Never assume.
- **Commit, tag and push only in Step 9**, after the build passes and the notes are shown, never earlier.
- **Never push the tag before the CI build of all three platforms passed** (Step 9.3).
- If a step produces no changes (e.g. CHEATSHEET.md is already accurate), state that explicitly and move on.
- If the git log is empty (no commits since last tag), say so and rely entirely on the conversation history for the change list.
- Keep release notes **user-facing**: omit internal refactors unless they affect users (file format changes, config key renames, etc.).
- Date in release notes should be today's date in `YYYY-MM-DD` format.
