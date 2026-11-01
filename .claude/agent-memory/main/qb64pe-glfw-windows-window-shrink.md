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

**Upstream status (checked 2026-10-09):** already addressed in a740g's open PR #786 "Various #701-related
fixes" (branch `a740g:various-fixes`, head 91106accc): "Uses GLFW screen coordinates instead of converted
pixel coordinates" - `WindowCreate` no longer does the ToPixel/ToScreen fix-up, and windows are sized in
GLFW screen coordinates. Sizing rule there: `$RESIZE:ON`/`OFF`/unspecified = no scaling (window = image,
in screen coords = pixels on Windows); `$RESIZE:STRETCH`/`SMOOTH` = content scale. DRAW is `$RESIZE:ON`.
Also open: Petr's #785 "fix: correct Windows DPI scaling and framebuffer resize" (Rick posted findings there).
Don't file a new issue; verify #786 on thinkpad and report results on the PR (Rick's call).
**When #786 lands:** DRAW's own Windows DPI code (`SCREEN_DPI_DIVISOR`, `HIDPI_AWARE`/SetProcessDPIAware,
the "_DESKTOPWIDTH folds the content scale" correction in OUTPUT/SCREEN.BM) may become unnecessary or
double-correct - re-test and expect to REMOVE code. The QA override must go too.

**How to apply:** QA on Windows works around it in the qa-harness DRAW adapter
(DISPLAY_SCALE = 2 x content scale, HIDPI_AWARE=0 so DRAW does not clamp to the true desktop,
SCREEN_HEIGHT=516 because Windows enforces DRAW's window minimum). When upstream fixes it, the
geometry check fails loudly (window 2.5x too big) - remove `_qa_cfg_os_overrides` then.
See [[reference-remote-mac-windows-testing]], [[qa-harness-toolkit]].

**Update 2026-10-10 - #786 merged; farm moved to QB64-PE main (8d8e9e475, optimized self-host).**
[Windows] verified fixed: an 800x600 window opens 800x600 at 250%. DRAW's own Windows DPI code is REMOVED
(DRAW 09124333: no SetProcessDPIAware / GetDpiForSystem divisor; HIDPI_AWARE read + ignored) and the harness
scale-5 override is gone (harness beb61c8; Windows keeps SCREEN_HEIGHT=516 for the OS-enforced window minimum).
[macOS] new behaviour: `$RESIZE:ON` windows are sized in POINTS - a 400x300 image is an 800x600-pixel window,
nearest-neighbour 2x2 (crisp); `_DESKTOPWIDTH` is now points (1728, was 3456); `_SCALEDWIDTH` = framebuffer
pixels. Reported as QB64-PE issue #789 (Rick asked). DRAW's Mac mouse mapping (`MOUSE_MAC_SCALE` via
`DRAW_backing_scale`) assumed pixel-sized windows - re-check on the Mac build against main.
