---
name: work-on-main
description: As of 2026-11-23 DRAW work happens on main; the theme-edit branch is retired (merged as PR #161)
metadata:
  type: project
---

Since 2026-11-23, DRAW work goes straight onto `main`. Rick: "just push it into main and stop using theme-edit branch get back on main".

`theme-edit` was merged as PR #161 (d2205a95). The fix that came after it (07b949e4, dialog title-bar drag) was cherry-picked onto main as 03123049. The `theme-edit` branch was deleted locally and on GitHub the same day.

**Why:** Rick wants one line of history, not a long-lived feature branch.

**How to apply:** Commit to `main` and push it when Rick says "commit and push"; don't start a new feature branch unless he asks for one. Older memories that name a working branch (`animation`, `antialiasing`, `customizable-shortcuts`, `input-rearchitecture`) describe the past, not where to work now. Related: [[theme-edit-uikit]].
