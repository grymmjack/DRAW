---
name: qb64pe-clipboard-image-or-text
description: [Linux] QB64-PE clipboard holds a picture OR text (text after image drops it); _CLIPBOARDIMAGE misreads palette+tRNS PNGs
metadata:
  type: project
---

Probed 2026-11-07 on Linux (QB64-PE main / GLFW, under Xvfb, `xclip -o -t TARGETS`):

- **[Linux] The OS clipboard holds a picture OR text, never both.** `_CLIPBOARDIMAGE = img`
  then `_CLIPBOARD$ = "..."` leaves only the text targets; the image/png target is gone. So
  Copy Layer (COMMAND.BM CASE 715: image, then the `DRAWLAYER1|...` text) cannot carry its
  pixels to another window on Linux - pre-existing, not fixed. Copy Frames (2.5) avoids it by
  putting its metadata in a pixel header strip inside the picture (`ANIM_OPS_clip_pack&`).
- **[Linux] `_CLIPBOARDIMAGE` misreads an indexed (palette, colour type 3) PNG with tRNS:**
  pixels come out shifted as if 4-byte data were read as 3. RGBA (type 6) and RGB (type 2) PNGs
  read correctly. ImageMagick writes type 3 for few-colour images with binary alpha - use
  `PNG32:` in QA fixtures. Pasting such a PNG from another app into DRAW would be garbled
  (upstream QB64-PE bug, not reported yet).

Untested on macOS / Windows. Related: [[project-animation]].
