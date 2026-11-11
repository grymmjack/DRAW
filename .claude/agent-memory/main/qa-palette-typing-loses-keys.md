---
name: qa-palette-typing-loses-keys
description: [Linux] on the slow QA user profile, a long command-palette query typed by xdotool can lose a key; keep test queries short and check the result
metadata:
  type: project
---

[Linux, observed 2026-11-11] Under `QA_USER_PROFILE=1` (1152x712@3 on a 3840x2400 Xvfb) frames are slow and the
command palette takes one typed key per frame (INKEY$ in `KEYBOARD_handle_command_palette%`, with a
`KEYHIT_CHAR$` fallback). A 28-character query typed by `type_text` (xdotool, 30 ms per key) lost a key every
run: "move brush: next cel every 2" arrived as "...every " (the 2 gone), and once as "every2" (the space gone).
A longer wait before Enter did not help, so a key is dropped, not just late. Not investigated in DRAW itself;
a fast human typist on a slow frame rate may hit it too.

**Why:** anim-move's "every 2" step failed 4 runs in a row on the user profile only.

**How to apply:** in tests, keep palette queries short and distinctive ("cel every 2"), read the setting back
from the dump and retry once (anim-move's `mv_set`). Remember the matcher (`CMD_fuzzy_match%`) is a plain
subsequence match, so a short query can also hit an earlier-registered command - check what it selects.
Related: [[qa-harness-toolkit]], [[draw-command-palette-registration]].
