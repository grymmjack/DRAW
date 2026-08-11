---
name: draw-command-palette-registration
description: Menu actions need CMD_register in CMD_init to appear in the ? command palette
metadata:
  type: reference
---

A DRAW action registered only via `MENUBAR_register_item "LABEL", ..., actionId` (GUI/MENUBAR.BM)
appears in the menu bar but **NOT** in the `?` command palette. The palette is populated separately by
`CMD_register "Name", "hotkey", CMD_CAT_*, actionId` calls in `CMD_init` (GUI/COMMAND.BM ~line 41+).
To make an action discoverable/searchable in the palette, add a `CMD_register` line too.

**Why it matters for QA:** the xdotool QA tests reach menu-only actions through the palette
(`key question` → `type_text "..."` → `Return`). If the action isn't `CMD_register`ed, the typed text
matches nothing, the palette closes, and a naive `assert_regions_differ` still "passes" on the
leftover tooltip/palette pixels (~1800px) instead of the real dialog — a false green. A genuinely
opened DRAW modal is a much larger diff (tens of thousands of px). Caught during the ANSI
import/export feature: "Export ANSI"/"Import ANSI" were menu-registered but not `CMD_register`ed, so
`QA/tests/ansi-export.sh` false-passed until both were added to `CMD_init`.

**Capacity cap (fixed 2026-08-11):** the palette registry is `CMD_LIST(CMD_MAX_COMMANDS)` and
`CMD_register` does `IF CMD_COUNT >= CMD_MAX_COMMANDS THEN EXIT SUB` — a *silent* drop, no warning.
`CMD_init` registers 260+ commands, so the old `CMD_MAX_COMMANDS = 256` was silently discarding the
last few registered. Raised to 512 (GUI/COMMAND.BI). When adding commands, keep the constant well
above the `CMD_register` count (`grep -c '^\s*CMD_register ' GUI/COMMAND.BM`). "Export Kit..."/"Install
Kit..." (KIT_ACT_EXPORT/INSTALL) were added here at the same time.

Related: [[feedback_draw_compile_convention]], [[reference_qa_harness_capture]].
