---
name: browser-fd-long-list-and-thumb-loader
description: FILE_DIALOG scroll math must be LONG (long thumbnail columns pass 32767 px); thumbnail loader must tick every frame, not from Browser mouse input
metadata:
  type: project
---

Found 2026-11-17 (OS-agnostic; observed on Linux), fixed on branch xsheet-holds-lanes:

- **INTEGER overflow in FILE_DIALOG scroll math.** A docked Browser in a narrow column shows ONE
  thumbnail per row; 724 files x ~156 px = 113k px. `totalH AS INTEGER` wrapped negative, so
  maxScroll = 0: no scrollbar, wheel clamped (Rick: "the browser won't scroll"). A shorter list
  wraps positive and silently cuts the END off instead. Anything holding a list pixel position
  (scrollOffset, maxScroll, totalH, drawY, cellY, relY, relRow, itemY) is LONG now - keep new
  ones LONG. C promotes INTEGER*INTEGER to int, so only the *store* wraps.
- **The thumbnail loader ran only under the pointer.** FD_THUMB_tick (one thumb a frame) lived in
  BROWSER_mouse_input, which MOUSE.BM calls only while BROWSER_owns_mouse%. Move the pointer off and
  loading stopped half-done ("thumbnails don't show consistently"). It is BROWSER_tick in the main
  loop now. Background work never belongs in a *_mouse_input handler.
- FD_THUMB_tick must use the render's grid (contentW minus the scrollbar when it shows,
  FD_STATE.rowHeight) - it used FD_ROW_HEIGHT + full width and drifted off the visible rows.
- FD's 6 px resize grip (FD_INPUT_hit_resize_edge%) overlaps the 12 px list scrollbar at the right
  edge; the scrollbar wins now (bar the outer 2 px). Same overlap family as the 2026-11-07 close-X bug.

**How to apply:** test Browser changes with a long folder in a narrow docked column
(QA/tests/dock-browser-scroll.sh makes 724 files; BROWSERSC dump line has maxScroll + loaded counts).
Related: [[browser-geometry-native-vs-viewport]].
