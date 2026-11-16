---
name: panel-surface-covers-canvas-overlays
description: A docked panel at its own Scale (PSURF) is blitted onto the window after the presented canvas - any overlay drawn into SCRN.CANVAS& over it (hover grip, highlights) is hidden unless re-blitted
metadata:
  type: project
---

A docked panel at a set Scale (GUI/PANEL-SURFACE, PSURF) draws into its own image and is put on
the window (screen 0) by `PSURF_blit_docked` inside `SCREEN_render_windows` - AFTER
`SCREEN_present_canvas`. Anything drawn into `SCRN.CANVAS&` over the panel's footprint is covered:
2026-11-14 the dock hover grip (`DOCK_overlay_render`) vanished on every panel set off Auto, while
right-click there still worked (hit tests are not drawing). Fix pattern: copy the overlay's canvas
rect back over the window in `DOCK_reblit_to_screen0` (`DOCK_reblit_rect`), which runs after the
windows. Menus already go through `POPUP_reblit_to_screen0`.

**Why:** the bug looks like "the overlay is not drawn", but it is drawn and then covered.
**How to apply:** any new hover / highlight overlay over dock panels must be re-blitted after
`SCREEN_render_windows` (QA: panel-scale-grip.sh shows the region-diff check). Related:
[[draw-display-scale-system]].
