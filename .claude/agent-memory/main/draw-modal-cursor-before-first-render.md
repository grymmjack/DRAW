---
name: draw-modal-cursor-before-first-render
description: In-app modal dialogs raised before the first POINTER_render have an invisible cursor (POINTER_init hid the OS cursor and nothing re-showed it)
metadata:
  type: project
---

[Linux] The in-app modal dialogs (message box / input box via the shared MSG_BOX
lib) draw **no cursor of their own** — they rely on the OS hardware cursor
already being visible ("DEFAULT"). During normal runtime that holds, because you
reach a dialog by clicking UI chrome and `POINTER_render` (GUI/POINTER.BM) last
called `_MOUSESHOW "DEFAULT"`.

**Gotcha:** any modal raised *before the main loop's first `SCREEN_render` /
`POINTER_render`* sees only `POINTER_init`'s `_MOUSEHIDE` — the OS cursor is
hidden and nothing has shown it. The dialog appears with **no visible pointer**
and can only be dismissed by Enter/Esc. First observed 2026-08-16 on the
`--config-upgrade` alert (since removed — that op is console-only now); the
remaining startup modals that fire from the include chain are Config-not-found /
Missing-config-path (CFG/CONFIG.BI) and Migrate-settings (CORE/PATHS.BM).

**Why:** DRAW hides the OS cursor and software-draws its own pointer every frame.
The shared `MB-API.BM` modal loop only calls `_MOUSESHOW` at *cleanup* (end),
never at the *start* of the loop.

**How to apply:** the DRAW-side chokepoint `DRAW_message_box%`
(GUI/GJ-DIALOG-SCALE.BM) now does `_SCREENSHOW` + `_MOUSESHOW "DEFAULT"` right
before `MB_modal_loop`, and sets `POINTER.PREV_SYS_CURSOR$ = "DEFAULT"` after
`BROWSER_resume_after_modal` so the pointer system re-syncs from the real state
instead of a stale cached one. The `_SCREENSHOW` also un-hides the window for
startup modals (app starts `$SCREENHIDE`; see
[[draw-cli-console-only-screenhide]]). If you add another modal that can fire at
startup (before first render / before `_SCREENSHOW`), route it through
`DRAW_message_box%` — don't assume the window or OS cursor is showing.

Not QA-testable via the xdotool/Xvfb harness: `snap_region` captures DRAW's own
canvas buffer, but the OS hardware cursor is composited by SDL/the display
server (and not rendered at all under offscreen Xvfb). See
[[effect-dialog-shared-widgets]].
