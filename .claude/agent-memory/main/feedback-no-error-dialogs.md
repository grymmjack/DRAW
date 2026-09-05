---
name: feedback-no-error-dialogs
description: EVERY QB64-PE program I build for Rick — DRAW and every throwaway probe/tool/test alike — MUST install its own ON ERROR handler so a runtime error NEVER pops QB64's default blocking "Continue?" dialog. No exceptions, ever.
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
