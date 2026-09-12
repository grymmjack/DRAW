---
name: draw-tooltip-container-wrap
description: DRAW has two independent tooltip renderers, both made to word-wrap to their CONTAINER (not the screen) via one shared helper TOOLTIP_wrap_line (v2.3.2). The QB64_GJ_LIB file dialog has a third, self-contained one.
metadata:
  type: reference
---

There are **two independent tooltip renderers in DRAW** (plus a third in the lib):
- `TOOLTIP_render` (GUI/TOOLTIP.BM) — the global floating tooltips for toolbar /
  organizer / edit+advanced bars / layers / ACP history (routed by `TOOLTIP_SRC_*`).
- `SW_draw_tooltip` (GUI/SETTINGS-WIDGETS.BM) — the **Settings dialog** has its OWN
  tooltip (`SW_TIP`, `SW_check_tooltip`), drawn onto the dialog's clip buffer. There
  is no `TOOLTIP_SRC_SETTINGS`; fixing TOOLTIP_render does NOT touch Settings.
- `FD_RENDER_tooltip` (includes/QB64_GJ_LIB/FILE_DIALOG/FD-TOOLTIP.BM) — the file
  dialog's self-contained tooltip (fixed-width font: `LEN(text)*FD_CFG.fontW`).

## The v2.3.2 fix: wrap to the container, not the screen
All three assumed the screen/window and only **clamped position** — a line wider than
the container spilled off the right edge (floating) or was **clipped mid-word**
(Settings, e.g. the long "MASTER UI scale…" help). The fix: a shared greedy word-wrap
**`TOOLTIP_wrap_line (text$, isBold%, maxPixW%, outRows() AS STRING, outBold() AS
INTEGER, rowCount%)`** in TOOLTIP.BM — wraps to a caller-supplied pixel budget using
the CURRENT `_FONT`, hard-breaks over-long words, fills fixed 1-based arrays. Each
renderer passes **its own container width**: TOOLTIP_render → `_WIDTH(target&)` (the
window); SW_draw_tooltip → `_WIDTH` of the clip buffer (the dialog content area).

## Gotchas that shaped it
- **Readability cap is in CHARACTERS, not pixels** (`TOOLTIP_MAX_CONTENT_CHARS = 90`
  in TOOLTIP.BI), converted through the current font (`_PRINTWIDTH("abc…z")\26`). A
  fixed pixel cap over-wraps the **UI-scaled dialog font** at high UI scale (the
  floating tooltip font is a fixed 8px, the dialog font is not).
- Most existing one-line tooltips are under the cap, so they render unchanged.
- **The lib is a submodule** — `FD_RENDER_tooltip` must NOT call DRAW's
  `TOOLTIP_wrap_line` (dependency runs DRAW→lib only). Keep FD self-contained; the
  lib's reusable wrap is `STR.word_wrap$` in the STRINGS module. See
  [[feedback_qb64_gj_lib_no_consumer_helpers]].
