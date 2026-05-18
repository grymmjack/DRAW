---
name: tag-before-experiments
description: "Before any speculative/exploratory work, tag the known-good state — tags survive squash-merges and are the only reliable recovery anchor when an experiment goes sideways"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 74038101-3a17-49bd-acf2-1a71a21ba671
---

When the user opens an exploratory phase ("let's freely experiment from here"), tag the known-good commit immediately as the recovery anchor. After the experiment, even if the branch gets squash-merged into main, the tag still points at the clean intermediate state and lets you do a surgical revert.

**Why**: The user proactively did this during the HW image work: *"i've git tag hw-image-reverted-but-3x-optimized - so let's freely experiment from here."* Later, the experimental branch (`fix-perf-2`) was **squash-merged** via PR #85 into main, which carried the bad HW code back into main even though the tagged commit on the branch was the clean intermediate state. A squash merge collapses the "we tried this, then reverted it" history into a single commit — there's no commit-by-commit revert path through it. The tag was the only way to recover: `git checkout <tag> -- <files>` restored just the affected files to the known-good state, preserving main's history and unrelated additions (the test programs we wanted to keep).

**How to apply**:
- When the user signals an exploratory phase, write the tag yourself or remind the user to tag if they haven't. Use a descriptive name like `pre-<experiment>` or `<feature>-reverted-but-<wins>-kept`.
- Prefer scoped recovery (`git checkout <tag> -- file1 file2`) over `git reset --hard <tag>` when main has unrelated commits past the tag — `reset --hard` would orphan everything ahead of it. Confirm with the user before any hard reset.
- Tags don't propagate revert semantics through squash merges. If a feature branch contains "tried X then reverted X", the squash will silently include the X-attempt regardless of intermediate tags — be especially cautious reviewing squash-merged PRs.
- If a tag is no longer useful after recovery, remove it cleanly: `git tag -d <name>` locally, `git push origin --delete <name>` remotely (the user asked exactly this question after recovery this session).

Related: [[user_background_and_collaboration]] — user values visibility into git state; surface tag operations explicitly rather than doing them silently.
