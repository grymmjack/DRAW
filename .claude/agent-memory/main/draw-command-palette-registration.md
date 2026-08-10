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

Related: [[feedback_draw_compile_convention]], [[reference_qa_harness_capture]].
