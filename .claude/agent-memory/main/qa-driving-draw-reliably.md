---
name: qa-driving-draw-reliably
description: [Linux] long xdotool scripts against DRAW (lightbox, 24 frames) lose clicks, the palette's "?" and Alt+] presses; hold clicks, confirm the palette is open before typing, verify every step from the dump
metadata:
  type: project
---

[Linux, observed 2026-11-11, default QA profile 958x514@2x, Xvfb] Building the AnimBrush example
scenes (DEV/animbrush-pack/build-scenes.sh: ~60 clicks / keys per scene, lightbox on a 24-frame
960x480 sheet) dropped inputs every run. Frames are slow there, so:

- **A quick `click` can vanish**: press and release inside one frame, DRAW never sees B1 down.
  Drawer bin picks and canvas stamps failed ~1 in 10. Fix: `mouse_down X Y; sleep 0.15; mouse_up`.
- **The `?` that opens the command palette can be lost**, and then `type_text` sends the query as
  HOTKEYS (it set two layers' blend mode to SUB and switched tools). Never type before checking
  the dump has `POPUP cmdpalette`; after Enter check it is gone.
- Alt+] and Ctrl+Shift+N presses can be lost too: read ABRS anchor / count `^LAYER ` lines and retry.
- Did a stamp land? `ANIMC` (per-frame CRCs of the current layer) changes. `ABRP` does not work for
  that: an identical copy (stacked tiles, same phase) or a see-through brush leaves it unchanged.

**Why:** three rebuilds were wasted on dropped inputs (a torch missing, owls instead of fireflies,
ghosts painted along a path when Move Brush never started).

**How to apply:** any long QA script: held clicks, palette-open check, read back each setting and
retry, and check the result from the dump rather than trusting the input was seen. Short
palette queries as in [[qa-palette-typing-loses-keys]]. Helpers to copy: `hclick`, `cmd`,
`mvset`, `layer`, `phase`, `stamp` in DEV/animbrush-pack/build-scenes.sh. See [[qa-harness-toolkit]].
