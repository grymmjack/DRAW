---
name: qa-option-override-never-saved
description: A key pinned in a test's QA-OPTIONS (--option KEY=VALUE) is never written by CONFIG_save, so a test asserting that key was saved to DRAW.qa.cfg can never pass (or passes by accident)
metadata:
  type: feedback
---

A key set in a test's `# QA-OPTIONS:` line reaches DRAW as `--option KEY=VALUE`, which by design
"beats the .cfg, never saved": CONFIG_save keeps writing the cfg's own value for it. So a test that
changes that key in the UI and then greps `$QA_CFG` for the new value always fails. A check for the
original value passes by accident.

Observed 2026-11-16 [Linux, Xvfb]: anim-lane-thumbs.sh pinned `XSHEET_LANE_THUMBS=KEYFRAMES`.
The header menu set EVERY, the thumbnails changed, but DRAW.qa.cfg stayed KEYFRAMES ("saved: EVERY"
failed). An earlier fix added a poll for a "race", which was wrong.

**Why:** the failure looks like a write race or a workspace overlay. The Default workspace has no
overlay (WS_apply exits early for it), and CONFIG_save is synchronous.

**How to apply:** a test that asserts a key is saved must not pin that key in QA-OPTIONS. Let
DRAW.qa.cfg supply the starting value, or set it through the UI first. Related:
[[qa-offscreen-fragile-tests]].
