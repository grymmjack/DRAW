---
name: thinkpad-two-windows-profiles
description: thinkpad has two Windows profiles — SSH login (grymmjack.thinkpad) differs from the interactive desktop user (grymm), so %APPDATA% / DRAW config dir differ
metadata:
  type: reference
---

[Windows] The **thinkpad** build-farm host: the SSH login user and the interactive
desktop login user are DIFFERENT, so `%APPDATA%` (and thus DRAW's config dir) differ by
who is *logged in*, NOT by the directory the exe is launched from:

- **SSH** connects as `grymmjack.thinkpad` → `%APPDATA% = C:\Users\grymmjack.thinkpad\AppData\Roaming`
- **Interactive desktop login** is `grymm` → `%APPDATA% = C:\Users\grymm\AppData\Roaming`

The user runs the worktree build from the terminal in `C:\Users\grymmjack.thinkpad\git\
DRAW-fstest\` (that IS the run dir — `_STARTDIR$` confirms it), but because their logged-in
Windows user is `grymm`, DRAW writes its config to `C:\Users\grymm\AppData\Roaming\DRAW\
DRAW.cfg` (the LOGIN user's AppData, not the exe's folder, not the SSH user's folder).
An SSH probe (as grymmjack.thinkpad) sees `C:\Users\grymmjack.thinkpad\...` — a different
profile's config, never the user's real one. The run directory is a red herring; the
`%APPDATA%` mismatch is purely the login-user difference (desktop `grymm` vs SSH
`grymmjack.thinkpad`).

**Confirmed 2026-09-13** via an in-app trace that logged `PATHS_CONFIG_DIR$`. This wasted a
long investigation into a fullscreen "config never persists / menu lies" bug that was
entirely an artifact of inspecting the wrong profile — DRAW's config write/persist was
correct all along.

**How to apply:** when debugging DRAW config/state on thinkpad, the file the user's GUI
uses is under `C:\Users\grymm\...`, NOT the SSH login's `C:\Users\grymmjack.thinkpad\...`.
To read the real state over SSH, target `C:/Users/grymm/AppData/Roaming/DRAW/` explicitly,
or have DRAW itself log `PATHS_CONFIG_DIR$`/`CONFIG_FILE_PATH$` (write a trace to
`_STARTDIR$` so it lands in the launch dir, which IS shared/visible). The worktree build
lives under the SSH profile (`C:\Users\grymmjack.thinkpad\git\DRAW-fstest`), but its
RUNTIME config goes to whichever user runs it. See [[farm-test-worktrees-invisible-to-dash]].
