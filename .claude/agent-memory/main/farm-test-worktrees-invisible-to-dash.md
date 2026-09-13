---
name: farm-test-worktrees-invisible-to-dash
description: Isolated build-farm test builds made in a DRAW-fstest git worktree do not show up in the remote build dashboard
metadata:
  type: feedback
---

When build-verifying a branch across the build farm (mac/titan/thinkpad/daw), build in a
non-destructive git **worktree** (`DRAW-fstest`) so the host's own dirty working tree is
never disturbed. Two gotchas learned the hard way:

1. **Submodules are NOT populated by `git worktree add`** — the worktree starts with an
   empty `includes/QB64_GJ_LIB/`, so the build fails with
   `_GJ_LIB_COMMON.BI not found`. Always run
   `git submodule update --init --recursive` inside the new worktree before building.

2. **The dashboard the user runs is `DEV/remote-dash.py`** (Python/rich, via
   `uv run DEV/remote-dash.py --watch`; `DEV/dash.sh` is a one-line wrapper for it).
   `DEV/remote-dash.sh` is an older 3-host shell version, NOT what the user runs.
   As of 2026-09-13 `remote-dash.py` was made **worktree-aware**: both probes now also
   inspect `${{drawdir}}-fstest` and a **TEST BUILD** column shows its branch/short-sha +
   binary size/mtime (was previously invisible). NB: the probe payloads are Python
   f-strings, so literal shell/PowerShell braces must be doubled (`{{ }}`), and a git
   worktree's `.git` is a FILE, so test with `-e`/`Test-Path`, not `-d`.

**Why:** the user runs `~/git/DRAW/DRAW.run` (their normal binary) by default, so a test
build in `~/git/DRAW-fstest/` gets missed unless its exact path is stated prominently.

**How to apply:** (a) always init submodules in a fresh worktree; (b) when a farm test
build exists, state the exact per-host binary path prominently, don't assume the dash
shows it; (c) consider adding a worktree-aware TEST column to `remote-dash.sh`.
Also: over-SSH `ssh host ... | head` sends SIGPIPE that can kill the remote command
early — run remote builds synchronously without piping to `head`.
