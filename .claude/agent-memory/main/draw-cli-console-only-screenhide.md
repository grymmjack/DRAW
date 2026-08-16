---
name: draw-cli-console-only-screenhide
description: CLI ops (--help/--version/--options-list/--config-upgrade) are console-only and flash no window because the app starts $SCREENHIDE and only _SCREENSHOWs on the normal launch path
metadata:
  type: project
---

DRAW uses `$CONSOLE` (not `$CONSOLE:ONLY`), so QB64-PE opens its default graphics
window at process start — before any of our code runs. That made console-only CLI
ops briefly **flash a blank window**. Fixed 2026-08-16:

- `_COMMON.BI` adds `$SCREENHIDE` right after `$CONSOLE` → window starts hidden.
- `DRAW.BAS` calls `_SCREENSHOW` once, right after the include chain (after
  `screen_shown = TRUE`, before the splash). Reaching that line == a normal editor
  launch. Every console-only CLI op `SYSTEM`s earlier (during the include chain),
  so it never reaches `_SCREENSHOW` and never shows a window.

**Consequences to respect when editing startup:**

1. **`SCREEN_init` runs while the window is HIDDEN** (it's in the include chain,
   before `_SCREENSHOW`). Window-visibility-dependent calls raise **ERR 5 (Illegal
   function call)** on a hidden window. `_SCREENMOVE _MIDDLE` and
   `IF CFG.FULLSCREEN% THEN _FULLSCREEN _SQUAREPIXELS` were moved OUT of
   `SCREEN_init` (OUTPUT/SCREEN.BM) to DRAW.BAS immediately after `_SCREENSHOW`.
   Do NOT add `_SCREENMOVE`/`_FULLSCREEN`-type window ops into `SCREEN_init` or any
   include-time code — put them after `_SCREENSHOW`. (`_ICON`, `_PIXELSIZE`,
   `SCREEN _NEWIMAGE`, offscreen `_NEWIMAGE` are fine on a hidden window.)

1b. **`_DESKTOPWIDTH`/`_DESKTOPHEIGHT` return 0 while the window is HIDDEN.**
   SDL doesn't report the desktop resolution until the window is shown (verified:
   `$CONSOLE`+`$SCREENHIDE` → `_DESKTOPWIDTH`=0 after 100 retries; shown → 1280
   instantly). `SCREEN_init`'s auto-detect (viewport + scale) depends on it, so a
   hidden query collapses the viewport to the WIN_MIN 320x200 clamp — a
   postage-stamp window on EVERY launch (exposed by `--reset-defaults`, which
   re-runs detection). **Fix:** `SCREEN_init` does `IF NOT CMDLINE_CONFIG_UPGRADE%
   THEN _SCREENSHOW` right after `THEME_load`, BEFORE the first `_DESKTOPWIDTH`
   query. Real launches (incl. `--reset-defaults`) reveal the window there and
   detect correctly; `--config-upgrade` stays hidden (it SYSTEMs later in the SUB).
   Never query `_DESKTOPWIDTH` before that `_SCREENSHOW`.

2. **Interactive startup modals must reveal the window first.** The Config-not-found
   / Missing-config-path (CFG/CONFIG.BI) and Migrate-settings (CORE/PATHS.BM)
   prompts fire from the include chain, before `_SCREENSHOW`. They all route through
   `DRAW_message_box%` (GUI/GJ-DIALOG-SCALE.BM), which now calls `_SCREENSHOW`
   (no-op if already shown) + `_MOUSESHOW "DEFAULT"` before its modal loop — else the
   modal renders into a hidden window and hangs. See
   [[draw-modal-cursor-before-first-render]].

3. **`--config-upgrade` is console-only + reconcile-and-exit.** It no longer uses
   `DRAW_alert` (a hidden-window modal would hang); it `PRINT`s to `_DEST _CONSOLE`
   and `SYSTEM`s. It does NOT launch the editor. See
   [[draw-config-upgrade-maxkeys-cap]].

Verified headless: Xvfb + `xdotool search --onlyvisible --name DRAW` shows NO window
for --help/--version/--options-list/--config-upgrade (all exit 0, console text); a
normal launch DOES show a centered window and keeps running. Regression guard:
`QA/cli-smoke.sh` (standalone, NOT a GUI-harness test) covers all of the above plus
the auto-detect window-size check.

⚠️ **Testing caution:** `--reset-defaults` deletes EVERY known config location, not
just `CONFIG_FILE_PATH$` — including `PATHS_config$("DRAW.cfg")` (the native
`~/.config/DRAW/DRAW.cfg`) even when `--config <other>` is passed (CFG/CONFIG.BI
~179). So `--config <copy> --reset-defaults` is NOT isolated — it also nukes the
user's real config. Never run `--reset-defaults` against the live environment while
testing.
