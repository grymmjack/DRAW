---
name: qb64pe-acceptfiledrop-cross-platform
description: QB64-PE _ACCEPTFILEDROP family is cross-platform now (GLFW), NOT Windows-only as the wiki says
metadata:
  type: reference
---

The QB64-PE drag-and-drop **file-drop-IN** keywords — `_ACCEPTFILEDROP`,
`_TOTALDROPPEDFILES`, `_DROPPEDFILE$`, `_FINISHDROP` — are **cross-platform** in
current QB64-PE (v4.6.0+, GLFW backend): Linux/X11, macOS, and Windows. The
qb64phoenix wiki still lists them under "Keywords currently not supported" as
Windows-only — that page **predates the GLFW backend and is stale**. Confirmed by
Rick (grymmjack) 2026-08-23 and by DRAW itself: DRAW calls `_ACCEPTFILEDROP`
unconditionally with no `$IF WIN` gate at [DRAW.BAS:258] and the drop handler
[DRAW.BAS:443-458] works on Linux.

Observed on Linux (2026-08-23); asserted cross-platform by the maintainer.

Still genuinely unavailable: drag-drop **OUT** (a drag *source*). QB64-PE has no
keyword to *initiate* an OS drag from its own window on any platform — GLFW only
provides the drop-target callback, not a drag source. So "drag a layer out of DRAW
onto another window/app" cannot be done without per-OS `DECLARE LIBRARY` native
drag APIs. See [[multi-instance-support]] for how DRAW works around this
(clipboard + polled handoff folder instead of drag-out).
