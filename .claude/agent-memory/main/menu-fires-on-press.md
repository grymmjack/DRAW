---
name: menu-fires-on-press
description: Menu items fire on mouse PRESS - any modal opened from the menu must swallow the still-held button / queued release
metadata:
  type: project
---

Menu items run their action on the B1 **press** edge (`MOUSE_handle_menubar_click%` in INPUT/MOUSE.BM), so a modal opened from the menu starts with the button still down or its release still queued. A modal that reads that as a fresh click acts at the menu item's screen position.

- Effect / generic dialogs: guarded by `ctx.inputArmed` (GUI/DIALOG.BM) - ignore B1 until it has been released once.
- File dialogs (QB64_GJ_LIB FILE_DIALOG): guarded DRAW-side by `DRAW_FD_wait_release` at the top of every `DRAW_*_file` / `DRAW_choose_folder$` wrapper (GUI/GJ-DIALOG-SCALE.BM), added 2026-10-10.
- [macOS] hit every time: the library's `$IF MAC` drain loop records any press seen while draining (tap-to-click support), so the opening click always counted. Save Project As landed on the DESKTOP sidebar place (navigated away, FILENAME lost focus, typed text vanished, then `_SAVEIMAGE` raised error 5). [Windows] same symptom via the ~60 ms held press. [Linux] passed (xdotool click drained before the first poll).

**How to apply:** a new modal / popup reachable from the menu needs the same arm-on-release guard. A QA test failing only on Mac/Windows right after a menu click into a dialog → suspect this first.
