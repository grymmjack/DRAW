---
name: feedback-no-error-dialogs
description: PERMANENT, NEVER BREAK - no error may ever surface as a dialog. Every QB64-PE program (DRAW, probes, tools, tests) traps its own errors (ON ERROR), AND failures BASIC can't trap (QB64-PE runtime alerts like "Failed to initialize window") are prevented by guarding BEFORE the failing call. Also never cause them (don't kill a display / process a run still uses).
metadata:
  type: feedback
---

**[Linux] Rick, 2026-09-04, emphatic:** *"you had a dialog box waiting from an error — I
told you never do that, prevent it at all costs with our own error handling ... always for
every tool every build everything."*

**Rule:** ANY QB64-PE program I compile for Rick — the DRAW app AND every one-off probe,
diagnostic, or test harness — must install its OWN error handler so a runtime error can
never surface QB64-PE's default modal **"Runtime error … Continue?"** dialog. That dialog
**blocks** — invisible under Xvfb but hanging automation behind an OK button (same reason
DRAW's headless path swaps the crash modal for an auto-dismiss banner). A throwaway tool is
NOT exempt: mine popped it (a bare `_MOUSEBUTTON(n)` past the device's button count → ERR 5,
no `ON ERROR`), which is what triggered this.

**Why:** a blocking dialog stalls the whole session behind a click nobody can make offscreen,
and Rick can't see it to dismiss it. "It's just a quick probe" is exactly when it bites.

**How to apply — put this in EVERY standalone `.bas` I write, right after the directives:**
```qb64
ON ERROR GOTO EH
' ... program body ... ends with SYSTEM
SYSTEM
EH:
    ' log + keep going; NEVER fall through to the default dialog
    _LOGWARN "trapped ERR" + STR$(ERR) + " at line" + STR$(_ERRORLINE)
    RESUME NEXT
```
For a graphics tool with `$CONSOLE`, `PRINT` the trap instead of `_LOGWARN` if simpler, but
the handler is mandatory. Also **bound risky calls** so they don't error in the first place
(e.g. only `_MOUSEBUTTON(n)` for `n <= _LASTBUTTON(mouseDev)`; `_LASTBUTTON` needs the
[MOUSE] device number or it raises ERR 5 — see [[proj-customizable-shortcuts-status]]).

Related standing prefs: [[feedback-zero-warnings-build]], [[feedback-dry-reuse-libs]].
DRAW's own protection is `FatalError` + `DRAW_HEADLESS`/`--developer` non-blocking banner.

**[Linux] Rick, 2026-10-11 - "make this a permanent thing - never not catch the errors, never."**
A QB64-PE *runtime* alert ("Failed to initialize window", libqb `main-thread-gui.cpp`
`gui_alert` -> exit) popped on his desktop. Cause: I killed a regression run's Xvfb (`:99`)
while its runner was still launching DRAW there; DRAW's no-display guard only checked that
`$DISPLAY` was *set*. `ON ERROR` can't catch this (C++ GUI thread, not a BASIC error), so:

- **Untrappable failures are prevented, not caught:** guard before the call that fails. DRAW's
  guard (OUTPUT/SCREEN.BM `SCREEN_init`) now really connects to X (`gj_x11_display_reachable&`,
  native/display_probe.h, dlopen libX11) and takes the clean exit (log + console, `SYSTEM 3`).
  Verify such a fix with the session bus / Wayland vars unset (`env -u DBUS_SESSION_BUS_ADDRESS
  -u WAYLAND_DISPLAY -u XDG_RUNTIME_DIR DISPLAY=:98 ...`) so a miss can't reach his desktop.
- **Don't create the failure:** to stop a QA run, kill the runner (its process tree) FIRST and
  let it finish its own teardown; never kill its Xvfb / display out from under live launches.
- **Isolate first:** prove a native helper / risky call in a standalone `DEV/EXPERIMENTS/*.bas`
  (with `ON ERROR`) before wiring it into DRAW (see [[feedback_isolated_tests_first]]).

