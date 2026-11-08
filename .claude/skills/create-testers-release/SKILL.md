---
name: create-testers-release
description: Build downloadable Linux / macOS / Windows packages of a DRAW feature branch in CI and publish them as a GitHub PRE-release for testers (never marked Latest), with tester notes - how to run on each OS, what to test, how to report. Use when the user says "/create-testers-release", "testers build", "build binaries for this branch", "give a tester a build", or wants to share a branch with someone who will not compile it.
---

# Create a testers release

Turns any pushed branch into a public GitHub **pre-release** with the same three
packages a real release has (`DRAW-lnx-x64.tar.gz`, `DRAW-osx-x64.tar.gz`,
`DRAW-win-x64.zip`), built by `.github/workflows/build-release.yml` from the
branch's own commit. A pre-release is never marked Latest, so the v2.x download
people get from the repo page does not change.

For a real versioned release use `/create-release` instead.

Argument: the branch (default: the current branch). Optional: a field kit URL or
notes to include.

---

## Step 1 - Preflight (stop and report if any fails)

```bash
B=${BRANCH:-$(git branch --show-current)}
git fetch -q origin
gh auth status                                     # needs repo + workflow scopes
test "$B" != main                                   # main -> /create-release
git status --porcelain --untracked-files=no         # uncommitted tracked changes: ask first
test "$(git rev-parse "$B")" = "$(git rev-parse "origin/$B")"   # pushed?
git show "origin/$B:.github/workflows/build-release.yml" | grep -q 'prerelease:'
```

- **The last check matters:** `workflow_dispatch` runs the workflow file *from the
  branch it is run on*. A branch cut before the `prerelease` input was added
  (2026-11-08) rejects `-f prerelease=true` ("Unexpected inputs"). Fix by merging
  or cherry-picking that workflow change onto the branch - ask the user first.
- If the QB64_GJ_LIB submodule has commits that are not pushed, CI cannot check
  them out: `git -C includes/QB64_GJ_LIB status -sb` must not say "ahead".
- Tell the user, in one line, that the pre-release is **public** (the repo is).

## Step 2 - Name it

```bash
SHA=$(git rev-parse --short=7 "origin/$B")
TAG="testers-$(echo "$B" | tr -c 'A-Za-z0-9\n' '-')-$(date +%Y%m%d)-$SHA"
gh release view "$TAG" >/dev/null 2>&1 && echo "exists"   # same commit already built: reuse it
```

Never use a `v*.*.*` name: those are the real release tags.

## Step 3 - Build (about 5 minutes)

```bash
gh workflow run build-release.yml --ref "$B" \
    -f create_release=true -f prerelease=true -f tag="$TAG"
sleep 5
RUN=$(gh run list --workflow build-release.yml --branch "$B" --event workflow_dispatch \
      --limit 5 --json databaseId,headSha -q ".[] | select(.headSha | startswith(\"$SHA\")) | .databaseId" | head -1)
gh run watch "$RUN" --exit-status        # run in the background; you are told when it ends
```

On failure: `gh run view "$RUN" --log-failed | tail -80`, report which OS failed and
why. A Windows-only C++ failure in QB64-PE's own sources has happened before (see the
`qoa_ma_vtable.cpp` patch step in the workflow).

## Step 4 - Tester notes

Write the notes to a scratchpad file and attach them. Written for a tester who has
never built DRAW. Include, in this order:

1. One line: what this build is (branch, commit, date) and that it is a test build.
2. **What's new to test**: user-facing summary of `git log --oneline main..origin/$B`
   (group by feature, no commit hashes, no internal refactors).
3. **The field kit** link, if the user has one. Artifacts are private until the owner
   shares them from the page's Share menu: remind the USER of that, in your reply.
4. **Download and run**, per OS:
   - Windows: unzip `DRAW-win-x64.zip`, run `DRAW.exe`. SmartScreen may warn about an
     unsigned app: *More info -> Run anyway*.
   - macOS: `tar xzf DRAW-osx-x64.tar.gz`, then once
     `xattr -dr com.apple.quarantine .` in that folder, then `./DRAW`.
   - Linux: `tar xzf DRAW-lnx-x64.tar.gz && ./DRAW`.
   - Keep the folder together: DRAW reads `ASSETS/` and `SAMPLES/` beside the program.
5. **Settings:** a test build shares its settings folder with any DRAW already
   installed (`./DRAW --dirs` lists it). Back that folder up first if it matters.
6. **Reporting:** what to send (the field kit's report, or steps + what happened +
   OS + screen scale), and `--developer` writes the inputs DRAW received to
   `inputs.log` next to the program.

```bash
gh release edit "$TAG" --title "DRAW $B - testers build $(date +%Y-%m-%d) ($SHA)" --notes-file "$NOTES"
```

## Step 5 - Verify before handing over

```bash
gh release view "$TAG" --json isPrerelease,tagName,assets -q '.isPrerelease, (.assets[] | .name+" "+(.size|tostring))'
git ls-remote origin "refs/tags/$TAG"                 # must point at the built commit, not main
gh release list --limit 3                             # the Latest row is still the v2.x release
```

Then smoke-test the Linux package (headless is fine - console flags need no window):

```bash
D=<scratchpad>/testers-$SHA; mkdir -p "$D"
gh release download "$TAG" -p 'DRAW-lnx-x64.tar.gz' -D "$D"
tar xzf "$D/DRAW-lnx-x64.tar.gz" -C "$D"
"$D/DRAW" --version
ls "$D/ASSETS" "$D/SAMPLES" | head
```

All three assets present, pre-release true, tag on the right commit, the binary runs:
give the user the release URL (`gh release view "$TAG" --json url -q .url`) and the
one-line reminder about sharing the field kit.

## Cleanup (only when the user asks)

```bash
gh release list --limit 50 | grep testers-
gh release delete "$TAG" --cleanup-tag -y     # removes the release AND its tag
```

Old testers builds pile up; offer to delete the previous one for the same branch
when making a new one, but never delete without a yes.

## Notes

- The version inside the binary (`APP_VERSION$`) is whatever the branch has; the tag
  and title identify the build.
- The macOS package is the bare binary plus assets (no .app bundle), the same as the
  real releases.
- Packaging follows `.qb64pe-ignore` (sources, `docs/`, `QA/`, `DEV/`, `PLANS/` are left
  out). Files a tester needs belong in `ASSETS/` or `SAMPLES/`.
