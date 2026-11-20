---
name: winz-capture-blocks-own-hit-tests
description: A window holding the WINZ capture (WZ_CAP) makes every panel's *_is_over_area% say FALSE - code that asks "which panel is under the mouse?" during its own drag must lift its capture for the query (TBED_panel_at%)
metadata:
  type: project
---

2026-11-20 (Linux, OS-agnostic logic): Customize Toolbars - dragging a row from the AVAILABLE list
onto the toolbox / edit bar / advanced bar added nothing. The editor window holds the capture
(`WZ_CAP = WZ_TBED`) for the drag, and `TOOLBAR/EDITBAR/ADVBAR_is_over_area%` all check
`WZ_blocked%`, which returns blocked for any window but the capturer - so `TBED_panel_at%` always
found no panel. Fix: TBED_panel_at% saves WZ_CAP, clears it while it asks if the capturer is
WZ_TBED, and restores it. QA: tbed-edit-mode ("an Available row dragged onto the advanced bar is
added") - a long-standing known failure that was this bug.

**How to apply:** any drag that ends on a *different* panel (drop targets) must do the same - the
capture protects others from the drag, not the drag from its own drop query. See
.claude/instructions/draw-zorder.md.
