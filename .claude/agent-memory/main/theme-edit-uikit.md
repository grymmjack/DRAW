---
name: theme-edit-uikit
description: Theme Edit mode is also the seed of Rick's reusable QB64PE UI library (UIKIT) - keep GUI/UIKIT host-independent
metadata:
  type: project
---

Theme Edit mode (`--theme-edit`, built 2026-11-21, uncommitted on `main` at the time) is
deliberately the first slice of a reusable UI library: Rick wants DRAW's **entire** widget set
usable in other QB64PE projects, and is using the theme editor to force a composable API out of
it (identify every component and every property, then decompose, document, extract).

**Why:** a long-standing goal of Rick's; the theme editor needs a property/component model anyway.

**How to apply:**
- `GUI/UIKIT/*` (`UIP_`, `UIPI_`) must never read a DRAW global - DRAW plugs in through
  `UIP_host_get$` / `UIP_host_set%` and the inspector's event queue. Anything DRAW-specific goes
  in `CFG/THEME-EDIT.BM` (`THEMEED_`).
- Planned path (PLANS/THEME-EDIT.md phases): finer elements + ENUM dropdowns -> extract to
  `QB64_GJ_LIB/UIKIT` with a generated component inventory + standalone demo -> move DRAW widgets
  (`FPANEL_*`, `DIALOG_draw_*`, Settings widgets) onto UIKIT one at a time.
- Guide: `.claude/instructions/draw-theme-edit.md`. See also [[qa-harness-toolkit]].
