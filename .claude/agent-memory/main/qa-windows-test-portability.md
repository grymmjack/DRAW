---
name: qa-windows-test-portability
description: [Windows] QA tests run in Git Bash but DRAW / magick / python are native - FMT:/path args, python \r\n, paths written into files, keypad characters need Num Lock; harness shims and native_path fix them
metadata:
  type: project
---

[Windows] (thinkpad, Git Bash under the qa-run Scheduled Task, 2026-11-17). Git Bash rewrites an MSYS path
(`/tmp/x`, `/c/...`) into `C:/...` only when a command-line argument STARTS with `/` (or is `NAME=/path`).
Everything else reaches native programs untranslated. Four ways that silently broke Windows QA:

1. **`magick ... "PNG32:/tmp/x.png"`**: the format prefix hides the path, so magick.exe can't open it, the
   fixture is never written, and DRAW shows "0 frames". About 110 tests use `FMT:$path`. Fixed by the shim
   `qa-harness/drivers/windows/bin/magick`, which rewrites `FMT:/path` → `FMT:C:/...` and then runs `magick.exe`.
   The shim dir is first on PATH; convert / compare / identify go through it too.
   It was misdiagnosed for a day as the WindowsApps python3 stub. python3 was fine.
2. **python3 prints `\r\n`**: values from `read` / `$(...)` keep a trailing `\r`, so identical-looking CRC
   lists compare unequal (animbrush-load). Fixed by the shim `drivers/windows/bin/python3`, which pipes
   through `tr -d '\r'` and keeps the exit status.
3. **Paths written INTO a file** (DRAW's `<dump>.drop` drop hook) are never translated. Use the core helper
   `native_path PATH` (cygpath -m on Windows, unchanged elsewhere). The 4 drop tests use it now.
4. **Keypad characters need Num Lock.** qa-io sends scan codes, so KP_* key codes always reach GLFW (the
   frame-step keys work), but a typed keypad digit appears only with Num Lock on. The thinkpad's is off,
   so anim-lightbox-bar's "Num 4 while typing" fails there (known-failures).

**How to apply:** when a test passes on Linux and fails on Windows with "0 frames", an empty list, or an
"X, wanted X" that looks identical, suspect these before DRAW. In a new test, wrap any path that goes into a
file with `native_path`. See also [[qa-harness-toolkit]] and [[thinkpad-two-windows-profiles]].
