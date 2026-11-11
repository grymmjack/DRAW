---
name: qa-data-dir-not-isolated
description: [Linux] a normal QA run shares the real ~/.local/share/DRAW (XDG_DATA_HOME) - code that a test reaches must not create folders there
metadata:
  type: project
---

[Linux, observed 2026-11-10] The qa-harness DRAW adapter (`adapters/draw/manifest.sh`) always isolates
`XDG_CACHE_HOME`, but `XDG_DATA_HOME` only under `QA_USER_PROFILE=1` (it copies the data into
`$RESULTS_DIR/draw-user-data`). In a normal run DRAW reads and writes the real `~/.local/share/DRAW`.

**Why:** the Swatches panel's set list first called `PATHS_ensure_dir PATHS_data$("SWATCHES/")` while
scanning, so a QA test that opened the list would have created a folder in Rick's real data dir.

**How to apply:** listing / scanning code never writes - skip a missing folder. Create a data folder only
on an explicit user action (import, "open folder"). If a test must exercise such an action, run it with
`QA_USER_PROFILE=1` (scratchpad `up.sh`) or set `XDG_DATA_HOME` in the test. See
`.claude/instructions/draw-swatches.md`; related [[feedback-test-with-user-profile]].
