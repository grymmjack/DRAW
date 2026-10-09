---
name: qb64pe-glfw-windows-window-shrink
description: [Windows] QB64-PE v4.7.0-GLFW opens every window at image size / monitor content scale (250% -> 800x600 SCREEN is a 320x240 window); not a DRAW bug; QA workaround and upstream status
metadata:
  type: project
---

[Windows] verified 2026-10-09 on thinkpad (4K, 250%, compiler `v4.7.0-GLFW` 26e0f6c13): a bare
`SCREEN _NEWIMAGE(800, 600, 32)` opens a **320x240** client area - every QB64-PE window is shrunk by the
monitor content scale, and the image is downscaled into it. DRAW at DISPLAY_SCALE 2 (1916x1028 image)
came up as 766x413.

**Cause** (`internal/c/libqb/src/glut-emu.cpp` `WindowCreate`, with `GLFW_SCALE_TO_MONITOR` +
`GLFW_SCALE_FRAMEBUFFER` set in `main-thread-gui.cpp`): after creating the window it converts with
`ToPixelCoords` = x * contentScale, which is right for macOS (screen coords are points) but wrong on
Windows/X11 where GLFW screen coords are already pixels; it then "fixes" the size with
`glfwSetWindowSize(ToScreenCoords(w))` = w / scale. Same code on main as of 16f629784 (no upstream fix).
Untested: X11 with a content scale > 1 likely hits it too.

**Why it matters:** any DRAW user on a scaled Windows display gets a tiny, downscaled window.
Not reported upstream yet - Rick's call (he talks to a740g).

**How to apply:** QA on Windows works around it in the qa-harness DRAW adapter
(DISPLAY_SCALE = 2 x content scale, HIDPI_AWARE=0 so DRAW does not clamp to the true desktop,
SCREEN_HEIGHT=516 because Windows enforces DRAW's window minimum). When upstream fixes it, the
geometry check fails loudly (window 2.5x too big) - remove `_qa_cfg_os_overrides` then.
See [[reference-remote-mac-windows-testing]], [[qa-harness-toolkit]].
