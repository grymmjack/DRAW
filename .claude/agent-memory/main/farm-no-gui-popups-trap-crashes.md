---
name: farm-no-gui-popups-trap-crashes
description: Never let farm/remote test runs pop windows on the user's Macbook/thinkpad — trap crash signals in-process so no OS crash dialog appears, and don't launch GUI apps there without asking
metadata:
  type: feedback
---

Remote test runs on the build farm (mac, thinkpad, titan, daw) must **never open a
window on the user's screen** — the user is actively using those machines.

**Why:** 2026-09-28, a crash-repro loop on `mac` (a `$CONSOLE:ONLY` QB64-PE program that
segfaults on purpose) popped macOS's "quit unexpectedly" crash-reporter dialog on the
user's desktop. The user said: "trap the errors and prevent GUI windows from opening …
don't do that ok?"

**How to apply:**
- [macOS] Every QB64-PE binary links Cocoa, so even `$CONSOLE:ONLY` programs get the
  ReportCrash GUI dialog on a crash. There is no Xvfb-style offscreen display on the Mac,
  so any DRAW/GUI launch there puts a real window on the desktop — ask first.
- Trap crashes **inside the process** instead of changing system settings: a
  `DECLARE LIBRARY "./sigtrap"` header that installs `signal(SIGSEGV/SIGBUS/SIGABRT/SIGILL/SIGFPE)`
  → `_exit(128+sig)`, plus on Windows `SetErrorMode(SEM_NOGPFAULTERRORBOX|…)` +
  `SetUnhandledExceptionFilter` → `_exit(139)`. Verified: [Linux] no core dump,
  [macOS] 2 real audio-race segfaults trapped in 2000 runs with 0 crash reports / 0 dialogs, [Windows] self-test exits 139 instead of the raw
  0xC0000005 code. Prove the trap on Linux (with a forced null write) BEFORE running it on
  a farm box.
- [Windows] programs launched over SSH run in a non-interactive session, so they don't
  reach the desktop — but still use the trap.
- Linux GUI tests stay under Xvfb (`draw-qa.sh` default) — see [[reference-remote-mac-windows-testing]].
