---
name: workspace-remember-whole-layout
description: A workspace remembers its WHOLE layout (every panel's presence, dock, size, scale, settings) by comparing the full capture; any new panel or panel setting must join that capture
metadata:
  type: feedback
---

**Rick, 2026-11-14:** "EVERY SINGLE PANEL that exists, with EVERY SINGLE CONFIGURATION in the
program for that panel, and for it's docks, and sizes and widths and heights and scales and
presence, and so on, MUST BE REMEMBERED in a workspace layout, then when they switch they must
be RECALLED just the way they were REMEMBERED. do NOT make mistakes again." That came after
several rounds where visibility was never saved, the [CHROME] dock sides came from stale keys,
hidden windows lost their places and in-workspace changes leaked into DRAW.cfg.

**Why:** piecemeal remember paths (per-key poll, dock commit, edge drag) each missed something.
The fix is one comparison of the whole capture (`WS_layout_state$` vs `WS_STATE_SEEN`) and
one save of all of it (`WS_remember_save`), with every element / dock side guarded while a
workspace is active. Details: `.claude/instructions/draw-workspaces.md` "Remember the whole
layout".

**How to apply:**
- A new panel: add its `WS_EL_*` element (visibility), its dock id to `WS_dk_panel%` if it has
  a side key, its window keys to `WS_window_keys$` + `DOCK_native_cfg_lines$` +
  `WS_window_key_docked%`, and its settings to `WS_panel_keys$` (+ `WS_panels_push` when the
  panel reads CFG only at init).
- A new panel setting (menu, gear, right-click, Ctrl+wheel): add the DRAW.cfg key to
  `WS_panel_keys$`.
- Prove it with `QA/tests/workspace-recall-all.sh` (state diff after switch / Default /
  restart / F11) in plain AND user-profile mode, not by spot-checking a few keys.
Related: [[feedback-test-with-user-profile]], [[qa-user-workspaces-override-builtins]].
