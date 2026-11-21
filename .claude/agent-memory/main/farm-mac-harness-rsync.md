---
name: farm-mac-harness-rsync
description: DEV/farm-check.sh rsyncs the LOCAL qa-harness working tree to the mac (and tars it to the thinkpad) - their git status always looks dirty; driver binaries need setup.sh after a change
metadata:
  type: reference
---

`DEV/farm-check.sh qa mac|thinkpad` copies `~/git/qa-harness/` (no .git) over the host's
qa-harness on every run: rsync to `mac:git/qa-harness/`, tar to `thinkpad:C:/qa-runner/qa-harness`.
So the mac checkout's `git status` shows "local changes" that are just today's local tree -
nothing to save or stash (I stashed one on 2026-11-20 as stash@{0}; it is redundant).

The copy does NOT rebuild the native drivers. After changing a driver, build on the host:
- [macOS] `ssh mac 'cd ~/git/qa-harness && bash drivers/macos/setup.sh'` (qa-io + QA Runner.app;
  `drivers/macos/qa-run --check` afterwards - "window list: NONE" there is normal, capture works)
- [Windows] `ssh thinkpad '"C:\Program Files\Git\bin\bash.exe" -lc "bash /c/qa-runner/qa-harness/drivers/windows/setup.sh"'`

[macOS] driver lessons (2026-11-20, qa-harness 3353200 / 45e74a0 / 1c86a96): QB64-PE's GLFW path
reads the KEY CODE, so a Shift flag without a Shift press, or `type` on key code 0, reach DRAW as
the unshifted key / 'a'. A Mac failure wave where typing, `?` (command palette) or `>` steps fail
is the driver first. Related: [[qa-harness-toolkit]].
