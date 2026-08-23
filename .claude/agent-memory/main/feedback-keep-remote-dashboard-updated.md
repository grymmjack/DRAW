---
name: feedback-keep-remote-dashboard-updated
description: Keep the remote-test dashboard's per-host NEXT/status notes updated on every iteration — Rick watches it to see, at a glance, what he needs to do next on mac/windows.
metadata:
  type: feedback
---

**Update the remote dashboard's NEXT/status notes on every iteration** as work moves
along — after each build, deploy, test result, or diagnosis. Rick relies on the
dashboard to see at a glance what *he* (the human) needs to do next on the remote
mac/windows machines, since he can't see the SSH state I can.

**Why:** he asked for this explicitly (2026-08-23). The dashboard's NEXT column is
only useful if it reflects the current step; a stale note is worse than none. It's
the shared status surface between us for the remote build/test loop.

**How to apply:** the dashboards live in `DEV/remote-dash.sh` and `DEV/remote-dash.py`
(the richer one, run via `uv run DEV/remote-dash.py`). Set a host's note with
`uv run DEV/remote-dash.py --set <host> "<note>"`, clear with `--clear <host>`.
Notes persist in `.claude/remote-status/<host>.status`. Lead with a marker so it
colors correctly: `▶` ready/action, `⏳` waiting, `⚠` down/problem, `✓` done.
See [[reference-remote-mac-windows-testing]].
