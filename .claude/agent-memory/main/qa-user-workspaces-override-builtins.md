---
name: qa-user-workspaces-override-builtins
description: QA runs read the user's real workspaces folder; a user copy of a built-in workspace (animate.workspace) silently replaces it in tests
metadata:
  type: project
---

[Linux] The qa-harness isolates DRAW's config (DRAW.qa.cfg) and cache, but NOT the data
folder: `~/.local/share/DRAW/WORKSPACES/` is the live one, and a user file with a built-in's
id wins over `ASSETS/WORKSPACES/`. Rick saved his own `animate.workspace` on 2026-11-10 (no
`[OPTIONS] LIGHTBOX=1`), so `workspace-animate.sh` failed 4 checks ("lightbox shown 0") from
then on - DRAW was fine; run directly with a scratch HOME it showed the lightbox (2026-11-12).

**Why:** any test of a built-in workspace's contents depends on Rick's own files otherwise.

**How to apply:** tests that check what a built-in workspace does put
`WORKSPACES_DIR=/tmp/draw-qa-ws-none` (or their own scratch dir) in `QA-OPTIONS`
(`--option WORKSPACES_DIR` is run-only, never saved). Done for workspace-animate,
workflow-buttons, workspace-sprite-scene. When a workspace test fails only on this machine,
`ls ~/.local/share/DRAW/WORKSPACES/` first (read-only - never edit Rick's files).
Related: [[qa-harness-toolkit]].
