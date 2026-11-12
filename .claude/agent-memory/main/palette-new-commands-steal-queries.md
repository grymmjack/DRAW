---
name: palette-new-commands-steal-queries
description: A new CMD_register name can steal an older command's palette query (subsequence match, first registered wins) and break QA tests far away
metadata:
  type: project
---

The command palette (`CMD_update_search`, GUI/COMMAND.BM) matches a query as a
SUBSEQUENCE of the name (case-insensitive) and lists results in `CMD_register` order;
QA's `cl_cmd` / `mv_cmd` type a query and press Enter = the FIRST match. So a long new
name registered early steals older queries: "Clip Layer: Delete Key on This Frame"
(registered in the clip block) matched "delete frame", Enter ran it instead of Delete
Frame, and anim-frame-ops + clip-layers failed 22 checks (2026-11-12). Nothing errors -
the wrong command just runs.

**Why:** QA tests drive most commands through the palette with short queries.

**How to apply:** register new commands at the END of `CMD_init` (after
"Customize Controls..."), as the lane commands now are, unless the name can't
subsequence-match an existing query. If a test of another feature fails with "nothing
happened" after you add commands, check what its palette query now matches first.

Second trap, same day: `CMD_MAX_COMMANDS` was 512 with 532 registered, so the LAST
20 (registered at the end, per the rule above) were silently dropped - the palette
never offered them. Raised to 1024 and `CMD_register` now `_LOGWARN`s when full; if
end-registered commands vanish, check the cap.
Related: [[qa-palette-typing-loses-keys]].
